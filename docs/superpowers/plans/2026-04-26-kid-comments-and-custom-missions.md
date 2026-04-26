# Kid Comments & Custom Missions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add submission comment to mission submissions, plus let kids propose one-off custom missions that parents approve (with adjustable points) crediting points immediately.

**Architecture:** `ProfileTask` schema gains a `source` enum (`catalog`/`custom`), nullable `global_task_id`, and `custom_*` columns so custom missions live as standalone `ProfileTask` rows without polluting `GlobalTask`. New `Tasks::CreateCustomService` plus `points_override` kwarg on `Tasks::ApproveService`. Submission comment is a single text column, captured on submit (catalog) or create (custom) and rendered in the approval queue.

**Tech Stack:** Rails 8.1, PostgreSQL 16, Tailwind 4 + Duolingo design system, Stimulus, Turbo, ViewComponent 4.7, RSpec + FactoryBot + Capybara.

Spec: `docs/superpowers/specs/2026-04-26-kid-comments-and-custom-missions-design.md`

---

## File Structure

**Migrations**
- Create: `db/migrate/<ts>_add_custom_mission_fields_to_profile_tasks.rb`

**Models**
- Modify: `app/models/profile_task.rb`

**Services**
- Modify: `app/services/tasks/complete_service.rb` — accept `submission_comment`
- Modify: `app/services/tasks/approve_service.rb` — accept `points_override`, write comment into ActivityLog
- Create: `app/services/tasks/create_custom_service.rb`

**Controllers**
- Modify: `app/controllers/kid/missions_controller.rb` — add `new`, `create`, accept `submission_comment` on `complete`
- Modify: `app/controllers/parent/approvals_controller.rb` — accept `points_override` on `approve`

**Routes**
- Modify: `config/routes.rb` — add `:new, :create` to `kid/missions`

**Views & Components**
- Create: `app/views/kid/missions/new.html.erb`
- Modify: `app/views/kid/missions/_mission_submit_form.html.erb` (or wherever submit form lives) — add comment textarea
- Modify: `app/components/ui/approval_row/component.rb` — accept `submission_comment`, `custom`, `points_editable`
- Modify: `app/components/ui/approval_row/component.html.erb` — render comment block + custom badge + editable points input
- Modify: `app/views/parent/approvals/index.html.erb` (or queue partial) — pass new props
- Modify: `app/views/kid/dashboard/index.html.erb` — add "+ Nova missão" button

**Tests**
- Modify: `spec/models/profile_task_spec.rb`
- Create: `spec/services/tasks/create_custom_service_spec.rb`
- Modify: `spec/services/tasks/approve_service_spec.rb`
- Modify: `spec/services/tasks/complete_service_spec.rb`
- Create: `spec/system/kid/custom_mission_spec.rb`
- Create: `spec/system/kid/submission_comment_spec.rb`
- Modify: `spec/factories/profile_tasks.rb`

---

## Task 1: Migration — Add custom mission fields to profile_tasks

**Files:**
- Create: `db/migrate/<ts>_add_custom_mission_fields_to_profile_tasks.rb`

- [ ] **Step 1: Generate migration**

```bash
bin/rails g migration AddCustomMissionFieldsToProfileTasks
```

- [ ] **Step 2: Write migration body**

Replace the generated migration body with:

```ruby
class AddCustomMissionFieldsToProfileTasks < ActiveRecord::Migration[8.1]
  def change
    change_column_null :profile_tasks, :global_task_id, true

    add_column :profile_tasks, :source,              :integer, default: 0, null: false
    add_column :profile_tasks, :custom_title,        :string
    add_column :profile_tasks, :custom_description,  :text
    add_column :profile_tasks, :custom_points,       :integer
    add_reference :profile_tasks, :custom_category,
                  foreign_key: { to_table: :categories, on_delete: :nullify },
                  null: true
    add_column :profile_tasks, :submission_comment,  :text

    add_index :profile_tasks, :source
  end
end
```

- [ ] **Step 3: Run migration**

Run: `bin/rails db:migrate`
Expected: migration applied; `profile_tasks.global_task_id` now nullable; new columns present.

- [ ] **Step 4: Commit**

```bash
git add db/migrate db/schema.rb
git commit -m "db: add source enum and custom mission fields to profile_tasks"
```

---

## Task 2: Model — ProfileTask source enum, validations, delegation rewrite

**Files:**
- Modify: `app/models/profile_task.rb`
- Modify: `spec/models/profile_task_spec.rb`
- Modify: `spec/factories/profile_tasks.rb`

- [ ] **Step 1: Update factory**

Open `spec/factories/profile_tasks.rb`. Add a `:custom` trait so specs can build custom rows:

```ruby
FactoryBot.define do
  factory :profile_task do
    profile
    global_task
    assigned_date { Date.current }
    status { :pending }
    source { :catalog }

    trait :custom do
      global_task { nil }
      source { :custom }
      custom_title { "Arrumei a estante" }
      custom_description { "Tirei o pó e organizei os livros" }
      custom_points { 25 }
      custom_category { association(:category) }
      status { :awaiting_approval }
      completed_at { Time.current }
    end
  end
end
```

- [ ] **Step 2: Write failing model specs**

Append to `spec/models/profile_task_spec.rb`:

```ruby
describe "source enum and custom missions" do
  it "defaults to catalog" do
    pt = build(:profile_task)
    expect(pt.source).to eq("catalog")
  end

  describe "custom validations" do
    let(:custom) { build(:profile_task, :custom) }

    it "is valid with required custom fields" do
      expect(custom).to be_valid
    end

    it "requires custom_title when custom" do
      custom.custom_title = nil
      expect(custom).not_to be_valid
      expect(custom.errors[:custom_title]).to be_present
    end

    it "requires custom_points >= 1" do
      custom.custom_points = 0
      expect(custom).not_to be_valid
      expect(custom.errors[:custom_points]).to be_present
    end

    it "requires custom_points <= 1000" do
      custom.custom_points = 1001
      expect(custom).not_to be_valid
      expect(custom.errors[:custom_points]).to be_present
    end

    it "requires custom_category when custom" do
      custom.custom_category = nil
      expect(custom).not_to be_valid
      expect(custom.errors[:custom_category_id]).to be_present
    end

    it "rejects global_task on custom" do
      custom.global_task = create(:global_task)
      expect(custom).not_to be_valid
      expect(custom.errors[:global_task_id]).to be_present
    end
  end

  describe "catalog validations" do
    it "requires global_task when catalog" do
      pt = build(:profile_task, global_task: nil)
      expect(pt).not_to be_valid
      expect(pt.errors[:global_task_id]).to be_present
    end
  end

  describe "delegated readers" do
    it "returns custom_title for custom missions" do
      pt = build(:profile_task, :custom, custom_title: "Lavar carro")
      expect(pt.title).to eq("Lavar carro")
    end

    it "returns custom_points for custom missions" do
      pt = build(:profile_task, :custom, custom_points: 42)
      expect(pt.points).to eq(42)
    end

    it "returns custom_category for custom missions" do
      cat = create(:category)
      pt = build(:profile_task, :custom, custom_category: cat)
      expect(pt.category).to eq(cat)
    end

    it "returns global_task fields for catalog missions" do
      gt = create(:global_task, points: 17)
      pt = build(:profile_task, global_task: gt)
      expect(pt.points).to eq(17)
    end
  end
end
```

- [ ] **Step 3: Run specs to verify they fail**

Run: `bundle exec rspec spec/models/profile_task_spec.rb -e "source enum and custom missions"`
Expected: FAIL — `source` enum / custom_* methods undefined or validations missing.

- [ ] **Step 4: Update ProfileTask model**

Replace the body of `app/models/profile_task.rb` (preserve schema header comment) with:

```ruby
class ProfileTask < ApplicationRecord
  belongs_to :profile
  belongs_to :global_task, optional: true
  belongs_to :custom_category, class_name: "Category", optional: true

  has_one_attached :proof_photo

  enum :status, { pending: 0, awaiting_approval: 1, approved: 2, rejected: 3 }, default: :pending
  enum :source, { catalog: 0, custom: 1 }, default: :catalog

  PROOF_PHOTO_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  PROOF_PHOTO_MAX_SIZE = 5.megabytes
  CUSTOM_TITLE_MAX = 120
  CUSTOM_POINTS_RANGE = (1..1000).freeze

  validate :proof_photo_valid, if: -> { proof_photo.attached? }
  validates :global_task_id, presence: true, if: :catalog?
  validates :global_task_id, absence: true, if: :custom?
  validates :custom_title, presence: true, length: { maximum: CUSTOM_TITLE_MAX }, if: :custom?
  validates :custom_points,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: CUSTOM_POINTS_RANGE.min, less_than_or_equal_to: CUSTOM_POINTS_RANGE.max },
            if: :custom?
  validates :custom_category_id, presence: true, if: :custom?

  before_validation :strip_submission_comment

  scope :for_today, ->(date = Date.current) { where(assigned_date: date) }
  scope :actionable, -> { pending.or(awaiting_approval) }

  after_commit :broadcast_approval_count
  after_update_commit :remove_from_kid_dashboard, if: -> { saved_change_to_status? && (awaiting_approval? || approved?) }

  def title
    custom? ? custom_title : global_task&.title
  end

  def description
    custom? ? custom_description : global_task&.description
  end

  def points
    custom? ? custom_points : global_task&.points
  end

  def category
    custom? ? custom_category : global_task&.category
  end

  def icon
    custom? ? nil : global_task&.icon
  end

  private

  def strip_submission_comment
    self.submission_comment = submission_comment.to_s.strip.presence
  end

  def proof_photo_valid
    if proof_photo.blob.byte_size > PROOF_PHOTO_MAX_SIZE
      errors.add(:proof_photo, :too_large, message: "must be smaller than 5 MB")
    end

    unless PROOF_PHOTO_CONTENT_TYPES.include?(proof_photo.blob.content_type)
      errors.add(:proof_photo, :invalid_content_type, message: "must be a JPEG, PNG, or WebP image")
    end
  end

  def broadcast_approval_count
    family_id = Profile.where(id: profile_id).pick(:family_id)
    return unless family_id

    count = ProfileTask.joins(:profile).where(profiles: { family_id: family_id }).awaiting_approval.count

    broadcast_update_to Family.new(id: family_id), "approvals",
      target: "pending_approvals_count",
      html: count.to_s
  end

  def remove_from_kid_dashboard
    broadcast_remove_to Profile.find(profile_id), "notifications", target: self
  end
end
```

- [ ] **Step 5: Run specs to verify they pass**

Run: `bundle exec rspec spec/models/profile_task_spec.rb`
Expected: all specs PASS.

- [ ] **Step 6: Commit**

```bash
git add app/models/profile_task.rb spec/models/profile_task_spec.rb spec/factories/profile_tasks.rb
git commit -m "feat(profile_task): add source enum, custom mission validations, and delegated readers"
```

---

## Task 3: Service — Tasks::CreateCustomService

**Files:**
- Create: `app/services/tasks/create_custom_service.rb`
- Create: `spec/services/tasks/create_custom_service_spec.rb`

- [ ] **Step 1: Write failing spec**

Create `spec/services/tasks/create_custom_service_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Tasks::CreateCustomService do
  let(:family) { create(:family) }
  let(:profile) { create(:profile, family: family, role: :child) }
  let(:category) { create(:category, family: family) }

  let(:valid_params) do
    {
      custom_title: "Arrumei a estante",
      custom_description: "Tirei o pó",
      custom_points: 25,
      custom_category_id: category.id,
      submission_comment: "Foi rapidinho"
    }
  end

  it "creates an awaiting_approval custom ProfileTask" do
    result = described_class.call(profile: profile, params: valid_params)

    expect(result).to be_success
    pt = result.data
    expect(pt).to be_persisted
    expect(pt.source).to eq("custom")
    expect(pt.status).to eq("awaiting_approval")
    expect(pt.profile).to eq(profile)
    expect(pt.custom_title).to eq("Arrumei a estante")
    expect(pt.custom_points).to eq(25)
    expect(pt.custom_category).to eq(category)
    expect(pt.submission_comment).to eq("Foi rapidinho")
    expect(pt.assigned_date).to eq(Date.current)
    expect(pt.completed_at).to be_within(2.seconds).of(Time.current)
  end

  it "returns failure when title missing" do
    result = described_class.call(profile: profile, params: valid_params.merge(custom_title: nil))
    expect(result).not_to be_success
    expect(result.error).to be_present
  end

  it "returns failure when points out of range" do
    result = described_class.call(profile: profile, params: valid_params.merge(custom_points: 0))
    expect(result).not_to be_success
  end

  it "attaches proof_photo when provided" do
    file = fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.jpg"), "image/jpeg")
    result = described_class.call(profile: profile, params: valid_params.merge(proof_photo: file))
    expect(result).to be_success
    expect(result.data.proof_photo).to be_attached
  end
end
```

If `spec/fixtures/files/sample.jpg` doesn't exist, the third test can be skipped — check first via `ls spec/fixtures/files/` and remove the test if no JPEG fixture is present (or generate one).

- [ ] **Step 2: Run spec to verify failure**

Run: `bundle exec rspec spec/services/tasks/create_custom_service_spec.rb`
Expected: FAIL — `Tasks::CreateCustomService` undefined.

- [ ] **Step 3: Implement service**

Create `app/services/tasks/create_custom_service.rb`:

```ruby
# frozen_string_literal: true

module Tasks
  class CreateCustomService < ApplicationService
    PERMITTED_KEYS = %i[custom_title custom_description custom_points custom_category_id submission_comment proof_photo].freeze

    def initialize(profile:, params:)
      @profile = profile
      @params  = params.to_h.symbolize_keys.slice(*PERMITTED_KEYS)
    end

    def call
      Rails.logger.info("[Tasks::CreateCustomService] start profile_id=#{@profile.id}")

      proof_photo = @params.delete(:proof_photo)

      profile_task = @profile.profile_tasks.build(
        @params.merge(
          source: :custom,
          status: :awaiting_approval,
          assigned_date: Date.current,
          completed_at: Time.current
        )
      )

      profile_task.proof_photo.attach(proof_photo) if proof_photo.present?

      if profile_task.save
        Rails.logger.info("[Tasks::CreateCustomService] success id=#{profile_task.id}")
        ok(profile_task)
      else
        Rails.logger.info("[Tasks::CreateCustomService] failure errors=#{profile_task.errors.full_messages}")
        fail_with(profile_task.errors.full_messages.to_sentence)
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Tasks::CreateCustomService] exception error=#{e.message}")
      fail_with(e.message)
    end
  end
end
```

- [ ] **Step 4: Run spec to verify pass**

Run: `bundle exec rspec spec/services/tasks/create_custom_service_spec.rb`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/services/tasks/create_custom_service.rb spec/services/tasks/create_custom_service_spec.rb
git commit -m "feat(tasks): add CreateCustomService for kid-proposed missions"
```

---

## Task 4: Service — Tasks::ApproveService points_override + comment in ActivityLog

**Files:**
- Modify: `app/services/tasks/approve_service.rb`
- Modify: `spec/services/tasks/approve_service_spec.rb`

- [ ] **Step 1: Write failing specs**

Append to `spec/services/tasks/approve_service_spec.rb` (inside the existing top-level describe block — adapt placement to the file's existing structure):

```ruby
describe "custom missions" do
  let(:family) { create(:family) }
  let(:profile) { create(:profile, family: family, role: :child) }
  let(:category) { create(:category, family: family) }
  let(:profile_task) do
    create(:profile_task, :custom,
           profile: profile,
           custom_category: category,
           custom_points: 50,
           submission_comment: "Foi mole")
  end

  it "applies points_override before crediting" do
    result = described_class.call(profile_task, points_override: 30)

    expect(result).to be_success
    expect(profile_task.reload.custom_points).to eq(30)
    expect(profile.reload.points).to eq(30)
  end

  it "uses original points when no override" do
    result = described_class.call(profile_task)

    expect(result).to be_success
    expect(profile.reload.points).to eq(50)
  end

  it "rejects override outside 1..1000" do
    result = described_class.call(profile_task, points_override: 0)
    expect(result).not_to be_success
    expect(profile.reload.points).to eq(0)
  end

  it "writes submission_comment into ActivityLog title note" do
    described_class.call(profile_task)
    log = ActivityLog.last
    expect(log.title).to include("Foi mole").or include("[Sugerida")
  end
end
```

- [ ] **Step 2: Run spec to verify failure**

Run: `bundle exec rspec spec/services/tasks/approve_service_spec.rb -e "custom missions"`
Expected: FAIL — `points_override` kwarg unknown.

- [ ] **Step 3: Update ApproveService**

Replace `app/services/tasks/approve_service.rb` with:

```ruby
module Tasks
  class ApproveService < ApplicationService
    POINTS_RANGE = (1..1000).freeze

    def initialize(profile_task, points_override: nil)
      @profile_task = profile_task
      @profile = profile_task.profile
      @points_override = points_override
    end

    def call
      Rails.logger.info("[Tasks::ApproveService] start profile_task_id=#{@profile_task.id}")

      unless @profile_task.awaiting_approval?
        Rails.logger.info("[Tasks::ApproveService] failure not awaiting_approval id=#{@profile_task.id}")
        return fail_with("Tarefa não está aguardando aprovação")
      end

      if @points_override.present?
        unless @profile_task.custom?
          return fail_with("Apenas missões customizadas aceitam ajuste de pontos")
        end
        unless POINTS_RANGE.cover?(@points_override.to_i)
          return fail_with("Pontos inválidos")
        end
      end

      points_before = @profile.points
      points_after = nil

      ActiveRecord::Base.transaction do
        if @points_override.present?
          @profile_task.update!(custom_points: @points_override.to_i)
        end
        @profile_task.update!(status: :approved, completed_at: Time.current)
        @profile.increment!(:points, @profile_task.points)

        ActivityLog.create!(
          profile: @profile,
          log_type: :earn,
          title: activity_log_title,
          points: @profile_task.points
        )
      end

      points_after = @profile.reload.points
      broadcast_celebration(points_before: points_before, points_after: points_after)

      Rails.logger.info("[Tasks::ApproveService] success id=#{@profile_task.id}")
      ok(@profile_task)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Tasks::ApproveService] exception id=#{@profile_task.id} error=#{e.message}")
      fail_with(e.message)
    end

    private

    def activity_log_title
      base = "Missão Concluída: #{@profile_task.title}"
      parts = [base]
      parts << "[Sugerida pela criança]" if @profile_task.custom?
      parts << "💬 #{@profile_task.submission_comment}" if @profile_task.submission_comment.present?
      parts.join(" ")
    end

    def broadcast_celebration(points_before:, points_after:)
      tier = Ui::Celebration.tier_for(:approved)
      payload = { points: @profile_task.points, message: "Tarefa aprovada!" }

      override = Streaks::CheckService.call(@profile, points_before: points_before, points_after: points_after)
      if override
        tier = override[:tier]
        payload = payload.merge(override[:payload])
      end

      Turbo::StreamsChannel.broadcast_append_to(
        "kid_#{@profile.id}",
        target: "fx_stage",
        partial: "kid/shared/celebration",
        locals: { tier: tier, payload: payload }
      )
    rescue StandardError => e
      Rails.logger.warn("[Tasks::ApproveService] broadcast failed id=#{@profile_task.id} error=#{e.message}")
    end
  end
end
```

- [ ] **Step 4: Run full ApproveService spec**

Run: `bundle exec rspec spec/services/tasks/approve_service_spec.rb`
Expected: all PASS (existing catalog tests still green).

- [ ] **Step 5: Commit**

```bash
git add app/services/tasks/approve_service.rb spec/services/tasks/approve_service_spec.rb
git commit -m "feat(tasks): ApproveService accepts points_override and logs submission_comment"
```

---

## Task 5: Service — CompleteService captures submission_comment

**Files:**
- Modify: `app/services/tasks/complete_service.rb`
- Modify: `spec/services/tasks/complete_service_spec.rb`

- [ ] **Step 1: Write failing spec**

Append to `spec/services/tasks/complete_service_spec.rb`:

```ruby
describe "submission_comment" do
  let(:family) { create(:family, require_photo: false, auto_approve_threshold: nil) }
  let(:profile) { create(:profile, family: family, role: :child) }
  let(:profile_task) { create(:profile_task, profile: profile, status: :pending) }

  it "persists the comment on submission" do
    result = described_class.call(profile_task: profile_task, submission_comment: "  fiz com carinho  ")
    expect(result).to be_success
    expect(profile_task.reload.submission_comment).to eq("fiz com carinho")
  end

  it "treats blank comment as nil" do
    result = described_class.call(profile_task: profile_task, submission_comment: "   ")
    expect(result).to be_success
    expect(profile_task.reload.submission_comment).to be_nil
  end
end
```

- [ ] **Step 2: Run spec to verify failure**

Run: `bundle exec rspec spec/services/tasks/complete_service_spec.rb -e "submission_comment"`
Expected: FAIL — `submission_comment` kwarg unknown.

- [ ] **Step 3: Update CompleteService signature and persistence**

In `app/services/tasks/complete_service.rb`:

Change `def initialize(profile_task:, proof_photo: nil)` to:

```ruby
def initialize(profile_task:, proof_photo: nil, submission_comment: nil)
  @profile_task = profile_task
  @proof_photo  = proof_photo
  @submission_comment = submission_comment
  @family       = profile_task.profile.family
end
```

Inside the `ActiveRecord::Base.transaction do` block, before `@profile_task.update!(status: :awaiting_approval)`, set the comment:

```ruby
@profile_task.proof_photo.attach(@proof_photo) if @proof_photo.present?
@profile_task.submission_comment = @submission_comment if @submission_comment
@profile_task.update!(status: :awaiting_approval)
```

(Model's `before_validation :strip_submission_comment` handles whitespace.)

- [ ] **Step 4: Run spec to verify pass**

Run: `bundle exec rspec spec/services/tasks/complete_service_spec.rb`
Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add app/services/tasks/complete_service.rb spec/services/tasks/complete_service_spec.rb
git commit -m "feat(tasks): CompleteService captures submission_comment"
```

---

## Task 6: Routes — kid missions new/create

**Files:**
- Modify: `config/routes.rb`

- [ ] **Step 1: Update routes**

In `config/routes.rb`, change the kid missions block from:

```ruby
resources :missions, only: [] do
  member { patch :complete }
end
```

to:

```ruby
resources :missions, only: %i[new create] do
  member { patch :complete }
end
```

- [ ] **Step 2: Verify routes**

Run: `bin/rails routes -g kid_missions`
Expected: lists `new_kid_mission GET`, `kid_missions POST`, `complete_kid_mission PATCH`.

- [ ] **Step 3: Commit**

```bash
git add config/routes.rb
git commit -m "routes: add new/create for kid missions"
```

---

## Task 7: Controller — Kid::MissionsController new/create + accept submission_comment

**Files:**
- Modify: `app/controllers/kid/missions_controller.rb`

- [ ] **Step 1: Update controller**

Replace `app/controllers/kid/missions_controller.rb` with:

```ruby
class Kid::MissionsController < ApplicationController
  include Authenticatable
  before_action :require_child!

  def new
    @categories = current_profile.family.categories.order(:name)
  end

  def create
    result = Tasks::CreateCustomService.call(profile: current_profile, params: custom_params)

    if result.success?
      redirect_to kid_root_path, notice: "Missão enviada para aprovação dos pais! 🚀"
    else
      @categories = current_profile.family.categories.order(:name)
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  def complete
    @profile_task = ProfileTask.includes(:global_task, profile: :family).pending.where(profile: current_profile).find(params[:id])
    result = Tasks::CompleteService.new(
      profile_task: @profile_task,
      proof_photo: complete_params[:proof_photo],
      submission_comment: complete_params[:submission_comment]
    ).call

    if result.success?
      respond_to do |format|
        format.html { redirect_to kid_root_path, notice: "Missão enviada para aprovação! 🚀" }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to kid_root_path, alert: result.error }
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("flash",
            html: "<div data-controller='flash' data-flash-dismiss-after-value='3500' class='pointer-events-auto flex items-center gap-2 px-5 py-3 rounded-full text-white font-extrabold text-[15px] shadow-lift animate-popIn' style='background-color: var(--c-red-dark);'>#{ERB::Util.html_escape(result.error)}</div>".html_safe),
            status: :unprocessable_entity
        end
      end
    end
  end

  private

  def complete_params
    params.permit(:proof_photo, :submission_comment)
  end

  def custom_params
    params.require(:profile_task).permit(:custom_title, :custom_description, :custom_points, :custom_category_id, :submission_comment, :proof_photo)
  end
end
```

- [ ] **Step 2: Smoke test**

Run: `bin/rails routes -g kid_missions` to confirm wiring.
Run: `bundle exec rspec spec/services/tasks/complete_service_spec.rb` (still passing).

- [ ] **Step 3: Commit**

```bash
git add app/controllers/kid/missions_controller.rb
git commit -m "feat(kid): MissionsController#new/create plus submission_comment on complete"
```

---

## Task 8: View — kid/missions/new form

**Files:**
- Create: `app/views/kid/missions/new.html.erb`

- [ ] **Step 1: Create view**

Create `app/views/kid/missions/new.html.erb`:

```erb
<%# Custom mission form — kid proposes a one-off task already done %>
<div class="px-5 py-6 max-w-[480px] mx-auto">
  <h1 class="font-display text-[26px] font-extrabold mb-1" style="color: var(--text);">Nova missão!</h1>
  <p class="text-[14px] font-bold mb-5" style="color: var(--text-muted);">Conta o que você fez. Os pais aprovam e você ganha estrelas! ⭐</p>

  <%= form_with url: kid_missions_path, scope: :profile_task, multipart: true, local: true,
        html: { class: "space-y-4", "data-controller": "" } do |f| %>
    <% if flash[:alert].present? %>
      <div class="rounded-[12px] border-2 px-4 py-3 text-[13px] font-bold"
           style="background: var(--danger-soft); color: var(--c-red-dark); border-color: var(--c-red-dark);">
        <%= flash[:alert] %>
      </div>
    <% end %>

    <div>
      <%= f.label :custom_title, "O que você fez?", class: "block text-[14px] font-extrabold mb-1.5", style: "color: var(--text);" %>
      <%= f.text_field :custom_title, required: true, maxlength: 120,
            placeholder: "Ex.: Arrumei a estante",
            class: "w-full px-4 py-3 rounded-[12px] border-2 text-[15px] font-bold",
            style: "border-color: var(--hairline); background: var(--surface); color: var(--text);" %>
    </div>

    <div>
      <%= f.label :custom_description, "Conta mais (opcional)", class: "block text-[14px] font-extrabold mb-1.5", style: "color: var(--text);" %>
      <%= f.text_area :custom_description, rows: 3,
            placeholder: "Como foi?",
            class: "w-full px-4 py-3 rounded-[12px] border-2 text-[14px] font-medium",
            style: "border-color: var(--hairline); background: var(--surface); color: var(--text);" %>
    </div>

    <div>
      <%= f.label :custom_points, "Quanto vale?", class: "block text-[14px] font-extrabold mb-1.5", style: "color: var(--text);" %>
      <%= f.number_field :custom_points, required: true, min: 1, max: 1000, value: 10,
            class: "w-full px-4 py-3 rounded-[12px] border-2 text-[15px] font-bold",
            style: "border-color: var(--hairline); background: var(--surface); color: var(--text);" %>
      <p class="text-[12px] font-bold mt-1" style="color: var(--text-muted);">Os pais podem ajustar.</p>
    </div>

    <div>
      <%= f.label :custom_category_id, "Categoria", class: "block text-[14px] font-extrabold mb-1.5", style: "color: var(--text);" %>
      <%= f.select :custom_category_id,
            @categories.map { |c| [c.name, c.id] },
            { include_blank: "Escolha uma..." },
            required: true,
            class: "w-full px-4 py-3 rounded-[12px] border-2 text-[15px] font-bold",
            style: "border-color: var(--hairline); background: var(--surface); color: var(--text);" %>
    </div>

    <div>
      <%= f.label :submission_comment, "Recado pros pais (opcional)", class: "block text-[14px] font-extrabold mb-1.5", style: "color: var(--text);" %>
      <%= f.text_area :submission_comment, rows: 2, maxlength: 500,
            placeholder: "Quer mandar um recado?",
            class: "w-full px-4 py-3 rounded-[12px] border-2 text-[14px] font-medium",
            style: "border-color: var(--hairline); background: var(--surface); color: var(--text);" %>
    </div>

    <div class="flex gap-3 pt-2">
      <%= link_to "Cancelar", kid_root_path,
            class: "flex-1 text-center text-[14px] uppercase tracking-[0.5px]",
            style: "background: var(--surface); color: var(--text-muted); border: 2px solid var(--hairline); border-radius: 12px; padding: 12px 0; font-weight: 800; box-shadow: 0 3px 0 var(--hairline);" %>
      <%= f.submit "Enviar pra aprovação",
            class: "flex-1 text-[14px] uppercase tracking-[0.5px]",
            style: "background: var(--primary); color: white; border: 2px solid var(--primary); border-radius: 12px; padding: 12px 0; font-weight: 800; cursor: pointer; box-shadow: 0 4px 0 var(--primary-2);" %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 2: Smoke check**

Start server: `bin/dev`. Sign in as a child profile, visit `/kid/missions/new`. Form renders without errors.

- [ ] **Step 3: Commit**

```bash
git add app/views/kid/missions/new.html.erb
git commit -m "feat(kid): custom mission form view"
```

---

## Task 9: Kid dashboard — "+ Nova missão" entry button

**Files:**
- Modify: `app/views/kid/dashboard/index.html.erb`

- [ ] **Step 1: Locate insertion point**

Open `app/views/kid/dashboard/index.html.erb`. Find the section that renders today's mission list (look for "missões de hoje", `profile_tasks.for_today`, or the missions container).

- [ ] **Step 2: Add the button**

Above the mission list (or as a prominent CTA below the wallet card), add:

```erb
<%= link_to new_kid_mission_path,
      class: "block w-full text-center text-[14px] uppercase tracking-[0.5px] mb-4",
      style: "background: var(--accent); color: var(--text); border: 2px solid var(--accent-2); border-radius: 14px; padding: 14px 0; font-weight: 800; box-shadow: 0 4px 0 var(--accent-2);" do %>
  + Nova missão
<% end %>
```

(If `--accent` token isn't defined, swap to `var(--primary)` colors but use a slightly different shade so it doesn't conflict with primary actions. Inspect `app/assets/stylesheets/tailwind/theme.css` to confirm tokens.)

- [ ] **Step 3: Visual smoke check**

Run `bin/dev`, log in as kid, confirm button appears and links to `/kid/missions/new`.

- [ ] **Step 4: Commit**

```bash
git add app/views/kid/dashboard/index.html.erb
git commit -m "feat(kid): dashboard entry button for custom mission form"
```

---

## Task 10: Submission comment on regular submit form

**Files:**
- Modify: kid mission submit form partial (locate via `grep -rn "proof_photo" app/views/kid/`)

- [ ] **Step 1: Locate the submit form**

Run: `grep -rn "proof_photo\|complete_kid_mission" app/views/kid/`
Identify the partial/view that posts to `complete_kid_mission_path`.

- [ ] **Step 2: Add comment textarea**

Inside the form, before the submit button, add:

```erb
<div class="mt-3">
  <label class="block text-[13px] font-extrabold mb-1.5" style="color: var(--text);">Quer mandar um recado? (opcional)</label>
  <textarea name="submission_comment" rows="2" maxlength="500"
            placeholder="Conta como foi…"
            class="w-full px-3 py-2 rounded-[12px] border-2 text-[14px] font-medium"
            style="border-color: var(--hairline); background: var(--surface); color: var(--text);"></textarea>
</div>
```

- [ ] **Step 3: Smoke test**

Submit a mission with a comment via UI; confirm `ProfileTask#submission_comment` persists (via Rails console: `ProfileTask.last.submission_comment`).

- [ ] **Step 4: Commit**

```bash
git add app/views/kid
git commit -m "feat(kid): submission_comment textarea on mission submit form"
```

---

## Task 11: ApprovalRow component renders comment + custom badge + editable points

**Files:**
- Modify: `app/components/ui/approval_row/component.rb`
- Modify: `app/components/ui/approval_row/component.html.erb`

- [ ] **Step 1: Extend component initializer**

In `app/components/ui/approval_row/component.rb`, add new kwargs to `initialize`:

```ruby
def initialize(kid:, title:, meta:, points:, approve_url:, reject_url:,
               dom_id: nil, kid_chip_text: nil, category_label: nil,
               points_sign: "+", approve_label: "Aprovar", reject_label: "Rejeitar",
               reject_confirm: nil, approve_submits_with: "Aprovando...",
               reject_submits_with: "Rejeitando...", bulk: false, bulk_value: nil,
               profile_task: nil, compact: false, category: nil,
               submission_comment: nil, custom: false, points_editable: false)
  # ...existing assignments...
  @submission_comment = submission_comment
  @custom = custom
  @points_editable = points_editable
  super()
end

attr_reader :submission_comment, :custom, :points_editable
```

(Add `:submission_comment, :custom, :points_editable` to the existing `attr_reader` line.)

- [ ] **Step 2: Update template**

In `app/components/ui/approval_row/component.html.erb`, in the `else` (full layout) branch, after the `<div class="flex flex-wrap items-center gap-1.5">` chips block, add the custom badge:

```erb
<% if custom %>
  <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-extrabold uppercase tracking-[0.5px]"
        style="background: var(--accent-soft, #FFF4D6); color: var(--c-amber-dark, #B45309); border: 1px solid var(--c-amber-dark, #B45309);">
    Sugerida pela criança
  </span>
<% end %>
```

After the points/meta div (before the closing `</div>` of the row's content area) and before the action buttons, add the comment block:

```erb
<% if submission_comment.present? %>
  <div class="mt-2 px-3 py-2 rounded-[10px] border-l-4 text-[13px] font-medium"
       style="background: var(--surface-2, #F5F5F7); border-color: var(--primary); color: var(--text);">
    💬 <%= submission_comment %>
  </div>
<% end %>
```

Replace the approve `button_to` (full layout only) with a form that includes a points override field when `points_editable`:

```erb
<%= form_with url: approve_url, method: :patch, class: "flex-1",
      data: { turbo_frame: "approvals_list", turbo_submits_with: approve_submits_with } do |f| %>
  <% if points_editable %>
    <div class="flex items-center gap-2 mb-2">
      <label class="text-[12px] font-extrabold" style="color: var(--text-muted);">Pontos:</label>
      <%= f.number_field :points_override, value: points, min: 1, max: 1000,
            class: "w-20 px-2 py-1 rounded-[8px] border-2 text-[13px] font-bold text-center",
            style: "border-color: var(--hairline); background: var(--surface); color: var(--text);" %>
    </div>
  <% end %>
  <%= f.submit approve_label,
        class: "w-full text-sm uppercase tracking-[0.5px]",
        style: "background: var(--primary); color: white; border: 2px solid var(--primary); border-radius: 12px; padding: 10px 0; font-weight: 800; cursor: pointer; box-shadow: 0 3px 0 var(--primary-2);" %>
<% end %>
```

(Keep the reject `button_to` as-is.)

- [ ] **Step 3: Pass new props from approvals view**

Open `app/views/parent/approvals/index.html.erb` (or whatever partial renders `Ui::ApprovalRow::Component`). Find the call site and add:

```ruby
submission_comment: profile_task.submission_comment,
custom: profile_task.custom?,
points_editable: profile_task.custom?
```

If the same component is used elsewhere in compact mode (kid dashboard), don't enable `points_editable` there — only on parent approval queue.

- [ ] **Step 4: Smoke test**

`bin/dev`, kid creates custom mission, parent visits approvals page, sees badge + comment + points input. Adjust value, click Aprovar, verify points credited at override value via `ActivityLog.last`.

- [ ] **Step 5: Commit**

```bash
git add app/components/ui/approval_row app/views/parent/approvals
git commit -m "feat(approvals): render submission_comment, custom badge, and editable points"
```

---

## Task 12: Controller — Parent::ApprovalsController#approve accepts points_override

**Files:**
- Modify: `app/controllers/parent/approvals_controller.rb`

- [ ] **Step 1: Update approve action**

In `app/controllers/parent/approvals_controller.rb`, change:

```ruby
def approve
  @profile_task = family_profile_tasks.find(params[:id])
  result = Tasks::ApproveService.call(@profile_task)
  respond_after(result, success_msg: "Tarefa aprovada com sucesso!", fail_msg: "Não foi possível aprovar a tarefa.")
end
```

to:

```ruby
def approve
  @profile_task = family_profile_tasks.find(params[:id])
  override = params[:points_override].presence&.to_i
  result = Tasks::ApproveService.call(@profile_task, points_override: override)
  respond_after(result, success_msg: "Tarefa aprovada com sucesso!", fail_msg: "Não foi possível aprovar a tarefa.")
end
```

- [ ] **Step 2: Manual smoke test**

Use parent UI to approve a custom mission with adjusted points; verify ActivityLog points match override.

- [ ] **Step 3: Commit**

```bash
git add app/controllers/parent/approvals_controller.rb
git commit -m "feat(parent): approvals#approve accepts points_override for custom missions"
```

---

## Task 13: System spec — kid creates custom mission, parent approves with override

**Files:**
- Create: `spec/system/kid/custom_mission_spec.rb`

- [ ] **Step 1: Write the spec**

Create `spec/system/kid/custom_mission_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Kid custom mission flow", type: :system do
  let(:family) { create(:family) }
  let!(:category) { create(:category, family: family, name: "Casa") }
  let!(:parent) { create(:profile, family: family, role: :parent, name: "Mae") }
  let!(:kid)    { create(:profile, family: family, role: :child,  name: "Ana", points: 0) }

  it "kid proposes mission, parent adjusts points and approves" do
    sign_in_as(kid)
    visit kid_root_path
    click_link "+ Nova missão"

    fill_in "O que você fez?", with: "Lavei a louça"
    fill_in "Quanto vale?",   with: "50"
    select "Casa", from: "Categoria"
    fill_in "Recado pros pais (opcional)", with: "Foi pesado"
    click_button "Enviar pra aprovação"

    expect(page).to have_content("Missão enviada para aprovação")

    sign_in_as(parent)
    visit parent_approvals_path

    expect(page).to have_content("Lavei a louça")
    expect(page).to have_content("Sugerida pela criança")
    expect(page).to have_content("Foi pesado")

    fill_in "points_override", with: "30"
    click_button "Aprovar"

    expect(kid.reload.points).to eq(30)
    log = ActivityLog.where(profile: kid).last
    expect(log.points).to eq(30)
    expect(log.title).to include("Lavei a louça")
  end
end
```

(Use existing `sign_in_as` test helper; if absent, see other system specs for the pattern — likely sets `session[:profile_id]` via a test login route.)

- [ ] **Step 2: Run spec**

Run: `bundle exec rspec spec/system/kid/custom_mission_spec.rb`
Expected: PASS.

If sign-in helper differs, adapt to the project's pattern (check existing system specs e.g. `grep -rn "sign_in_as\|session\[:profile_id\]" spec/system/ spec/support/`).

- [ ] **Step 3: Commit**

```bash
git add spec/system/kid/custom_mission_spec.rb
git commit -m "test(system): kid custom mission flow with parent points override"
```

---

## Task 14: System spec — submission comment on regular mission

**Files:**
- Create: `spec/system/kid/submission_comment_spec.rb`

- [ ] **Step 1: Write the spec**

Create `spec/system/kid/submission_comment_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Kid submission comment flow", type: :system do
  let(:family) { create(:family, require_photo: false, auto_approve_threshold: nil) }
  let!(:parent) { create(:profile, family: family, role: :parent, name: "Pai") }
  let!(:kid)    { create(:profile, family: family, role: :child,  name: "Beto", points: 0) }
  let!(:global_task) { create(:global_task, family: family, title: "Escovar dentes", points: 5) }
  let!(:profile_task) { create(:profile_task, profile: kid, global_task: global_task, status: :pending, assigned_date: Date.current) }

  it "kid submits with comment, parent sees it on approval queue" do
    sign_in_as(kid)
    visit kid_root_path

    # find and submit the mission with a comment — adapt selectors to your dashboard
    within("##{ActionView::RecordIdentifier.dom_id(profile_task)}") do
      click_button "Concluir" rescue click_link "Concluir"
    end
    fill_in "submission_comment", with: "fiz antes de dormir"
    click_button "Enviar"

    sign_in_as(parent)
    visit parent_approvals_path

    expect(page).to have_content("Escovar dentes")
    expect(page).to have_content("fiz antes de dormir")
  end
end
```

If the kid submit flow doesn't use a separate confirmation page (the "Concluir" button submits directly), adapt: open the dashboard, fill the comment textarea inline, then click Concluir.

- [ ] **Step 2: Run spec**

Run: `bundle exec rspec spec/system/kid/submission_comment_spec.rb`
Expected: PASS. If it fails on selectors, inspect the actual dashboard markup and adjust.

- [ ] **Step 3: Commit**

```bash
git add spec/system/kid/submission_comment_spec.rb
git commit -m "test(system): submission_comment flows from kid submit to parent queue"
```

---

## Task 15: Final verification — full suite + lint

**Files:** none

- [ ] **Step 1: Run full RSpec suite**

Run: `bundle exec rspec`
Expected: all green. Fix any incidental failures (factory updates, fixture drift).

- [ ] **Step 2: Lint**

Run: `bin/rubocop -A`
Stage and commit any auto-fixes:

```bash
git add -A
git diff --cached --quiet || git commit -m "chore: rubocop autocorrect"
```

- [ ] **Step 3: Brakeman**

Run: `bin/brakeman -q`
Expected: no new warnings. Investigate if any.

- [ ] **Step 4: Final commit if any pending changes**

```bash
git status
```

Should be clean.

---

## Self-Review Notes

- Spec coverage check: every section in the design spec maps to a task —
  - Schema → Task 1
  - Model validations + delegation → Task 2
  - CreateCustomService → Task 3
  - ApproveService points_override + ActivityLog comment → Task 4
  - CompleteService submission_comment → Task 5
  - Routes → Task 6
  - Kid controller → Task 7
  - Custom mission view → Task 8
  - Dashboard entry → Task 9
  - Comment textarea on submit form → Task 10
  - ApprovalRow rendering (comment + badge + points input) → Task 11
  - Parent approve controller wiring → Task 12
  - System specs → Tasks 13, 14
  - Verification → Task 15
- Type/method consistency: `points_override` kwarg used consistently in service, controller, form field. `custom?` predicate used throughout. `submission_comment` column name consistent everywhere.
- No placeholders.

# Repeatable Missions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow each `GlobalTask` to declare a per-period completion cap (default 1) so missions like "brush teeth" can be done multiple times in the same window while still going through the existing approval flow.

**Architecture:** Keep `ProfileTask` as the unit of submission (each row carries its own photo, comment, status, timestamps). A new `Tasks::SlotRefresher` service guarantees exactly one `pending` `ProfileTask` per `(profile, global_task, period)` while consumed slots (`awaiting_approval` + `approved`) are below the cap. `DailyResetService`, `CompleteService`, `ApproveService`, and `RejectService` invoke the refresher at the right moments. The parent form gets a "Repetível no período" toggle wired to a numeric input, defaulting to 1 (today's behaviour).

**Tech Stack:** Rails 8.1 · Ruby 3.3 · PostgreSQL 16 · Stimulus · Turbo · ViewComponent · RSpec · FactoryBot · Capybara.

---

## File map

- Create: `db/migrate/<timestamp>_add_max_completions_per_period_to_global_tasks.rb`
- Modify: `app/models/global_task.rb`
- Modify: `app/models/profile_task.rb`
- Create: `app/services/tasks/slot_refresher.rb`
- Modify: `app/services/tasks/daily_reset_service.rb`
- Modify: `app/services/tasks/complete_service.rb`
- Modify: `app/services/tasks/approve_service.rb`
- Modify: `app/services/tasks/reject_service.rb`
- Modify: `app/controllers/parent/global_tasks_controller.rb`
- Modify: `app/views/parent/global_tasks/_form.html.erb`
- Create: `app/assets/controllers/repeatable_controller.js`
- Modify: `spec/factories/global_tasks.rb`
- Modify: `spec/models/global_task_spec.rb`
- Modify: `spec/models/profile_task_spec.rb`
- Create: `spec/services/tasks/slot_refresher_spec.rb`
- Modify: `spec/services/tasks/daily_reset_service_spec.rb`
- Modify: `spec/services/tasks/complete_service_spec.rb`
- Modify: `spec/services/tasks/approve_service_spec.rb`
- Modify: `spec/services/tasks/reject_service_spec.rb`
- Create: `spec/system/kid/repeatable_missions_spec.rb`
- Create: `spec/system/parent/global_task_repeatable_form_spec.rb`

> All commands run inside the `web` container. Use `make rspec` for the full suite or `make shell` then `bundle exec rspec <path>:<line>` for a single example. Never run `bundle exec rspec` from the host.

---

## Task 1: Migration and `GlobalTask` model changes

**Files:**
- Create: `db/migrate/<timestamp>_add_max_completions_per_period_to_global_tasks.rb`
- Modify: `app/models/global_task.rb`
- Modify: `spec/models/global_task_spec.rb`
- Modify: `spec/factories/global_tasks.rb`

- [ ] **Step 1: Generate migration**

Run:

```bash
make shell
# inside web container:
bin/rails generate migration AddMaxCompletionsPerPeriodToGlobalTasks max_completions_per_period:integer
```

- [ ] **Step 2: Edit the migration file**

Replace contents with:

```ruby
class AddMaxCompletionsPerPeriodToGlobalTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :global_tasks, :max_completions_per_period, :integer, default: 1, null: false
    add_check_constraint :global_tasks,
      "max_completions_per_period >= 1",
      name: "max_completions_positive"
  end
end
```

- [ ] **Step 3: Run the migration**

```bash
bin/rails db:migrate
```

Expected: migration runs cleanly, schema annotation shows new column with `default(1), not null`.

- [ ] **Step 4: Update the factory default to keep tests deterministic**

Edit `spec/factories/global_tasks.rb`. After the `days_of_week { [] }` line and before the first `trait`, add:

```ruby
    max_completions_per_period { 1 }

    trait :repeatable do
      max_completions_per_period { 3 }
    end
```

- [ ] **Step 5: Add failing model specs**

Append the following to `spec/models/global_task_spec.rb` inside the existing `RSpec.describe GlobalTask, type: :model do` block (before its final `end`):

```ruby
  describe "max_completions_per_period" do
    subject(:task) { build(:global_task, max_completions_per_period: 3) }

    it "is valid with a value between 1 and 20" do
      expect(task).to be_valid
    end

    it "rejects values below 1" do
      task.max_completions_per_period = 0
      expect(task).not_to be_valid
      expect(task.errors[:max_completions_per_period]).to be_present
    end

    it "rejects values above 20" do
      task.max_completions_per_period = 21
      expect(task).not_to be_valid
    end

    it "forces max=1 when frequency is once" do
      task = build(:global_task, frequency: :once, max_completions_per_period: 5)
      task.valid?
      expect(task.max_completions_per_period).to eq(1)
    end
  end

  describe "#repeatable?" do
    it "is false when max_completions_per_period is 1" do
      expect(build(:global_task, max_completions_per_period: 1).repeatable?).to be(false)
    end

    it "is true when max_completions_per_period is greater than 1" do
      expect(build(:global_task, max_completions_per_period: 2).repeatable?).to be(true)
    end
  end
```

- [ ] **Step 6: Run the specs to confirm they fail**

```bash
make shell
bundle exec rspec spec/models/global_task_spec.rb -e "max_completions_per_period" -e "repeatable?"
```

Expected: failures (no validation, no `repeatable?` method, `before_validation` callback not in place).

- [ ] **Step 7: Update `GlobalTask` model**

Edit `app/models/global_task.rb`. Inside the class, after the existing `validates :day_of_month, ...` line, add:

```ruby
  MAX_COMPLETIONS_RANGE = (1..20).freeze

  before_validation :force_single_completion_for_once

  validates :max_completions_per_period,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: MAX_COMPLETIONS_RANGE.min,
              less_than_or_equal_to: MAX_COMPLETIONS_RANGE.max
            }

  def repeatable?
    max_completions_per_period.to_i > 1
  end

  private

  def force_single_completion_for_once
    self.max_completions_per_period = 1 if frequency.to_s == "once"
  end
```

- [ ] **Step 8: Run the specs to confirm they pass**

```bash
bundle exec rspec spec/models/global_task_spec.rb -e "max_completions_per_period" -e "repeatable?"
```

Expected: all green.

- [ ] **Step 9: Run the full model suite to confirm no regression**

```bash
bundle exec rspec spec/models
```

Expected: all green.

- [ ] **Step 10: Re-run the schema annotation (if the project annotates) and commit**

```bash
exit  # leave web container if you used make shell
git add db/migrate db/schema.rb app/models/global_task.rb spec/models/global_task_spec.rb spec/factories/global_tasks.rb
git commit -m "feat(global_task): add max_completions_per_period with validations"
```

---

## Task 2: `ProfileTask` period scopes

**Files:**
- Modify: `app/models/profile_task.rb`
- Modify: `spec/models/profile_task_spec.rb`

- [ ] **Step 1: Add failing specs for `period_range`, `in_period_for`, `consuming_slot`**

Append to `spec/models/profile_task_spec.rb` inside the existing `RSpec.describe ProfileTask, type: :model do` block (before its final `end`):

```ruby
  describe ".period_range" do
    let(:family) { create(:family, week_start: 1) } # Monday
    let(:date)   { Date.new(2026, 4, 29) } # Wednesday

    it "returns a single-day range for daily" do
      gt = create(:global_task, :daily, family: family)
      expect(ProfileTask.period_range(gt, date)).to eq(date..date)
    end

    it "returns the Monday-to-Sunday range for weekly when week_start is Monday" do
      gt = create(:global_task, :weekly, family: family)
      expected = Date.new(2026, 4, 27)..Date.new(2026, 5, 3)
      expect(ProfileTask.period_range(gt, date)).to eq(expected)
    end

    it "returns the calendar month for monthly" do
      gt = create(:global_task, family: family, frequency: :monthly, day_of_month: 15)
      expected = Date.new(2026, 4, 1)..Date.new(2026, 4, 30)
      expect(ProfileTask.period_range(gt, date)).to eq(expected)
    end

    it "returns a wide-open range starting at the epoch for once" do
      gt = create(:global_task, family: family, frequency: :once)
      range = ProfileTask.period_range(gt, date)
      expect(range.cover?(Date.new(2000, 1, 1))).to be(true)
      expect(range.cover?(date)).to be(true)
    end
  end

  describe ".in_period_for and .consuming_slot" do
    let(:family) { create(:family, week_start: 1) }
    let(:profile) { create(:profile, :child, family: family) }
    let(:gt)      { create(:global_task, :daily, family: family) }
    let(:date)    { Date.new(2026, 4, 29) }

    it "scopes profile_tasks by the period's date range" do
      pt_today    = create(:profile_task, profile: profile, global_task: gt, assigned_date: date)
      _pt_yday    = create(:profile_task, profile: profile, global_task: gt, assigned_date: date - 1)

      expect(ProfileTask.in_period_for(gt, date)).to eq([pt_today])
    end

    it "filters to rows that consume a slot" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :pending)
      awa  = create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :awaiting_approval)
      appr = create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :approved)
      create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :rejected)

      expect(ProfileTask.consuming_slot.where(id: [awa.id, appr.id])).to match_array([awa, appr])
      expect(ProfileTask.consuming_slot.where(profile: profile, global_task: gt).count).to eq(2)
    end
  end
```

- [ ] **Step 2: Run the specs to confirm they fail**

```bash
make shell
bundle exec rspec spec/models/profile_task_spec.rb -e "period_range" -e "in_period_for and .consuming_slot"
```

Expected: failures (`undefined method period_range`, etc.).

- [ ] **Step 3: Update `ProfileTask` model**

Edit `app/models/profile_task.rb`. Replace the existing `scope :for_today` line and the `scope :actionable` line block with:

```ruby
  scope :for_today, ->(date = Date.current) { where(assigned_date: date) }
  scope :actionable, -> { pending.or(awaiting_approval) }
  scope :in_period_for, ->(global_task, date) {
    where(assigned_date: ProfileTask.period_range(global_task, date))
  }
  scope :consuming_slot, -> { where(status: %i[awaiting_approval approved]) }

  def self.period_range(global_task, date)
    case global_task.frequency.to_s
    when "weekly"
      week_start_sym = global_task.family.week_start.to_i.zero? ? :sunday : :monday
      date.beginning_of_week(week_start_sym)..date.end_of_week(week_start_sym)
    when "monthly"
      date.beginning_of_month..date.end_of_month
    when "once"
      Date.new(2000, 1, 1)..date.end_of_day.to_date
    else
      date..date
    end
  end
```

> The `for_today` and `actionable` scopes are unchanged — keep them exactly as-is. Only the two new scopes and the class method are added.

- [ ] **Step 4: Run the specs to confirm they pass**

```bash
bundle exec rspec spec/models/profile_task_spec.rb -e "period_range" -e "in_period_for and .consuming_slot"
```

Expected: all green.

- [ ] **Step 5: Run the full model suite**

```bash
bundle exec rspec spec/models
```

Expected: all green.

- [ ] **Step 6: Commit**

```bash
exit
git add app/models/profile_task.rb spec/models/profile_task_spec.rb
git commit -m "feat(profile_task): add period_range, in_period_for, consuming_slot scopes"
```

---

## Task 3: `Tasks::SlotRefresher` service

**Files:**
- Create: `app/services/tasks/slot_refresher.rb`
- Create: `spec/services/tasks/slot_refresher_spec.rb`

- [ ] **Step 1: Write the failing service spec**

Create `spec/services/tasks/slot_refresher_spec.rb` with:

```ruby
require "rails_helper"

RSpec.describe Tasks::SlotRefresher do
  let(:family)  { create(:family, week_start: 1) }
  let(:profile) { create(:profile, :child, family: family) }
  let(:date)    { Date.new(2026, 4, 29) }

  subject(:call) { described_class.new(profile: profile, global_task: gt, date: date).call }

  describe "with a non-repeatable daily task (max=1)" do
    let(:gt) { create(:global_task, :daily, family: family, max_completions_per_period: 1) }

    it "creates one pending profile_task when none exists" do
      expect { call }.to change { ProfileTask.count }.by(1)
      expect(ProfileTask.last).to have_attributes(
        profile_id: profile.id,
        global_task_id: gt.id,
        assigned_date: date,
        status: "pending"
      )
    end

    it "does not duplicate the pending row on repeated calls" do
      call
      expect { call }.not_to change { ProfileTask.count }
    end

    it "destroys the pending row once a slot is consumed (awaiting_approval)" do
      pending_pt = create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :awaiting_approval)
      orphan = create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :pending)

      expect { call }.to change { ProfileTask.where(id: orphan.id).count }.from(1).to(0)
      expect(ProfileTask.where(id: pending_pt.id)).to exist
    end

    it "does not respawn after approval (cap reached)" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :approved)
      expect { call }.not_to change { ProfileTask.where(status: :pending).count }
      expect(ProfileTask.where(profile: profile, global_task: gt, status: :pending)).to be_empty
    end
  end

  describe "with a repeatable daily task (max=3)" do
    let(:gt) { create(:global_task, :daily, family: family, max_completions_per_period: 3) }

    it "creates a fresh pending row after a completion goes awaiting_approval" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :awaiting_approval)
      expect { call }.to change { ProfileTask.where(profile: profile, global_task: gt, status: :pending).count }.from(0).to(1)
    end

    it "creates a fresh pending row after one approval and one awaiting_approval (1 + 1 = 2 < 3)" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :approved)
      create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :awaiting_approval)
      expect { call }.to change { ProfileTask.where(status: :pending).count }.by(1)
    end

    it "stops creating pending rows once the cap of 3 is reached" do
      3.times { create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :approved) }
      expect { call }.not_to change { ProfileTask.where(status: :pending).count }
    end

    it "treats rejected rows as not consuming a slot" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :rejected)
      expect { call }.to change { ProfileTask.where(status: :pending).count }.by(1)
    end

    it "respects the assigned_date when computing the period" do
      yesterday = date - 1
      create(:profile_task, profile: profile, global_task: gt, assigned_date: yesterday, status: :approved)
      expect { call }.to change { ProfileTask.where(assigned_date: date, status: :pending).count }.by(1)
    end
  end

  describe "with a repeatable weekly task (max=2)" do
    let(:gt) { create(:global_task, :weekly, family: family, days_of_week: ["3"], max_completions_per_period: 2) }

    it "treats approvals across the same calendar week as part of the same cap" do
      monday    = date - 2 # 2026-04-27
      wednesday = date     # 2026-04-29
      create(:profile_task, profile: profile, global_task: gt, assigned_date: monday, status: :approved)
      create(:profile_task, profile: profile, global_task: gt, assigned_date: wednesday, status: :approved)

      expect { call }.not_to change { ProfileTask.where(status: :pending).count }
    end
  end
end
```

- [ ] **Step 2: Run the spec to confirm it fails**

```bash
make shell
bundle exec rspec spec/services/tasks/slot_refresher_spec.rb
```

Expected: failures (`uninitialized constant Tasks::SlotRefresher`).

- [ ] **Step 3: Create the service file**

Create `app/services/tasks/slot_refresher.rb`:

```ruby
# frozen_string_literal: true

module Tasks
  class SlotRefresher < ApplicationService
    def initialize(profile:, global_task:, date: nil)
      @profile = profile
      @global_task = global_task
      @date = date || default_date
    end

    def call
      return ok(:not_applicable) if @global_task.nil?

      ActiveRecord::Base.transaction do
        period_pts = ProfileTask
          .where(profile: @profile, global_task: @global_task)
          .in_period_for(@global_task, @date)
          .lock

        consumed = period_pts.consuming_slot.count
        max = @global_task.max_completions_per_period.to_i

        if consumed >= max
          period_pts.pending.destroy_all
          return ok(:cap_reached)
        end

        unless period_pts.pending.exists?
          ProfileTask.create!(
            profile: @profile,
            global_task: @global_task,
            assigned_date: @date,
            status: :pending
          )
        end

        ok(:slot_available)
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[Tasks::SlotRefresher] error profile_id=#{@profile.id} global_task_id=#{@global_task&.id} error=#{e.message}")
      fail_with(e.message)
    end

    private

    def default_date
      Time.current.in_time_zone(@profile.family.timezone).to_date
    end
  end
end
```

- [ ] **Step 4: Run the spec to confirm it passes**

```bash
bundle exec rspec spec/services/tasks/slot_refresher_spec.rb
```

Expected: all green.

- [ ] **Step 5: Run all service specs to confirm no regression**

```bash
bundle exec rspec spec/services
```

Expected: all green (existing service specs unaffected — refresher is not yet wired in).

- [ ] **Step 6: Commit**

```bash
exit
git add app/services/tasks/slot_refresher.rb spec/services/tasks/slot_refresher_spec.rb
git commit -m "feat(tasks): add SlotRefresher service for per-period slot management"
```

---

## Task 4: Wire `SlotRefresher` into `DailyResetService`

**Files:**
- Modify: `app/services/tasks/daily_reset_service.rb`
- Modify: `spec/services/tasks/daily_reset_service_spec.rb`

- [ ] **Step 1: Add a failing spec for repeatable mission behaviour during reset**

Append the following inside the existing `describe '#call' do` block in `spec/services/tasks/daily_reset_service_spec.rb`, before the final `end` of that block:

```ruby
    context 'with repeatable daily missions (max=3)' do
      let(:monday) { Date.new(2024, 1, 1) }
      let!(:repeatable_task) { create(:global_task, :daily, family: family, max_completions_per_period: 3) }

      it 'creates exactly one pending row per child (not three)' do
        described_class.new(date: monday, family: family).call
        expect(ProfileTask.where(global_task: repeatable_task, assigned_date: monday, status: :pending).count).to eq(2) # one per child
      end

      it 'does not respawn pending rows already consumed by prior runs' do
        described_class.new(date: monday, family: family).call
        ProfileTask.where(global_task: repeatable_task).each do |pt|
          pt.update!(status: :awaiting_approval)
        end

        expect {
          described_class.new(date: monday, family: family).call
        }.to change { ProfileTask.where(global_task: repeatable_task, status: :pending).count }.from(0).to(2)
      end
    end
```

- [ ] **Step 2: Run the new spec to confirm it fails**

```bash
make shell
bundle exec rspec spec/services/tasks/daily_reset_service_spec.rb -e "with repeatable daily missions"
```

Expected: failures (existing `find_or_create_by!` does not respawn after `awaiting_approval`).

- [ ] **Step 3: Update `DailyResetService` to use `SlotRefresher`**

Replace the body of the `target_profiles.each` block in `app/services/tasks/daily_reset_service.rb` with:

```ruby
        target_profiles.each do |child|
          before_count = ProfileTask.where(profile: child, global_task: global_task).count
          Tasks::SlotRefresher.new(profile: child, global_task: global_task, date: @date).call
          created_count += 1 if ProfileTask.where(profile: child, global_task: global_task).count > before_count
        end
```

The full updated `call` method should now read:

```ruby
    def call
      Rails.logger.info("[Tasks::DailyResetService] start date=#{@date} family_id=#{@family&.id || 'all'}")

      tasks_scope =
        if @family
          @family.global_tasks.includes(:assigned_profiles, family: :profiles)
        else
          GlobalTask.includes(:assigned_profiles, family: :profiles)
        end

      created_count = 0

      tasks_scope.find_each do |global_task|
        next unless global_task.active?
        next unless applicable_today?(global_task)

        target_profiles = if global_task.assigned_profiles.any?
                            global_task.assigned_profiles.select(&:child?)
        else
                            global_task.family.profiles.select(&:child?)
        end

        target_profiles.each do |child|
          before_count = ProfileTask.where(profile: child, global_task: global_task).count
          Tasks::SlotRefresher.new(profile: child, global_task: global_task, date: @date).call
          created_count += 1 if ProfileTask.where(profile: child, global_task: global_task).count > before_count
        end
      end

      Rails.logger.info("[Tasks::DailyResetService] success created=#{created_count} family_id=#{@family&.id || 'all'}")
      created_count
    end
```

Leave `applicable_today?` exactly as it is.

- [ ] **Step 4: Run the new spec to confirm it passes**

```bash
bundle exec rspec spec/services/tasks/daily_reset_service_spec.rb -e "with repeatable daily missions"
```

Expected: green.

- [ ] **Step 5: Run the full daily-reset spec to confirm no regression**

```bash
bundle exec rspec spec/services/tasks/daily_reset_service_spec.rb
```

Expected: all green. The original "does not duplicate tasks if run twice", "instantiates only daily tasks", "monthly missions", "once missions", and "with explicit assignments" contexts must still pass — `SlotRefresher` is idempotent for `max=1` so existing behaviour is preserved.

- [ ] **Step 6: Commit**

```bash
exit
git add app/services/tasks/daily_reset_service.rb spec/services/tasks/daily_reset_service_spec.rb
git commit -m "refactor(tasks): use SlotRefresher in DailyResetService"
```

---

## Task 5: Wire `SlotRefresher` into `CompleteService`

**Files:**
- Modify: `app/services/tasks/complete_service.rb`
- Modify: `spec/services/tasks/complete_service_spec.rb`

- [ ] **Step 1: Add a failing spec for the post-complete spawn**

Append to `spec/services/tasks/complete_service_spec.rb` inside the outer `RSpec.describe Tasks::CompleteService do` block (before its final `end`):

```ruby
  describe "with a repeatable mission (max=3)" do
    let(:family) { create(:family) }
    let(:profile) { create(:profile, :child, family: family) }
    let(:gt) { create(:global_task, :daily, family: family, max_completions_per_period: 3) }
    let(:pt) { create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :pending) }

    it "spawns a new pending row after the current one moves to awaiting_approval" do
      expect {
        described_class.new(profile_task: pt).call
      }.to change {
        ProfileTask.where(profile: profile, global_task: gt, status: :pending).count
      }.from(1).to(1) # the original flips, a new one is created — net unchanged
      expect(pt.reload.status).to eq("awaiting_approval")
      expect(ProfileTask.where(profile: profile, global_task: gt, status: :pending).count).to eq(1)
    end

    it "does not spawn a new pending row once the cap is reached" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :approved)
      create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :approved)
      # 2 approved + 1 about-to-be-awaiting = 3, cap reached
      described_class.new(profile_task: pt).call
      expect(ProfileTask.where(profile: profile, global_task: gt, status: :pending)).to be_empty
    end
  end
```

- [ ] **Step 2: Run the new spec to confirm it fails**

```bash
make shell
bundle exec rspec spec/services/tasks/complete_service_spec.rb -e "with a repeatable mission"
```

Expected: failures (no respawn yet).

- [ ] **Step 3: Update `CompleteService`**

Edit `app/services/tasks/complete_service.rb`. Inside the existing `ActiveRecord::Base.transaction do` block, immediately after `@profile_task.update!(status: :awaiting_approval)` and before the auto-approve `if` branch, insert the refresher call. The relevant slice should now read:

```ruby
      ActiveRecord::Base.transaction do
        @profile_task.proof_photo.attach(@proof_photo) if @proof_photo.present?
        @profile_task.submission_comment = @submission_comment unless @submission_comment.nil?
        @profile_task.update!(status: :awaiting_approval)

        Tasks::SlotRefresher.new(
          profile: @profile_task.profile,
          global_task: @profile_task.global_task,
          date: @profile_task.assigned_date
        ).call if @profile_task.global_task.present?

        # Status must be :awaiting_approval before ApproveService runs —
        # ApproveService guards on awaiting_approval? so the flip above must
        # happen first. Both run inside the same transaction (Rails re-entrant).
        #
        # Auto-approve fires when:
        #   - auto_approve_threshold is set (nil = feature disabled)
        #   - task points <= threshold (threshold: 0 approves every free task)
        #   - family does NOT require_photo (photos always need human review)
        if @family.auto_approve_threshold.present? &&
           @profile_task.global_task.points <= @family.auto_approve_threshold &&
           !@family.require_photo?
          Tasks::ApproveService.new(@profile_task).call
          @profile_task.reload
          auto_approved = true
        end
      end
```

> The `if @profile_task.global_task.present?` guard skips refresher for `source: :custom` rows, which have no `global_task`.

- [ ] **Step 4: Run the new spec to confirm it passes**

```bash
bundle exec rspec spec/services/tasks/complete_service_spec.rb -e "with a repeatable mission"
```

Expected: green.

- [ ] **Step 5: Run the full complete-service spec**

```bash
bundle exec rspec spec/services/tasks/complete_service_spec.rb
```

Expected: all green. Existing single-shot behaviour is preserved because for `max=1` the refresher hits `consumed >= max` and removes any orphan pending — there is none to remove.

- [ ] **Step 6: Commit**

```bash
exit
git add app/services/tasks/complete_service.rb spec/services/tasks/complete_service_spec.rb
git commit -m "feat(tasks): refresh slot after complete for repeatable missions"
```

---

## Task 6: Wire `SlotRefresher` into `ApproveService`

**Files:**
- Modify: `app/services/tasks/approve_service.rb`
- Modify: `spec/services/tasks/approve_service_spec.rb`

- [ ] **Step 1: Add a failing spec**

Append to `spec/services/tasks/approve_service_spec.rb` inside the outer describe block:

```ruby
  describe "post-approval slot refresh on a repeatable mission" do
    let(:family) { create(:family) }
    let(:profile) { create(:profile, :child, family: family) }
    let(:gt) { create(:global_task, :daily, family: family, max_completions_per_period: 3) }
    let(:awaiting) { create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :awaiting_approval) }

    it "leaves a pending row available when there is still slot capacity" do
      described_class.new(awaiting).call
      expect(ProfileTask.where(profile: profile, global_task: gt, status: :pending).count).to eq(1)
    end

    it "does not create a pending row when the cap has been reached" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :approved)
      create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :approved)
      described_class.new(awaiting).call
      expect(ProfileTask.where(profile: profile, global_task: gt, status: :pending)).to be_empty
    end
  end
```

- [ ] **Step 2: Run the spec to confirm it fails**

```bash
make shell
bundle exec rspec spec/services/tasks/approve_service_spec.rb -e "post-approval slot refresh"
```

Expected: failures (no pending row is auto-created today).

- [ ] **Step 3: Update `ApproveService`**

Edit `app/services/tasks/approve_service.rb`. Inside the `ActiveRecord::Base.transaction do` block, after the `ActivityLog.create!` line and before the `end` of the transaction, insert:

```ruby
        if @profile_task.global_task.present?
          Tasks::SlotRefresher.new(
            profile: @profile,
            global_task: @profile_task.global_task,
            date: @profile_task.assigned_date
          ).call
        end
```

The transaction block should now read:

```ruby
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

        if @profile_task.global_task.present?
          Tasks::SlotRefresher.new(
            profile: @profile,
            global_task: @profile_task.global_task,
            date: @profile_task.assigned_date
          ).call
        end
      end
```

- [ ] **Step 4: Run the spec to confirm it passes**

```bash
bundle exec rspec spec/services/tasks/approve_service_spec.rb -e "post-approval slot refresh"
```

Expected: green.

- [ ] **Step 5: Run the full approve-service spec**

```bash
bundle exec rspec spec/services/tasks/approve_service_spec.rb
```

Expected: all green.

- [ ] **Step 6: Commit**

```bash
exit
git add app/services/tasks/approve_service.rb spec/services/tasks/approve_service_spec.rb
git commit -m "feat(tasks): refresh slot after approve for repeatable missions"
```

---

## Task 7: Wire `SlotRefresher` into `RejectService`

**Files:**
- Modify: `app/services/tasks/reject_service.rb`
- Modify: `spec/services/tasks/reject_service_spec.rb`

- [ ] **Step 1: Add a failing spec**

Append to `spec/services/tasks/reject_service_spec.rb` inside the outer describe block:

```ruby
  describe "post-reject slot refresh on a repeatable mission" do
    let(:family) { create(:family) }
    let(:profile) { create(:profile, :child, family: family) }
    let(:gt) { create(:global_task, :daily, family: family, max_completions_per_period: 3) }
    let(:awaiting) { create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :awaiting_approval) }

    it "spawns a fresh pending row after a rejection so the kid can retry" do
      expect {
        described_class.new(awaiting).call
      }.to change {
        ProfileTask.where(profile: profile, global_task: gt, status: :pending).count
      }.from(0).to(1)
    end

    it "does not double-spawn if a pending row already exists" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :pending)
      expect {
        described_class.new(awaiting).call
      }.not_to change {
        ProfileTask.where(profile: profile, global_task: gt, status: :pending).count
      }
    end
  end
```

- [ ] **Step 2: Run the spec to confirm it fails**

```bash
make shell
bundle exec rspec spec/services/tasks/reject_service_spec.rb -e "post-reject slot refresh"
```

Expected: failure (no pending row created today).

- [ ] **Step 3: Update `RejectService`**

Edit `app/services/tasks/reject_service.rb`. Replace the `call` method body so the refresher fires after the status update:

```ruby
    def call
      Rails.logger.info("[Tasks::RejectService] start profile_task_id=#{@profile_task.id}")

      unless @profile_task.awaiting_approval?
        Rails.logger.info("[Tasks::RejectService] failure not awaiting_approval id=#{@profile_task.id}")
        return fail_with("Tarefa não está aguardando aprovação")
      end

      ActiveRecord::Base.transaction do
        @profile_task.update!(status: :rejected)

        if @profile_task.global_task.present?
          Tasks::SlotRefresher.new(
            profile: @profile_task.profile,
            global_task: @profile_task.global_task,
            date: @profile_task.assigned_date
          ).call
        end
      end

      Rails.logger.info("[Tasks::RejectService] success id=#{@profile_task.id}")
      ok(@profile_task)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Tasks::RejectService] exception id=#{@profile_task.id} error=#{e.message}")
      fail_with(e.message)
    end
```

- [ ] **Step 4: Run the spec to confirm it passes**

```bash
bundle exec rspec spec/services/tasks/reject_service_spec.rb -e "post-reject slot refresh"
```

Expected: green.

- [ ] **Step 5: Run the full reject-service spec and the existing rejection system flow**

```bash
bundle exec rspec spec/services/tasks/reject_service_spec.rb spec/system/mission_rejection_flow_spec.rb
```

Expected: all green.

- [ ] **Step 6: Commit**

```bash
exit
git add app/services/tasks/reject_service.rb spec/services/tasks/reject_service_spec.rb
git commit -m "feat(tasks): refresh slot after reject so kids can retry"
```

---

## Task 8: Parent form — toggle and numeric input

**Files:**
- Modify: `app/controllers/parent/global_tasks_controller.rb`
- Modify: `app/views/parent/global_tasks/_form.html.erb`
- Create: `app/assets/controllers/repeatable_controller.js`
- Create: `spec/system/parent/global_task_repeatable_form_spec.rb`

- [ ] **Step 1: Permit the new param in the controller**

Edit `app/controllers/parent/global_tasks_controller.rb`. Change the `global_task_params` method to permit `:max_completions_per_period`:

```ruby
  def global_task_params
    p = params.require(:global_task).permit(:title, :points, :category, :frequency, :active, :icon, :description,
                                             :day_of_month, :max_completions_per_period,
                                             days_of_week: [], assigned_profile_ids: [])
    p[:days_of_week]&.reject!(&:blank?)
    p[:assigned_profile_ids]&.reject!(&:blank?)
    p
  end
```

> Keep the rest of the method body unchanged — only add `:max_completions_per_period` to the `permit` call.

- [ ] **Step 2: Create the Stimulus controller**

Create `app/assets/controllers/repeatable_controller.js`:

```js
import { Controller } from "@hotwired/stimulus"

// Controls the "Repetível no período" toggle on the global_task form.
//
// - When the toggle is off, the numeric input is hidden, disabled, and forced to 1.
// - When the toggle is on, the numeric input is visible, enabled, and defaults to 3.
// - The frequency select is observed so the helper label tracks "dia / semana / mês".
// - When frequency changes to "once", the toggle is forced off and disabled.
export default class extends Controller {
  static targets = ["toggle", "input", "field", "helper"]
  static values = { defaultMax: { type: Number, default: 3 } }

  connect() {
    this.syncFromInput()
    this.syncFromFrequency()
    this.observeFrequency()
  }

  toggle() {
    if (this.toggleTarget.checked) {
      this.fieldTarget.classList.remove("hidden")
      this.inputTarget.disabled = false
      if (parseInt(this.inputTarget.value, 10) <= 1) {
        this.inputTarget.value = this.defaultMaxValue
      }
    } else {
      this.fieldTarget.classList.add("hidden")
      this.inputTarget.disabled = false // keep submittable
      this.inputTarget.value = 1
    }
  }

  syncFromInput() {
    const max = parseInt(this.inputTarget.value, 10) || 1
    if (max > 1) {
      this.toggleTarget.checked = true
      this.fieldTarget.classList.remove("hidden")
    } else {
      this.toggleTarget.checked = false
      this.fieldTarget.classList.add("hidden")
    }
  }

  observeFrequency() {
    const radios = document.querySelectorAll('input[name="global_task[frequency]"]')
    radios.forEach((radio) => radio.addEventListener("change", () => this.syncFromFrequency()))
  }

  syncFromFrequency() {
    const selected = document.querySelector('input[name="global_task[frequency]"]:checked')?.value || "daily"
    const labels = { daily: "dia", weekly: "semana", monthly: "mês", once: "" }
    if (this.hasHelperTarget) {
      this.helperTarget.textContent = `Quantas vezes por ${labels[selected] || "dia"}?`
    }
    if (selected === "once") {
      this.toggleTarget.checked = false
      this.toggleTarget.disabled = true
      this.fieldTarget.classList.add("hidden")
      this.inputTarget.value = 1
    } else {
      this.toggleTarget.disabled = false
    }
  }
}
```

> Stimulus controllers in this project are auto-registered by `stimulus-vite-helpers` from `app/assets/controllers/index.js` — no manual import required.

- [ ] **Step 3: Add the toggle and numeric input to the form**

Edit `app/views/parent/global_tasks/_form.html.erb`. Locate the `<%# Frequency %>` section. Immediately after the closing `<% end %>` of that `Ui::FormSection::Component` block, insert a new section:

```erb
    <%# Repetível no período %>
    <%
      current_max = (global_task.max_completions_per_period.presence || 1).to_i
      repeatable_initial = current_max > 1
    %>
    <%= render Ui::FormSection::Component.new(title: "Repetível no período") do %>
      <div data-controller="repeatable" data-repeatable-default-max-value="3">
        <label class="flex items-center gap-3 cursor-pointer">
          <input type="checkbox"
                 class="form-checkbox"
                 data-repeatable-target="toggle"
                 data-action="change->repeatable#toggle"
                 <%= "checked" if repeatable_initial %>
                 <%= "disabled" if global_task.frequency.to_s == "once" %>
                 aria-controls="repeatable_field"
                 aria-label="Permitir múltiplas execuções por período" />
          <span class="text-[13px] font-extrabold" style="color: var(--text);">
            Permitir mais de uma execução por período
          </span>
        </label>

        <fieldset id="repeatable_field"
                  data-repeatable-target="field"
                  class="flex flex-col gap-2 mt-3 <%= 'hidden' unless repeatable_initial %>">
          <%= f.label :max_completions_per_period,
                "Quantas vezes por dia?",
                class: "form-label",
                data: { repeatable_target: "helper" } %>
          <%= f.number_field :max_completions_per_period,
                value: current_max,
                min: 1,
                max: 20,
                class: "form-input",
                data: { repeatable_target: "input" } %>
          <p class="text-[11px] font-bold" style="color: var(--text-muted);">
            Cap de execuções por período. Por exemplo: escovar dentes 3x/dia.
          </p>
        </fieldset>
      </div>
    <% end %>
```

> Place this block **after** the Frequency section so the Stimulus controller can observe the existing `global_task[frequency]` radios that are already in the DOM.

- [ ] **Step 4: Write a failing system spec for the toggle UX**

Create `spec/system/parent/global_task_repeatable_form_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Repeatable mission form", type: :system, js: true do
  let(:family) { create(:family) }
  let!(:parent) { create(:profile, :parent, family: family) }

  before do
    sign_in_family(family) # use the project's auth helper
    visit_parent_with_pin(parent) # use the project's pin-pad helper
  end

  it "hides the cap input by default and reveals it when the toggle is enabled" do
    visit new_parent_global_task_path

    expect(page).to have_css('[data-repeatable-target="field"].hidden', visible: :all)

    find('[data-repeatable-target="toggle"]').click

    expect(page).not_to have_css('[data-repeatable-target="field"].hidden', visible: :all)
    expect(find('[data-repeatable-target="input"]').value).to eq("3")
  end

  it "disables the toggle and forces max=1 when frequency is set to 'once'" do
    visit new_parent_global_task_path
    choose "Única"
    expect(find('[data-repeatable-target="toggle"]')).to be_disabled
    expect(find('[data-repeatable-target="input"]').value).to eq("1")
  end

  it "persists max_completions_per_period when the form is submitted" do
    visit new_parent_global_task_path
    fill_in "Título da missão", with: "Escovar dentes"
    find('[data-repeatable-target="toggle"]').click
    fill_in "global_task[max_completions_per_period]", with: 3
    click_button "Salvar"

    expect(GlobalTask.find_by(title: "Escovar dentes").max_completions_per_period).to eq(3)
  end
end
```

> If the project does not yet expose `sign_in_family` / `visit_parent_with_pin` helpers, replace those two calls with the same login dance used in `spec/system/parent_management_flow_spec.rb`. The intent is to be authenticated as a parent profile when reaching `new_parent_global_task_path`.

- [ ] **Step 5: Run the system spec to confirm it fails**

```bash
make shell
bundle exec rspec spec/system/parent/global_task_repeatable_form_spec.rb
```

Expected: failures (controller, view, and Stimulus controller bits not yet wired together).

- [ ] **Step 6: Rebuild assets and re-run the system spec**

```bash
bin/vite build
bundle exec rspec spec/system/parent/global_task_repeatable_form_spec.rb
```

Expected: green.

- [ ] **Step 7: Run the full parent flow specs as a regression check**

```bash
bundle exec rspec spec/system/parent_flow_spec.rb spec/system/parent_management_flow_spec.rb
```

Expected: all green.

- [ ] **Step 8: Commit**

```bash
exit
git add app/controllers/parent/global_tasks_controller.rb \
        app/views/parent/global_tasks/_form.html.erb \
        app/assets/controllers/repeatable_controller.js \
        spec/system/parent/global_task_repeatable_form_spec.rb
git commit -m "feat(parent): add repeatable toggle to global task form"
```

---

## Task 9: Kid system test for repeatable mission flow

**Files:**
- Create: `spec/system/kid/repeatable_missions_spec.rb`

- [ ] **Step 1: Write the failing system spec**

Create `spec/system/kid/repeatable_missions_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Kid completes a repeatable mission", type: :system, js: true do
  let(:family) { create(:family, require_photo: false, auto_approve_threshold: nil) }
  let!(:parent) { create(:profile, :parent, family: family) }
  let!(:kid)    { create(:profile, :child, family: family) }
  let!(:gt) {
    create(:global_task, :daily, family: family, title: "Escovar dentes", points: 5, max_completions_per_period: 3)
  }

  before do
    Tasks::DailyResetService.new(family: family).call
    sign_in_family(family)
    visit_kid_with_pin(kid)
  end

  it "lets the kid submit twice and shows a fresh pending card both times, then no card on the third try" do
    expect(page).to have_text("Escovar dentes")

    # 1st completion
    within(find_card("Escovar dentes")) { click_button "Completar" }
    expect(page).to have_text("Aguardando aprovação", wait: 5).or have_no_text("Escovar dentes")

    # Parent approves to free the slot deterministically
    pt = ProfileTask.where(profile: kid, global_task: gt, status: :awaiting_approval).order(:created_at).last
    Tasks::ApproveService.new(pt).call

    # Kid sees the card again
    expect(page).to have_text("Escovar dentes", wait: 5)

    # 2nd completion
    within(find_card("Escovar dentes")) { click_button "Completar" }
    pt2 = ProfileTask.where(profile: kid, global_task: gt, status: :awaiting_approval).order(:created_at).last
    Tasks::ApproveService.new(pt2).call

    # Kid sees the card a third time
    expect(page).to have_text("Escovar dentes", wait: 5)

    # 3rd completion fills the cap
    within(find_card("Escovar dentes")) { click_button "Completar" }
    pt3 = ProfileTask.where(profile: kid, global_task: gt, status: :awaiting_approval).order(:created_at).last
    Tasks::ApproveService.new(pt3).call

    # Cap reached: the card stays gone
    expect(page).to have_no_text("Escovar dentes", wait: 5)
    expect(ProfileTask.where(profile: kid, global_task: gt, status: :pending)).to be_empty
    expect(ProfileTask.where(profile: kid, global_task: gt, status: :approved).count).to eq(3)
  end

  def find_card(title)
    find("[data-mission-title]", text: title).ancestor("[data-mission-card]")
  end
end
```

> Replace `data-mission-title` / `data-mission-card` with whatever selectors the existing kid mission card actually exposes — search `app/components/kid/` and `app/views/kid/missions/` for the current attributes. If no semantic data attributes exist yet, the spec author should pin them to the closest available selector (CSS class plus text match). The `find_card` helper is the only place this matters.

- [ ] **Step 2: Run the spec to confirm it fails or passes**

```bash
make shell
bundle exec rspec spec/system/kid/repeatable_missions_spec.rb
```

Expected: green if all earlier tasks were implemented correctly. If the selectors in `find_card` need adjusting, that is the only thing left to fix.

- [ ] **Step 3: Run the full kid system flow**

```bash
bundle exec rspec spec/system/kid_flow_spec.rb spec/system/full_mission_flow_spec.rb
```

Expected: all green.

- [ ] **Step 4: Commit**

```bash
exit
git add spec/system/kid/repeatable_missions_spec.rb
git commit -m "test(system): kid completes repeatable mission until cap reached"
```

---

## Task 10: Final regression sweep

- [ ] **Step 1: Run the full test suite, lint, and security checks**

```bash
make rspec
make lint
make brakeman
```

Expected: all green.

- [ ] **Step 2: Hand-verify in browser**

```bash
make dev-detached
```

In the parent UI:

1. Create a new mission "Escovar dentes", toggle "Repetível no período", set 3, save.
2. Switch to the kid profile, see the card, complete it once.
3. As parent, approve. Confirm card returns on the kid side.
4. Repeat until 3 approvals; confirm card disappears for the day.
5. Edit the mission, set frequency to "Única", confirm the toggle is disabled and the value resets to 1.

If anything looks off, debug before claiming done.

- [ ] **Step 3: Final commit if any minor adjustments were needed**

```bash
git status
# stage and commit only if there are changes
```

---

## Notes for the executor

- `make rspec`, `make lint`, `make brakeman`, `make migrate`, `make shell`, `make c` all run inside the `web` Docker container. Never run `bundle exec` from the host — the database host is not reachable.
- All commits should be small, single-purpose, and follow the existing message style (see `git log --oneline | head -20`).
- Custom missions (`source: :custom`) have no `global_task` and are therefore unaffected by this change. The refresher early-returns in that case.
- Auto-approve threshold (`Family#auto_approve_threshold`) still works — when triggered, `ApproveService` runs inside the same transaction as the complete step and its own refresher call confirms the post-approval slot state. Idempotent end result.
- Concurrency: `SlotRefresher` uses `FOR UPDATE` on the period scope, so two simultaneous completes from the same kid converge correctly. The `find_or_create_by` style is intentionally avoided.
- Backfill: existing rows get `max_completions_per_period = 1` from the migration default, preserving today's single-shot behaviour exactly.

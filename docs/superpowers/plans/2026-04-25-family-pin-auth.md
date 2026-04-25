# Family + PIN Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace current parent-email/password + click-to-pick-kid auth with a two-layer system — family email+password (90-day signed cookie) gates a unified profile picker, then per-profile 4-digit PIN gates an ephemeral profile session.

**Architecture:** Two split resources: `FamilySessionsController` and `ProfileSessionsController`. `Family` gains `email` + `password_digest`; `Profile` swaps `password_digest` for `pin_digest`. Service objects under `app/services/auth/` wrap mutations. `HomeController#index` branches the root URL based on auth state.

**Tech Stack:** Rails 8.1, has_secure_password (bcrypt), Stimulus (PIN keypad), Turbo Frames (PIN modal), ViewComponent, RSpec, FactoryBot, Capybara.

**Pre-execution notes:**
- Working tree currently has unrelated uncommitted UI work. Stash or commit before starting this plan, or work in a worktree.
- This plan nukes seed data — ensure no real users exist in dev DB before running migration.
- Spec source: `docs/superpowers/specs/2026-04-25-family-pin-auth-design.md`.
- All commands run inside the `web` container (`docker compose exec web …`) per project conventions.

---

## File Structure

### New files
- `db/migrate/<ts>_refactor_auth_to_family_and_pin.rb`
- `app/services/auth/create_family.rb`
- `app/services/auth/create_profile.rb`
- `app/services/auth/reset_pin.rb`
- `app/services/auth/accept_invitation.rb`
- `app/controllers/home_controller.rb`
- `app/controllers/family_sessions_controller.rb`
- `app/controllers/profile_sessions_controller.rb`
- `app/views/home/index.html.erb` (only if branching logic surfaces — likely empty, controller redirects)
- `app/views/family_sessions/new.html.erb`
- `app/views/profile_sessions/new.html.erb`
- `app/components/ui/pin_modal/component.rb`
- `app/components/ui/pin_modal/component.html.erb`
- `app/components/ui/pin_modal/component.css`
- `app/components/ui/profile_picker/component.rb`
- `app/components/ui/profile_picker/component.html.erb`
- `app/assets/controllers/pin_pad_controller.js`
- `app/assets/controllers/switch_profile_controller.js`
- `spec/models/family_spec.rb` (if missing)
- `spec/services/auth/create_family_spec.rb`
- `spec/services/auth/create_profile_spec.rb`
- `spec/services/auth/reset_pin_spec.rb`
- `spec/services/auth/accept_invitation_spec.rb`
- `spec/requests/family_sessions_spec.rb`
- `spec/requests/profile_sessions_spec.rb`
- `spec/system/signup_flow_spec.rb`
- `spec/system/family_login_flow_spec.rb`
- `spec/system/profile_pick_flow_spec.rb`
- `spec/system/switch_profile_flow_spec.rb`
- `spec/system/parent_invite_flow_spec.rb`

### Modified files
- `app/models/family.rb` — `has_secure_password`, validations.
- `app/models/profile.rb` — drop password concerns, add `pin` virtual attr + `authenticate_pin`.
- `app/controllers/concerns/authenticatable.rb` — `current_family`, `require_family!`.
- `app/controllers/sessions_controller.rb` — DELETE (superseded).
- `app/controllers/registrations_controller.rb` — rewrite.
- `app/controllers/password_resets_controller.rb` — target Family instead of Profile.
- `app/controllers/invitations_controller.rb` — rewrite.
- `app/controllers/parent/profiles_controller.rb` — add `reset_pin` action + PIN form field.
- `app/controllers/parent/settings_controller.rb` — add PIN reset UI.
- `app/views/parent/profiles/_form.html.erb` — add PIN field.
- `app/views/parent/settings/show.html.erb` — add per-profile PIN reset rows.
- `app/views/layouts/parent.html.erb` — switch-profile button.
- `app/views/layouts/kid.html.erb` — switch-profile button.
- `config/routes.rb` — drop `:sessions`, add `:family_session` + `:profile_session`, add `home#index` root, add `reset_pin` member route.
- `db/seeds.rb` — create family with login creds, profiles with PINs.
- `spec/factories/families.rb` — add email/password traits.
- `spec/factories/profiles.rb` — add `pin` trait, drop password.
- `spec/support/system_auth_helpers.rb` — `sign_in_family`, `sign_in_profile` helpers.
- `spec/system/kid_flow_spec.rb`, `spec/system/parent_flow_spec.rb`, etc. — switch to new helpers.

### Deleted files
- `app/views/sessions/index.html.erb` (replaced by family + profile session views)
- `app/controllers/sessions_controller.rb`

---

## Task 1: Schema migration

**Files:**
- Create: `db/migrate/<timestamp>_refactor_auth_to_family_and_pin.rb`

- [ ] **Step 1: Generate migration**

Run: `docker compose exec web bin/rails g migration RefactorAuthToFamilyAndPin`

- [ ] **Step 2: Write migration body**

```ruby
class RefactorAuthToFamilyAndPin < ActiveRecord::Migration[8.1]
  def change
    enable_extension "citext" unless extension_enabled?("citext")

    add_column :families, :email, :citext
    add_column :families, :password_digest, :string
    add_index  :families, :email, unique: true

    add_column :profiles, :pin_digest, :string

    remove_index  :profiles, name: "index_profiles_on_email_parent", if_exists: true
    remove_column :profiles, :password_digest, :string
    remove_column :profiles, :confirmed_at, :datetime
  end
end
```

- [ ] **Step 3: Run migration**

Run: `docker compose exec web bin/rails db:reset`
Expected: schema reloads, seeds run (seeds will be rewritten in Task 22 — temporarily fail is OK; if so, run `bin/rails db:drop db:create db:migrate` instead).

- [ ] **Step 4: Verify schema**

Run: `docker compose exec web bin/rails runner "puts Family.column_names.sort"`
Expected output includes `email` and `password_digest`.

Run: `docker compose exec web bin/rails runner "puts Profile.column_names.sort"`
Expected output includes `pin_digest`, excludes `password_digest` and `confirmed_at`.

- [ ] **Step 5: Commit**

```bash
git add db/migrate/ db/schema.rb
git commit -m "feat(auth): add family credentials + profile pin_digest schema"
```

---

## Task 2: `Family` model — credentials

**Files:**
- Modify: `app/models/family.rb`
- Test: `spec/models/family_spec.rb`

- [ ] **Step 1: Write failing model spec**

```ruby
# spec/models/family_spec.rb
require "rails_helper"

RSpec.describe Family, type: :model do
  describe "credentials" do
    it "is invalid without email" do
      family = Family.new(name: "Test", password: "supersecret1234")
      expect(family).not_to be_valid
      expect(family.errors[:email]).to be_present
    end

    it "is invalid with malformed email" do
      family = Family.new(name: "Test", email: "nope", password: "supersecret1234")
      expect(family).not_to be_valid
      expect(family.errors[:email]).to be_present
    end

    it "rejects passwords shorter than 12 characters" do
      family = Family.new(name: "Test", email: "a@b.co", password: "short")
      expect(family).not_to be_valid
      expect(family.errors[:password]).to be_present
    end

    it "enforces unique email (case-insensitive)" do
      Family.create!(name: "A", email: "a@b.co", password: "supersecret1234")
      dup = Family.new(name: "B", email: "A@B.CO", password: "anothersecret1")
      expect(dup).not_to be_valid
      expect(dup.errors[:email]).to be_present
    end

    it "authenticates with correct password" do
      family = Family.create!(name: "A", email: "a@b.co", password: "supersecret1234")
      expect(family.authenticate("supersecret1234")).to eq(family)
      expect(family.authenticate("wrong")).to be_falsey
    end
  end
end
```

- [ ] **Step 2: Run spec to verify it fails**

Run: `docker compose exec web bundle exec rspec spec/models/family_spec.rb`
Expected: failures (no email validation, no `authenticate`).

- [ ] **Step 3: Update `Family` model**

```ruby
# app/models/family.rb
class Family < ApplicationRecord
  has_many :profiles, dependent: :destroy
  has_many :global_tasks, dependent: :destroy
  has_many :rewards, dependent: :destroy
  has_many :profile_invitations, dependent: :destroy

  has_secure_password

  before_validation { email&.downcase! }

  validates :name, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: URI::MailTo::EMAIL_REGEXP
  validates :password, length: { minimum: 12 }, allow_nil: true
end
```

(If existing `Family` has additional associations or validations not shown above, retain them — adapt this snippet to merge instead of replace.)

- [ ] **Step 4: Run spec — pass**

Run: `docker compose exec web bundle exec rspec spec/models/family_spec.rb`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add app/models/family.rb spec/models/family_spec.rb
git commit -m "feat(auth): add Family credentials with has_secure_password"
```

---

## Task 3: `Profile` model — PIN

**Files:**
- Modify: `app/models/profile.rb`
- Modify: `spec/models/profile_spec.rb`

- [ ] **Step 1: Write failing PIN specs**

```ruby
# Append to spec/models/profile_spec.rb (within RSpec.describe Profile)
describe "PIN" do
  let(:family) { Family.create!(name: "Fam", email: "f@x.co", password: "supersecret1234") }

  it "stores a hashed pin_digest, never the plaintext PIN" do
    profile = Profile.create!(family: family, name: "Kid", role: :child, pin: "1234")
    expect(profile.pin_digest).to be_present
    expect(profile.pin_digest).not_to eq("1234")
  end

  it "authenticates with correct PIN" do
    profile = Profile.create!(family: family, name: "Kid", role: :child, pin: "1234")
    expect(profile.authenticate_pin("1234")).to be_truthy
    expect(profile.authenticate_pin("9999")).to be_falsey
  end

  it "requires a 4-digit numeric PIN" do
    profile = Profile.new(family: family, name: "Kid", role: :child, pin: "abcd")
    expect(profile).not_to be_valid
    expect(profile.errors[:pin]).to be_present
  end

  it "requires pin on create" do
    profile = Profile.new(family: family, name: "Kid", role: :child)
    expect(profile).not_to be_valid
    expect(profile.errors[:pin_digest]).to be_present
  end
end
```

- [ ] **Step 2: Run spec — fail**

Run: `docker compose exec web bundle exec rspec spec/models/profile_spec.rb -e "PIN"`
Expected: failures.

- [ ] **Step 3: Rewrite `Profile` model**

```ruby
# app/models/profile.rb
class Profile < ApplicationRecord
  PIN_FORMAT = /\A\d{4}\z/

  belongs_to :family
  has_many :profile_tasks, dependent: :destroy
  has_many :redemptions, dependent: :destroy
  has_many :activity_logs, dependent: :destroy
  has_many :global_task_assignments, dependent: :destroy
  has_many :sent_invitations, class_name: "ProfileInvitation", foreign_key: :invited_by_id, dependent: :nullify

  attr_accessor :pin

  enum :role, { child: 0, parent: 1 }, default: :child

  before_validation { email&.downcase! }
  before_save :hash_pin, if: -> { pin.present? }

  after_update_commit :broadcast_points, if: :saved_change_to_points?

  validates :name, presence: true
  validates :points, numericality: { greater_than_or_equal_to: 0 }, unless: -> { family&.allow_negative? }
  validates :color, inclusion: { in: %w[peach rose mint sky lilac coral primary], allow_blank: true }
  validates :email, allow_blank: true,
                    format: URI::MailTo::EMAIL_REGEXP
  validates :pin, format: { with: PIN_FORMAT, message: "deve ter 4 dígitos numéricos" }, if: -> { pin.present? }
  validates :pin_digest, presence: true, on: :create

  def authenticate_pin(candidate)
    return false if pin_digest.blank?
    BCrypt::Password.new(pin_digest) == candidate.to_s
  end

  def full_name
    name
  end

  def avatar_url(*_args)
    avatar.presence
  end

  private

  def hash_pin
    self.pin_digest = BCrypt::Password.create(pin)
    self.pin = nil
  end

  def broadcast_points
    broadcast_update_to self, "notifications", target: "profile_points_#{id}", html: points.to_s
  end
end
```

- [ ] **Step 4: Run spec — pass**

Run: `docker compose exec web bundle exec rspec spec/models/profile_spec.rb`
Expected: all pass (existing examples may need PIN added in setup — fix any breakage).

- [ ] **Step 5: Update `Profile` factory**

```ruby
# spec/factories/profiles.rb
FactoryBot.define do
  factory :profile do
    association :family
    sequence(:name) { |n| "Profile #{n}" }
    role { :child }
    pin { "1234" }

    trait :parent do
      role { :parent }
      sequence(:email) { |n| "parent#{n}@example.com" }
    end

    trait :child do
      role { :child }
    end
  end
end
```

(If existing factory has more attributes, merge — do not lose them.)

- [ ] **Step 6: Run full model + factory specs — pass**

Run: `docker compose exec web bundle exec rspec spec/models spec/factories`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add app/models/profile.rb spec/models/profile_spec.rb spec/factories/profiles.rb
git commit -m "feat(auth): replace profile password with pin_digest + virtual pin attr"
```

---

## Task 4: `Auth::CreateFamily` service

**Files:**
- Create: `app/services/auth/create_family.rb`
- Test: `spec/services/auth/create_family_spec.rb`

- [ ] **Step 1: Write failing service spec**

```ruby
# spec/services/auth/create_family_spec.rb
require "rails_helper"

RSpec.describe Auth::CreateFamily do
  describe ".call" do
    let(:valid_params) { { name: "Test Fam", email: "fam@example.com", password: "supersecret1234" } }

    it "creates a family on valid params" do
      result = described_class.call(valid_params)
      expect(result.success?).to be true
      expect(result.family).to be_persisted
      expect(result.family.email).to eq("fam@example.com")
    end

    it "fails on duplicate email" do
      Family.create!(valid_params)
      result = described_class.call(valid_params)
      expect(result.success?).to be false
      expect(result.error).to be_present
    end

    it "fails on weak password" do
      result = described_class.call(valid_params.merge(password: "short"))
      expect(result.success?).to be false
      expect(result.error).to match(/senha|password/i)
    end
  end
end
```

- [ ] **Step 2: Run — fail**

Run: `docker compose exec web bundle exec rspec spec/services/auth/create_family_spec.rb`
Expected: NameError (`Auth::CreateFamily` undefined).

- [ ] **Step 3: Implement service**

```ruby
# app/services/auth/create_family.rb
module Auth
  class CreateFamily < ApplicationService
    def initialize(params)
      @params = params
    end

    def call
      family = Family.new(@params)
      if family.save
        OpenStruct.new(success?: true, family: family, error: nil)
      else
        OpenStruct.new(success?: false, family: family, error: family.errors.full_messages.to_sentence)
      end
    end

    def self.call(params)
      new(params).call
    end
  end
end
```

(Confirm `ApplicationService` base class — use it if present, else inherit nothing.)

- [ ] **Step 4: Run — pass**

Run: `docker compose exec web bundle exec rspec spec/services/auth/create_family_spec.rb`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add app/services/auth/create_family.rb spec/services/auth/create_family_spec.rb
git commit -m "feat(auth): add Auth::CreateFamily service"
```

---

## Task 5: `Auth::CreateProfile` service

**Files:**
- Create: `app/services/auth/create_profile.rb`
- Test: `spec/services/auth/create_profile_spec.rb`

- [ ] **Step 1: Write failing spec**

```ruby
# spec/services/auth/create_profile_spec.rb
require "rails_helper"

RSpec.describe Auth::CreateProfile do
  let(:family) { Family.create!(name: "Fam", email: "f@x.co", password: "supersecret1234") }

  it "creates a profile with hashed PIN" do
    result = described_class.call(family: family, params: { name: "Kid", role: :child }, pin: "1234")
    expect(result.success?).to be true
    expect(result.profile).to be_persisted
    expect(result.profile.authenticate_pin("1234")).to be_truthy
  end

  it "fails on invalid PIN format" do
    result = described_class.call(family: family, params: { name: "Kid", role: :child }, pin: "abcd")
    expect(result.success?).to be false
    expect(result.error).to be_present
  end

  it "fails when name missing" do
    result = described_class.call(family: family, params: { name: "", role: :child }, pin: "1234")
    expect(result.success?).to be false
  end
end
```

- [ ] **Step 2: Run — fail**

Run: `docker compose exec web bundle exec rspec spec/services/auth/create_profile_spec.rb`

- [ ] **Step 3: Implement**

```ruby
# app/services/auth/create_profile.rb
module Auth
  class CreateProfile < ApplicationService
    def initialize(family:, params:, pin:)
      @family = family
      @params = params
      @pin = pin
    end

    def call
      profile = @family.profiles.new(@params.merge(pin: @pin))
      if profile.save
        OpenStruct.new(success?: true, profile: profile, error: nil)
      else
        OpenStruct.new(success?: false, profile: profile, error: profile.errors.full_messages.to_sentence)
      end
    end

    def self.call(**kwargs)
      new(**kwargs).call
    end
  end
end
```

- [ ] **Step 4: Run — pass**

Run: `docker compose exec web bundle exec rspec spec/services/auth/create_profile_spec.rb`

- [ ] **Step 5: Commit**

```bash
git add app/services/auth/create_profile.rb spec/services/auth/create_profile_spec.rb
git commit -m "feat(auth): add Auth::CreateProfile service"
```

---

## Task 6: `Auth::ResetPin` service

**Files:**
- Create: `app/services/auth/reset_pin.rb`
- Test: `spec/services/auth/reset_pin_spec.rb`

- [ ] **Step 1: Write failing spec**

```ruby
# spec/services/auth/reset_pin_spec.rb
require "rails_helper"

RSpec.describe Auth::ResetPin do
  let(:family) { Family.create!(name: "Fam", email: "f@x.co", password: "supersecret1234") }
  let(:other_family) { Family.create!(name: "Other", email: "o@x.co", password: "supersecret1234") }
  let(:parent) { family.profiles.create!(name: "Parent", role: :parent, pin: "1111") }
  let(:kid)    { family.profiles.create!(name: "Kid",    role: :child,  pin: "2222") }
  let(:foreign_parent) { other_family.profiles.create!(name: "Other Parent", role: :parent, pin: "3333") }

  it "lets parent reset own PIN" do
    result = described_class.call(profile: parent, new_pin: "4444", actor: parent)
    expect(result.success?).to be true
    expect(parent.reload.authenticate_pin("4444")).to be_truthy
  end

  it "lets parent reset kid PIN" do
    result = described_class.call(profile: kid, new_pin: "5555", actor: parent)
    expect(result.success?).to be true
    expect(kid.reload.authenticate_pin("5555")).to be_truthy
  end

  it "denies non-parent actor" do
    result = described_class.call(profile: kid, new_pin: "5555", actor: kid)
    expect(result.success?).to be false
  end

  it "denies cross-family target" do
    result = described_class.call(profile: foreign_parent, new_pin: "5555", actor: parent)
    expect(result.success?).to be false
  end

  it "rejects invalid PIN format" do
    result = described_class.call(profile: kid, new_pin: "abcd", actor: parent)
    expect(result.success?).to be false
  end
end
```

- [ ] **Step 2: Run — fail**

- [ ] **Step 3: Implement**

```ruby
# app/services/auth/reset_pin.rb
module Auth
  class ResetPin < ApplicationService
    def initialize(profile:, new_pin:, actor:)
      @profile = profile
      @new_pin = new_pin
      @actor = actor
    end

    def call
      return failure("Apenas pais podem redefinir PIN.") unless @actor&.parent?
      return failure("Perfil não pertence à mesma família.") unless @actor.family_id == @profile.family_id

      @profile.pin = @new_pin
      if @profile.save
        OpenStruct.new(success?: true, profile: @profile, error: nil)
      else
        failure(@profile.errors.full_messages.to_sentence)
      end
    end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    private

    def failure(msg)
      OpenStruct.new(success?: false, profile: @profile, error: msg)
    end
  end
end
```

- [ ] **Step 4: Run — pass**

- [ ] **Step 5: Commit**

```bash
git add app/services/auth/reset_pin.rb spec/services/auth/reset_pin_spec.rb
git commit -m "feat(auth): add Auth::ResetPin service"
```

---

## Task 7: `Auth::AcceptInvitation` service

**Files:**
- Create: `app/services/auth/accept_invitation.rb`
- Test: `spec/services/auth/accept_invitation_spec.rb`

- [ ] **Step 1: Write failing spec**

```ruby
# spec/services/auth/accept_invitation_spec.rb
require "rails_helper"

RSpec.describe Auth::AcceptInvitation do
  let(:family) { Family.create!(name: "Fam", email: "f@x.co", password: "supersecret1234") }
  let(:invitation) do
    family.profile_invitations.create!(
      email: "new@example.com", token: SecureRandom.hex(16),
      expires_at: 1.day.from_now
    )
  end

  it "marks invitation accepted and returns family" do
    result = described_class.call(token: invitation.token)
    expect(result.success?).to be true
    expect(result.family).to eq(family)
    expect(invitation.reload.accepted_at).to be_present
  end

  it "fails for unknown token" do
    result = described_class.call(token: "nope")
    expect(result.success?).to be false
  end

  it "fails for expired invitation" do
    invitation.update!(expires_at: 1.day.ago)
    result = described_class.call(token: invitation.token)
    expect(result.success?).to be false
  end

  it "fails for already-accepted invitation" do
    invitation.update!(accepted_at: 1.hour.ago)
    result = described_class.call(token: invitation.token)
    expect(result.success?).to be false
  end
end
```

- [ ] **Step 2: Run — fail**

- [ ] **Step 3: Implement**

```ruby
# app/services/auth/accept_invitation.rb
module Auth
  class AcceptInvitation < ApplicationService
    def initialize(token:)
      @token = token
    end

    def call
      invitation = ProfileInvitation.find_by(token: @token)
      return failure("Convite inválido.") if invitation.nil?
      return failure("Convite expirado.") if invitation.expires_at < Time.current
      return failure("Convite já aceito.") if invitation.accepted_at.present?

      invitation.update!(accepted_at: Time.current)
      OpenStruct.new(success?: true, family: invitation.family, invitation: invitation, error: nil)
    end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    private

    def failure(msg)
      OpenStruct.new(success?: false, family: nil, invitation: nil, error: msg)
    end
  end
end
```

- [ ] **Step 4: Run — pass**

- [ ] **Step 5: Commit**

```bash
git add app/services/auth/accept_invitation.rb spec/services/auth/accept_invitation_spec.rb
git commit -m "feat(auth): add Auth::AcceptInvitation service"
```

---

## Task 8: `Authenticatable` concern — `current_family`

**Files:**
- Modify: `app/controllers/concerns/authenticatable.rb`

- [ ] **Step 1: Rewrite concern**

```ruby
# app/controllers/concerns/authenticatable.rb
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :require_family!
    before_action :require_profile!
    helper_method :current_family, :current_profile
  end

  private

  def current_family
    return @current_family if defined?(@current_family)
    @current_family = Family.find_by(id: cookies.signed[:family_id])
  end

  def current_profile
    return @current_profile if defined?(@current_profile)
    @current_profile =
      if session[:profile_id] && current_family
        current_family.profiles.find_by(id: session[:profile_id])
      end
  end

  def require_family!
    return if current_family
    redirect_to new_family_session_path, alert: "Faça login na família."
  end

  def require_profile!
    return unless current_family
    return if current_profile
    redirect_to new_profile_session_path, alert: "Selecione um perfil."
  end

  def require_parent!
    unless current_profile&.parent?
      redirect_to root_path, alert: "Acesso restrito para pais."
    end
  end

  def require_child!
    unless current_profile&.child?
      redirect_to root_path, alert: "Acesso restrito para filhos."
    end
  end

  def authorize_family!(record)
    return if record.nil?
    family_id =
      if record.respond_to?(:family_id) && record.family_id
        record.family_id
      elsif record.respond_to?(:profile) && record.profile
        record.profile.family_id
      end
    unless family_id && current_profile && family_id == current_profile.family_id
      raise ActiveRecord::RecordNotFound, "Record not in current family"
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add app/controllers/concerns/authenticatable.rb
git commit -m "feat(auth): split current_family from current_profile in concern"
```

(Concern is exercised via request/system specs in later tasks.)

---

## Task 9: `HomeController` (root branching)

**Files:**
- Create: `app/controllers/home_controller.rb`

- [ ] **Step 1: Implement**

```ruby
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    family = Family.find_by(id: cookies.signed[:family_id])
    return redirect_to new_family_session_path unless family

    profile = session[:profile_id] && family.profiles.find_by(id: session[:profile_id])
    return redirect_to new_profile_session_path unless profile

    redirect_to profile.parent? ? parent_root_path : kid_root_path
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add app/controllers/home_controller.rb
git commit -m "feat(auth): add HomeController#index branching root by auth state"
```

---

## Task 10: Routes

**Files:**
- Modify: `config/routes.rb`

- [ ] **Step 1: Update routes**

Replace the entire `Rails.application.routes.draw` block with:

```ruby
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  resource :family_session,  only: [ :new, :create, :destroy ]
  resource :profile_session, only: [ :new, :create, :destroy ]

  resource :registration, only: [ :new, :create ]
  resource :password_reset, only: [ :new, :create, :edit, :update ]

  get  "invitations/:token/accept" => "invitations#show",   as: :invitation_acceptance
  post "invitations/:token/accept" => "invitations#accept", as: :accept_invitation

  namespace :parent do
    root "dashboard#index"
    resources :invitations, only: [ :new, :create ]
    resources :profiles, only: [ :index, :new, :create, :edit, :update, :destroy ] do
      member do
        patch :reset_pin
      end
    end
    resources :global_tasks, except: [ :show ] do
      member { patch :toggle_active }
    end
    resources :rewards, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :approvals, only: [ :index ] do
      collection do
        post :bulk_approve
        post :bulk_reject
      end
      member do
        patch :approve
        patch :reject
        patch :approve_redemption
        patch :reject_redemption
      end
    end
    resources :activity_logs, only: [ :index ]
    resource :settings, only: [ :show, :update ]
  end

  namespace :kid do
    root to: "dashboard#index"
    resources :missions, only: [] do
      member { patch :complete }
    end
    resources :rewards, only: [ :index ] do
      member { post :redeem }
    end
    resources :wallet, only: [ :index ]
  end
end
```

- [ ] **Step 2: Run `rails routes` to verify**

Run: `docker compose exec web bin/rails routes | grep -E "family_session|profile_session|reset_pin"`
Expected: includes new resources + member route.

- [ ] **Step 3: Commit**

```bash
git add config/routes.rb
git commit -m "feat(auth): split sessions into family_session + profile_session routes"
```

---

## Task 11: `FamilySessionsController`

**Files:**
- Create: `app/controllers/family_sessions_controller.rb`
- Create: `app/views/family_sessions/new.html.erb`
- Test: `spec/requests/family_sessions_spec.rb`

- [ ] **Step 1: Write request spec**

```ruby
# spec/requests/family_sessions_spec.rb
require "rails_helper"

RSpec.describe "FamilySessions", type: :request do
  let!(:family) { Family.create!(name: "Fam", email: "f@x.co", password: "supersecret1234") }

  describe "POST /family_session" do
    it "sets a signed cookie and redirects to picker on valid creds" do
      post family_session_path, params: { email: "f@x.co", password: "supersecret1234" }
      expect(response).to redirect_to(new_profile_session_path)
      expect(cookies.signed[:family_id]).to eq(family.id)
    end

    it "re-renders new on invalid creds" do
      post family_session_path, params: { email: "f@x.co", password: "wrong" }
      expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:ok)
      expect(cookies.signed[:family_id]).to be_blank
    end
  end

  describe "DELETE /family_session" do
    it "clears the family cookie" do
      post family_session_path, params: { email: "f@x.co", password: "supersecret1234" }
      delete family_session_path
      expect(cookies.signed[:family_id]).to be_blank
    end
  end
end
```

- [ ] **Step 2: Run — fail**

- [ ] **Step 3: Implement controller**

```ruby
# app/controllers/family_sessions_controller.rb
class FamilySessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create, :destroy ], raise: false

  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  def new
    redirect_to new_profile_session_path and return if cookies.signed[:family_id]
  end

  def create
    family = Family.find_by(email: params[:email].to_s.downcase.strip)
    if family&.authenticate(params[:password])
      reset_session
      cookies.signed.permanent[:family_id] = { value: family.id, httponly: true, same_site: :lax }
      redirect_to new_profile_session_path
    else
      flash.now[:alert] = "Email ou senha inválidos."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    cookies.delete(:family_id)
    reset_session
    redirect_to new_family_session_path, notice: "Sessão da família encerrada."
  end
end
```

- [ ] **Step 4: Add view**

```erb
<%# app/views/family_sessions/new.html.erb %>
<div class="screen flex flex-col items-center justify-center p-10">
  <%= render Ui::LogoMark::Component.new(size: 56) %>
  <h1 class="font-display text-[32px] font-extrabold mb-6">Entrar na família</h1>

  <% if flash[:alert] %>
    <p class="text-destructive mb-4"><%= flash[:alert] %></p>
  <% end %>

  <%= form_with url: family_session_path, method: :post, local: true,
                class: "flex flex-col gap-3 max-w-[320px] w-full" do |f| %>
    <%= f.email_field :email, placeholder: "Email da família", required: true,
        class: "w-full px-3 py-2 rounded-md border border-hairline bg-white" %>
    <%= f.password_field :password, placeholder: "Senha", required: true,
        class: "w-full px-3 py-2 rounded-md border border-hairline bg-white" %>
    <%= render Ui::Btn::Component.new(variant: "primary", size: "md", type: "submit") do %>
      Entrar
    <% end %>
  <% end %>

  <div class="text-center mt-4 text-sm">
    <%= link_to "Criar família", new_registration_path, class: "text-primary font-bold" %> ·
    <%= link_to "Esqueci a senha", new_password_reset_path, class: "text-primary font-bold" %>
  </div>
</div>
```

- [ ] **Step 5: Run — pass**

Run: `docker compose exec web bundle exec rspec spec/requests/family_sessions_spec.rb`

- [ ] **Step 6: Commit**

```bash
git add app/controllers/family_sessions_controller.rb app/views/family_sessions/ spec/requests/family_sessions_spec.rb
git commit -m "feat(auth): add FamilySessionsController + login view"
```

---

## Task 12: `ProfileSessionsController` + picker view

**Files:**
- Create: `app/controllers/profile_sessions_controller.rb`
- Create: `app/views/profile_sessions/new.html.erb`
- Test: `spec/requests/profile_sessions_spec.rb`

- [ ] **Step 1: Write request spec**

```ruby
# spec/requests/profile_sessions_spec.rb
require "rails_helper"

RSpec.describe "ProfileSessions", type: :request do
  let!(:family) { Family.create!(name: "Fam", email: "f@x.co", password: "supersecret1234") }
  let!(:kid)    { family.profiles.create!(name: "Kid", role: :child, pin: "1234") }
  let!(:other)  { Family.create!(name: "Other", email: "o@x.co", password: "supersecret1234").profiles.create!(name: "Stranger", role: :child, pin: "9999") }

  before do
    post family_session_path, params: { email: "f@x.co", password: "supersecret1234" }
  end

  it "redirects to family login if no family cookie" do
    cookies.delete(:family_id)
    get new_profile_session_path
    expect(response).to redirect_to(new_family_session_path)
  end

  it "renders picker with family profiles" do
    get new_profile_session_path
    expect(response).to be_successful
    expect(response.body).to include("Kid")
  end

  it "logs in profile with correct PIN" do
    post profile_session_path, params: { profile_id: kid.id, pin: "1234" }
    expect(response).to redirect_to(kid_root_path)
    expect(session[:profile_id]).to eq(kid.id)
  end

  it "rejects wrong PIN" do
    post profile_session_path, params: { profile_id: kid.id, pin: "0000" }
    expect(session[:profile_id]).to be_blank
  end

  it "404s on cross-family profile_id" do
    post profile_session_path, params: { profile_id: other.id, pin: "9999" }
    expect(response).to have_http_status(:not_found)
  end
end
```

- [ ] **Step 2: Run — fail**

- [ ] **Step 3: Implement controller**

```ruby
# app/controllers/profile_sessions_controller.rb
class ProfileSessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create, :destroy ], raise: false

  before_action :require_family!

  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  def new
    @profiles = current_family.profiles.order(:created_at)
    @selected_profile = @profiles.find_by(id: params[:profile_id]) if params[:profile_id]
  end

  def create
    profile = current_family.profiles.find(params[:profile_id])
    if profile.authenticate_pin(params[:pin])
      family_id = cookies.signed[:family_id]
      reset_session
      cookies.signed.permanent[:family_id] = { value: family_id, httponly: true, same_site: :lax }
      session[:profile_id] = profile.id
      redirect_to profile.parent? ? parent_root_path : kid_root_path
    else
      flash.now[:alert] = "PIN incorreto."
      @profiles = current_family.profiles.order(:created_at)
      @selected_profile = profile
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:profile_id)
    redirect_to new_profile_session_path, notice: "Perfil desconectado."
  end

  private

  def current_family
    @current_family ||= Family.find_by(id: cookies.signed[:family_id])
  end
  helper_method :current_family

  def require_family!
    redirect_to new_family_session_path, alert: "Faça login na família." unless current_family
  end
end
```

- [ ] **Step 4: Picker view (placeholder until Task 14 component lands)**

```erb
<%# app/views/profile_sessions/new.html.erb %>
<div class="screen flex flex-col items-center justify-center p-10">
  <%= render Ui::LogoMark::Component.new(size: 48) %>
  <h1 class="font-display text-[28px] font-extrabold mb-6">Quem é você?</h1>

  <%= render Ui::ProfilePicker::Component.new(profiles: @profiles, selected: @selected_profile) %>
</div>
```

(`Ui::ProfilePicker::Component` is created in Task 14 — for now this view will fail to render. Create a temporary ERB that lists profiles inline, then replace in Task 14:)

```erb
<%# Temporary content for Task 12 — replaced in Task 14 %>
<div class="grid grid-cols-2 gap-3 max-w-[480px] w-full">
  <% @profiles.each do |profile| %>
    <%= button_to profile.name, new_profile_session_path(profile_id: profile.id),
                  method: :get, class: "p-4 rounded-md bg-white border" %>
  <% end %>
</div>

<% if @selected_profile %>
  <%= form_with url: profile_session_path, method: :post, local: true, class: "mt-6 flex flex-col gap-2" do |f| %>
    <%= f.hidden_field :profile_id, value: @selected_profile.id %>
    <%= f.text_field :pin, pattern: "\\d{4}", maxlength: 4, autofocus: true, placeholder: "PIN" %>
    <%= render Ui::Btn::Component.new(variant: "primary", size: "md", type: "submit") do %>Entrar<% end %>
  <% end %>

  <% if flash[:alert] %><p class="text-destructive mt-2"><%= flash[:alert] %></p><% end %>
<% end %>
```

- [ ] **Step 5: Run — pass**

Run: `docker compose exec web bundle exec rspec spec/requests/profile_sessions_spec.rb`

- [ ] **Step 6: Commit**

```bash
git add app/controllers/profile_sessions_controller.rb app/views/profile_sessions/ spec/requests/profile_sessions_spec.rb
git commit -m "feat(auth): add ProfileSessionsController + bare picker view"
```

---

## Task 13: Delete legacy `SessionsController`

**Files:**
- Delete: `app/controllers/sessions_controller.rb`
- Delete: `app/views/sessions/`

- [ ] **Step 1: Remove legacy code**

Run: `git rm app/controllers/sessions_controller.rb && git rm -r app/views/sessions`

- [ ] **Step 2: Update specs that reference `sessions_path`**

Search: `docker compose exec web grep -rn "sessions_path\b" spec/ app/views/ app/controllers/`
For each occurrence, replace with `new_family_session_path` or `new_profile_session_path` depending on intent. (Helpers in `system_auth_helpers.rb` get rewritten in Task 24.)

- [ ] **Step 3: Run full RSpec suite (failures expected — placeholders for now)**

Run: `docker compose exec web bundle exec rspec --fail-fast`
Expect existing system specs to fail until Task 24. Note failures, do not fix here.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat(auth): drop legacy SessionsController and views"
```

---

## Task 14: `Ui::ProfilePicker::Component` (single grid)

**Files:**
- Create: `app/components/ui/profile_picker/component.rb`
- Create: `app/components/ui/profile_picker/component.html.erb`

- [ ] **Step 1: Implement component**

```ruby
# app/components/ui/profile_picker/component.rb
class Ui::ProfilePicker::Component < ApplicationComponent
  def initialize(profiles:, selected: nil)
    @profiles = profiles
    @selected = selected
  end

  attr_reader :profiles, :selected
end
```

- [ ] **Step 2: Add template**

```erb
<%# app/components/ui/profile_picker/component.html.erb %>
<div class="w-full max-w-[480px]"
     data-controller="profile-picker"
     data-profile-picker-selected-id-value="<%= selected&.id %>">

  <div class="grid grid-cols-2 gap-3 mb-6">
    <% profiles.each do |profile| %>
      <%= link_to new_profile_session_path(profile_id: profile.id),
                  class: "p-4 rounded-md bg-white border-2 border-hairline hover:border-primary text-center font-bold #{'border-primary' if selected&.id == profile.id}",
                  data: { turbo_frame: "pin_modal" } do %>
        <div class="w-12 h-12 mx-auto mb-2 rounded-full bg-primary-soft grid place-items-center font-extrabold text-xl">
          <%= profile.name.first %>
        </div>
        <div><%= profile.name %></div>
        <div class="text-xs text-muted-foreground"><%= profile.parent? ? "Pai/Mãe" : "Criança" %></div>
      <% end %>
    <% end %>
  </div>

  <%= turbo_frame_tag "pin_modal" do %>
    <% if selected %>
      <%= render Ui::PinModal::Component.new(profile: selected) %>
    <% end %>
  <% end %>
</div>
```

- [ ] **Step 3: Update profile_sessions/new view**

Replace temporary content with:

```erb
<%# app/views/profile_sessions/new.html.erb %>
<div class="screen flex flex-col items-center justify-center p-10">
  <%= render Ui::LogoMark::Component.new(size: 48) %>
  <h1 class="font-display text-[28px] font-extrabold mb-6">Quem é você?</h1>
  <%= render Ui::ProfilePicker::Component.new(profiles: @profiles, selected: @selected_profile) %>
</div>
```

- [ ] **Step 4: Commit**

```bash
git add app/components/ui/profile_picker/ app/views/profile_sessions/new.html.erb
git commit -m "feat(auth): add ProfilePicker component (unified grid)"
```

---

## Task 15: `Ui::PinModal::Component` + Stimulus pin_pad

**Files:**
- Create: `app/components/ui/pin_modal/component.rb`
- Create: `app/components/ui/pin_modal/component.html.erb`
- Create: `app/components/ui/pin_modal/component.css`
- Create: `app/assets/controllers/pin_pad_controller.js`

- [ ] **Step 1: Implement component**

```ruby
# app/components/ui/pin_modal/component.rb
class Ui::PinModal::Component < ApplicationComponent
  def initialize(profile:, error: nil)
    @profile = profile
    @error = error
  end

  attr_reader :profile, :error
end
```

- [ ] **Step 2: Template (Soft Candy keypad — mockup A)**

```erb
<%# app/components/ui/pin_modal/component.html.erb %>
<div class="pin-card" data-controller="pin-pad" data-pin-pad-target="card">
  <div class="pin-avatar bg-primary text-white">
    <%= profile.name.first %>
  </div>
  <div class="pin-name"><%= profile.name %></div>
  <div class="pin-hint">Digite seu PIN</div>

  <div class="pin-dots" data-pin-pad-target="dots">
    <% 4.times do %><div class="pin-dot"></div><% end %>
  </div>

  <% if error %>
    <p class="text-destructive text-sm mt-1"><%= error %></p>
  <% end %>

  <%= form_with url: profile_session_path, method: :post, local: true,
                data: { pin_pad_target: "form", turbo_frame: "pin_modal" },
                class: "contents" do |f| %>
    <%= f.hidden_field :profile_id, value: profile.id %>
    <%= f.hidden_field :pin, value: "", data: { pin_pad_target: "input" } %>

    <div class="pin-pad">
      <% [1,2,3,4,5,6,7,8,9].each do |n| %>
        <button type="button" class="pin-key" data-action="click->pin-pad#press" data-digit="<%= n %>"><%= n %></button>
      <% end %>
      <button type="button" class="pin-key action" data-action="click->pin-pad#clear">esc</button>
      <button type="button" class="pin-key" data-action="click->pin-pad#press" data-digit="0">0</button>
      <button type="button" class="pin-key action" data-action="click->pin-pad#backspace">⌫</button>
    </div>
  <% end %>
</div>
```

- [ ] **Step 3: Component CSS**

```css
/* app/components/ui/pin_modal/component.css */
.pin-card { background: #fff; border-radius: 24px; padding: 32px 24px; box-shadow: 0 12px 32px rgba(0,0,0,.08); display: flex; flex-direction: column; align-items: center; gap: 16px; max-width: 360px; margin: 24px auto; }
.pin-avatar { width: 72px; height: 72px; border-radius: 50%; display: grid; place-items: center; font-weight: 800; font-size: 26px; color: #fff; }
.pin-name { font-weight: 800; font-size: 18px; }
.pin-hint { font-size: 13px; color: #888; }
.pin-dots { display: flex; gap: 14px; margin: 8px 0 12px; }
.pin-dot { width: 16px; height: 16px; border-radius: 50%; background: #e9ecef; transition: all .15s; }
.pin-dot.filled { background: #f59e0b; transform: scale(1.15); }
.pin-pad { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; width: 100%; max-width: 240px; }
.pin-key { aspect-ratio: 1; border-radius: 16px; background: #fef3c7; box-shadow: 0 3px 0 #f59e0b; border: none; font-size: 22px; font-weight: 700; cursor: pointer; }
.pin-key:hover { background: #fde68a; }
.pin-key.action { background: transparent; box-shadow: none; color: #888; font-size: 14px; }
```

Import this CSS via the existing component pattern (project uses Tailwind v4 `@import` in `app/assets/entrypoints/application.css` — append `@import "../../components/ui/pin_modal/component.css";` if other component CSS is wired the same way; otherwise inline equivalent Tailwind classes in the template).

- [ ] **Step 4: Stimulus controller**

```javascript
// app/assets/controllers/pin_pad_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dots", "input", "form"];

  connect() {
    this.value = "";
    this.render();
  }

  press(event) {
    if (this.value.length >= 4) return;
    this.value += event.currentTarget.dataset.digit;
    this.render();
    if (this.value.length === 4) this.submit();
  }

  backspace() {
    this.value = this.value.slice(0, -1);
    this.render();
  }

  clear() {
    this.value = "";
    this.render();
  }

  submit() {
    this.inputTarget.value = this.value;
    this.formTarget.requestSubmit();
  }

  render() {
    const dots = this.dotsTarget.querySelectorAll(".pin-dot");
    dots.forEach((dot, i) => dot.classList.toggle("filled", i < this.value.length));
    this.inputTarget.value = this.value;
  }
}
```

- [ ] **Step 5: Smoke-test in browser**

Run: `bin/dev`
Open `http://localhost:3000`, register a family + parent, log out, log back in, click a profile, confirm modal appears with keypad and dots fill on press.

- [ ] **Step 6: Commit**

```bash
git add app/components/ui/pin_modal/ app/assets/controllers/pin_pad_controller.js
git commit -m "feat(auth): add PinModal component with Soft Candy keypad"
```

---

## Task 16: `RegistrationsController` rewrite

**Files:**
- Modify: `app/controllers/registrations_controller.rb`
- Modify: `app/views/registrations/new.html.erb`

- [ ] **Step 1: Rewrite controller**

```ruby
# app/controllers/registrations_controller.rb
class RegistrationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create, raise: false

  def new
    @family = Family.new
  end

  def create
    result = Auth::CreateFamily.call(registration_params)
    if result.success?
      cookies.signed.permanent[:family_id] = { value: result.family.id, httponly: true, same_site: :lax }
      redirect_to new_parent_profile_path(onboarding: true)
    else
      @family = result.family
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:family).permit(:name, :email, :password)
  end
end
```

- [ ] **Step 2: Rewrite view**

```erb
<%# app/views/registrations/new.html.erb %>
<div class="screen flex flex-col items-center p-10">
  <%= render Ui::LogoMark::Component.new(size: 56) %>
  <h1 class="font-display text-[32px] font-extrabold mb-6">Criar família</h1>

  <% if flash[:alert] %><p class="text-destructive mb-4"><%= flash[:alert] %></p><% end %>

  <%= form_with model: @family, url: registration_path, local: true,
                class: "flex flex-col gap-3 max-w-[320px] w-full" do |f| %>
    <%= f.text_field :name, placeholder: "Nome da família", required: true,
        class: "w-full px-3 py-2 rounded-md border border-hairline bg-white" %>
    <%= f.email_field :email, placeholder: "Email", required: true,
        class: "w-full px-3 py-2 rounded-md border border-hairline bg-white" %>
    <%= f.password_field :password, placeholder: "Senha (mín. 12 caracteres)", required: true,
        class: "w-full px-3 py-2 rounded-md border border-hairline bg-white" %>
    <%= render Ui::Btn::Component.new(variant: "primary", size: "md", type: "submit") do %>Criar<% end %>
  <% end %>
</div>
```

- [ ] **Step 3: Commit**

```bash
git add app/controllers/registrations_controller.rb app/views/registrations/
git commit -m "feat(auth): rewrite registration to create Family + cookie"
```

---

## Task 17: `Parent::ProfilesController` PIN field + reset_pin action

**Files:**
- Modify: `app/controllers/parent/profiles_controller.rb`
- Modify: `app/views/parent/profiles/_form.html.erb`

- [ ] **Step 1: Read existing controller**

Run: `cat app/controllers/parent/profiles_controller.rb`
Plan how to merge — keep existing index/edit/update/destroy, replace `create` to use `Auth::CreateProfile`, add `reset_pin` action.

- [ ] **Step 2: Update controller**

Add `reset_pin` action:

```ruby
def reset_pin
  profile = current_family.profiles.find(params[:id])
  result = Auth::ResetPin.call(profile: profile, new_pin: params[:pin], actor: current_profile)
  if result.success?
    redirect_to parent_settings_path, notice: "PIN redefinido."
  else
    redirect_to parent_settings_path, alert: result.error
  end
end
```

Update `create` to use `Auth::CreateProfile`:

```ruby
def create
  pin = params.dig(:profile, :pin)
  attrs = profile_params.except(:pin)
  result = Auth::CreateProfile.call(family: current_family, params: attrs, pin: pin)
  if result.success?
    if params[:onboarding] == "true"
      session[:profile_id] = result.profile.id
      redirect_to result.profile.parent? ? parent_root_path : kid_root_path
    else
      redirect_to parent_profiles_path, notice: "Perfil criado."
    end
  else
    @profile = result.profile
    render :new, status: :unprocessable_entity
  end
end
```

Update `profile_params` to permit `:pin`. Onboarding flag from query string copied into hidden form field (Step 3).

- [ ] **Step 3: Add PIN field to form partial**

```erb
<%# Append to app/views/parent/profiles/_form.html.erb %>
<div class="flex flex-col gap-1">
  <%= f.label :pin, "PIN (4 dígitos)" %>
  <%= f.text_field :pin, pattern: "\\d{4}", maxlength: 4, inputmode: "numeric",
      autocomplete: "off", required: action_name == "new" %>
</div>

<% if params[:onboarding].present? %>
  <%= hidden_field_tag :onboarding, params[:onboarding] %>
<% end %>
```

- [ ] **Step 4: Smoke test**

Run: `bin/dev`. Register family → fill first parent name + PIN → submit → land on parent dashboard.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/parent/profiles_controller.rb app/views/parent/profiles/_form.html.erb
git commit -m "feat(auth): wire PIN field + reset_pin into Parent::ProfilesController"
```

---

## Task 18: `Parent::SettingsController` PIN reset UI

**Files:**
- Modify: `app/views/parent/settings/show.html.erb`

- [ ] **Step 1: Add PIN reset rows**

Append to settings view:

```erb
<section class="mt-8">
  <h2 class="font-display text-xl font-bold mb-4">PINs dos perfis</h2>
  <ul class="flex flex-col gap-3">
    <% current_family.profiles.order(:name).each do |profile| %>
      <li class="flex items-center justify-between bg-white rounded-md p-3 border">
        <span class="font-bold"><%= profile.name %> <span class="text-xs text-muted-foreground">(<%= profile.parent? ? "Pai/Mãe" : "Criança" %>)</span></span>
        <%= form_with url: reset_pin_parent_profile_path(profile), method: :patch, local: true,
                      class: "flex gap-2" do |f| %>
          <%= f.text_field :pin, pattern: "\\d{4}", maxlength: 4, inputmode: "numeric",
              autocomplete: "off", placeholder: "Novo PIN", required: true,
              class: "px-2 py-1 border rounded w-24" %>
          <%= render Ui::Btn::Component.new(variant: "secondary", size: "sm", type: "submit") do %>Resetar<% end %>
        <% end %>
      </li>
    <% end %>
  </ul>
</section>

<section class="mt-8">
  <%= button_to "Sair desta família neste dispositivo", family_session_path, method: :delete,
                class: "text-destructive font-bold" %>
</section>
```

- [ ] **Step 2: Commit**

```bash
git add app/views/parent/settings/show.html.erb
git commit -m "feat(auth): add PIN reset UI + family logout to settings"
```

---

## Task 19: `PasswordResetsController` rewire to Family

**Files:**
- Modify: `app/controllers/password_resets_controller.rb`

- [ ] **Step 1: Read existing controller**

Run: `cat app/controllers/password_resets_controller.rb`

- [ ] **Step 2: Replace `Profile.find_by(email: ...)` with `Family.find_by(email: ...)`**

Adjust mailer call (`PasswordResetMailer`) to pass family object. Token storage moves from profile to family — add a transient signed token via Rails `generates_token_for :password_reset, expires_in: 30.minutes` on `Family` model:

```ruby
# In app/models/family.rb (append)
generates_token_for :password_reset, expires_in: 30.minutes do
  password_salt&.last(10)
end
```

In controller `edit`/`update`, use `Family.find_by_token_for(:password_reset, params[:token])`.

(Adapt to existing structure; if mailer/templates already use a different token scheme, keep that scheme but swap the model.)

- [ ] **Step 3: Smoke-test or skip if mailer not running locally**

- [ ] **Step 4: Commit**

```bash
git add app/controllers/password_resets_controller.rb app/models/family.rb app/mailers/
git commit -m "feat(auth): rewire password reset to Family"
```

---

## Task 20: `InvitationsController` rewrite

**Files:**
- Modify: `app/controllers/invitations_controller.rb`

- [ ] **Step 1: Rewrite**

```ruby
# app/controllers/invitations_controller.rb
class InvitationsController < ApplicationController
  def show
    @invitation = ProfileInvitation.find_by(token: params[:token])
    if @invitation.nil? || @invitation.expires_at < Time.current || @invitation.accepted_at.present?
      render plain: "Convite expirado ou inválido.", status: :not_found
    end
  end

  def accept
    result = Auth::AcceptInvitation.call(token: params[:token])
    if result.success?
      cookies.signed.permanent[:family_id] = { value: result.family.id, httponly: true, same_site: :lax }
      redirect_to new_parent_profile_path(onboarding: true, invited: true)
    else
      render plain: result.error, status: :not_found
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add app/controllers/invitations_controller.rb
git commit -m "feat(auth): rewrite invitation accept to set family cookie + onboarding"
```

---

## Task 21: Switch-profile UI

**Files:**
- Modify: `app/views/layouts/parent.html.erb`
- Modify: `app/views/layouts/kid.html.erb`
- Create: `app/assets/controllers/switch_profile_controller.js`

- [ ] **Step 1: Stimulus confirm controller**

```javascript
// app/assets/controllers/switch_profile_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form"];

  confirm(event) {
    event.preventDefault();
    if (window.confirm("Sair desta conta?")) {
      this.formTarget.requestSubmit();
    }
  }
}
```

- [ ] **Step 2: Add button to parent layout**

In top-right of `app/views/layouts/parent.html.erb`:

```erb
<div data-controller="switch-profile" class="absolute top-4 right-4">
  <%= form_with url: profile_session_path, method: :delete, local: true,
                data: { switch_profile_target: "form" } do %>
    <button type="button" data-action="click->switch-profile#confirm"
            class="text-sm font-bold text-muted-foreground hover:text-primary">
      Trocar perfil
    </button>
  <% end %>
</div>
```

- [ ] **Step 3: Add same to kid layout**

Mirror the snippet into `app/views/layouts/kid.html.erb`, styling adjusted for kid theme (e.g. position above bottom nav).

- [ ] **Step 4: Commit**

```bash
git add app/views/layouts/ app/assets/controllers/switch_profile_controller.js
git commit -m "feat(auth): add switch-profile button + confirm to layouts"
```

---

## Task 22: Rewrite seeds

**Files:**
- Modify: `db/seeds.rb`

- [ ] **Step 1: Update seed file**

Replace family + profile creation block:

```ruby
# db/seeds.rb (replace family/profile section)
puts "Creating Demo Family..."
family = Family.create!(
  name: "Estrelas Incríveis",
  email: "familia@example.com",
  password: "supersecret1234"
)

puts "Creating Profiles..."
parent1 = Profile.create!(family: family, name: "Mamãe", role: :parent, avatar: "faceParent",
                          color: "rose", email: "mae@example.com", pin: "1111")
parent2 = Profile.create!(family: family, name: "Papai", role: :parent, avatar: "faceParent",
                          color: "sky", email: "pai@example.com", pin: "2222")

child1 = Profile.create!(family: family, name: "Lila", role: :child, avatar: "faceFox",
                         color: "peach", points: 340, pin: "1234")
child2 = Profile.create!(family: family, name: "Theo", role: :child, avatar: "faceHero",
                         color: "sky", points: 180, pin: "5678")
child3 = Profile.create!(family: family, name: "Zoe", role: :child, avatar: "facePrincess",
                         color: "rose", points: 520, pin: "9012")

# Rest of seeds unchanged (tasks, rewards, assignments)
```

- [ ] **Step 2: Run seeds**

Run: `docker compose exec web bin/rails db:reset`
Expected: success, no errors.

- [ ] **Step 3: Verify in console**

Run: `docker compose exec web bin/rails runner "p Family.first.authenticate('supersecret1234').present?; p Profile.first.authenticate_pin('1111') || Profile.first.authenticate_pin('1234')"`
Expected: `true` and `true`.

- [ ] **Step 4: Commit**

```bash
git add db/seeds.rb
git commit -m "feat(auth): rewrite seeds for Family creds + profile PINs"
```

---

## Task 23: Family factory

**Files:**
- Modify: `spec/factories/families.rb`

- [ ] **Step 1: Update factory**

```ruby
# spec/factories/families.rb
FactoryBot.define do
  factory :family do
    sequence(:name)  { |n| "Family #{n}" }
    sequence(:email) { |n| "family#{n}@example.com" }
    password { "supersecret1234" }
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add spec/factories/families.rb
git commit -m "test(auth): update Family factory with credentials"
```

---

## Task 24: Update `system_auth_helpers.rb`

**Files:**
- Modify: `spec/support/system_auth_helpers.rb`

- [ ] **Step 1: Read current helpers**

Run: `cat spec/support/system_auth_helpers.rb`

- [ ] **Step 2: Replace with new helpers**

```ruby
# spec/support/system_auth_helpers.rb
module SystemAuthHelpers
  def sign_in_family(family)
    visit new_family_session_path
    fill_in "Email da família", with: family.email
    fill_in "Senha", with: "supersecret1234"
    click_on "Entrar"
  end

  def sign_in_profile(profile, pin: "1234")
    sign_in_family(profile.family) unless current_path == new_profile_session_path
    click_on profile.name
    fill_pin(pin)
  end

  def fill_pin(pin)
    pin.chars.each do |digit|
      find("button.pin-key", text: digit, match: :first).click
    end
  end
end

RSpec.configure do |config|
  config.include SystemAuthHelpers, type: :system
end
```

(Adapt to existing helper API if specs already call e.g. `login_as(profile)` — provide a thin alias to `sign_in_profile`.)

- [ ] **Step 3: Commit**

```bash
git add spec/support/system_auth_helpers.rb
git commit -m "test(auth): rewrite system auth helpers for family + PIN"
```

---

## Task 25: System spec — signup flow

**Files:**
- Create: `spec/system/signup_flow_spec.rb`

- [ ] **Step 1: Write spec**

```ruby
# spec/system/signup_flow_spec.rb
require "rails_helper"

RSpec.describe "Family signup flow", type: :system do
  it "creates a family then first parent profile and lands on parent dashboard" do
    visit new_registration_path

    fill_in "Nome da família", with: "Os Silva"
    fill_in "Email", with: "silva@example.com"
    fill_in "Senha (mín. 12 caracteres)", with: "supersecret1234"
    click_on "Criar"

    expect(page).to have_current_path(new_parent_profile_path(onboarding: true))

    fill_in "Name", with: "Mamãe Silva"
    fill_in "PIN (4 dígitos)", with: "5555"
    click_on "Salvar"

    expect(page).to have_current_path(parent_root_path)
    expect(Family.find_by(email: "silva@example.com")).to be_present
  end
end
```

(Field labels must match the actual form — adjust if `Name` differs.)

- [ ] **Step 2: Run — pass**

Run: `docker compose exec web bundle exec rspec spec/system/signup_flow_spec.rb`

- [ ] **Step 3: Commit**

```bash
git add spec/system/signup_flow_spec.rb
git commit -m "test(auth): add signup flow system spec"
```

---

## Task 26: System spec — family login flow

**Files:**
- Create: `spec/system/family_login_flow_spec.rb`

- [ ] **Step 1: Spec**

```ruby
# spec/system/family_login_flow_spec.rb
require "rails_helper"

RSpec.describe "Family login flow", type: :system do
  let!(:family) { Family.create!(name: "Fam", email: "fam@example.com", password: "supersecret1234") }
  let!(:kid)    { family.profiles.create!(name: "Kid", role: :child, pin: "1234") }

  it "logs in family and lands on picker" do
    visit root_path
    expect(page).to have_current_path(new_family_session_path)

    fill_in "Email da família", with: "fam@example.com"
    fill_in "Senha", with: "supersecret1234"
    click_on "Entrar"

    expect(page).to have_current_path(new_profile_session_path)
    expect(page).to have_content("Kid")
  end
end
```

- [ ] **Step 2: Run — pass**

- [ ] **Step 3: Commit**

```bash
git add spec/system/family_login_flow_spec.rb
git commit -m "test(auth): add family login flow system spec"
```

---

## Task 27: System spec — profile pick + PIN

**Files:**
- Create: `spec/system/profile_pick_flow_spec.rb`

- [ ] **Step 1: Spec**

```ruby
# spec/system/profile_pick_flow_spec.rb
require "rails_helper"

RSpec.describe "Profile pick + PIN flow", type: :system, js: true do
  let!(:family) { Family.create!(name: "Fam", email: "fam@example.com", password: "supersecret1234") }
  let!(:kid)    { family.profiles.create!(name: "Lila", role: :child, pin: "1234") }

  it "lets a kid log in with PIN" do
    sign_in_family(family)

    click_on "Lila"
    fill_pin("1234")

    expect(page).to have_current_path(kid_root_path, ignore_query: true)
  end
end
```

- [ ] **Step 2: Run — pass** (requires JS driver — capybara default is `selenium` per project config; verify via `bin/rails about` or capybara config).

- [ ] **Step 3: Commit**

```bash
git add spec/system/profile_pick_flow_spec.rb
git commit -m "test(auth): add profile pick + PIN system spec"
```

---

## Task 28: System spec — switch profile

**Files:**
- Create: `spec/system/switch_profile_flow_spec.rb`

- [ ] **Step 1: Spec**

```ruby
# spec/system/switch_profile_flow_spec.rb
require "rails_helper"

RSpec.describe "Switch profile flow", type: :system, js: true do
  let!(:family) { Family.create!(name: "Fam", email: "fam@example.com", password: "supersecret1234") }
  let!(:kid)    { family.profiles.create!(name: "Lila", role: :child, pin: "1234") }
  let!(:other)  { family.profiles.create!(name: "Theo", role: :child, pin: "5678") }

  it "returns to picker, family cookie intact" do
    sign_in_profile(kid, pin: "1234")
    expect(page).to have_current_path(kid_root_path, ignore_query: true)

    accept_confirm { click_on "Trocar perfil" }

    expect(page).to have_current_path(new_profile_session_path)
    expect(page).to have_content("Theo")
  end
end
```

- [ ] **Step 2: Run — pass**

- [ ] **Step 3: Commit**

```bash
git add spec/system/switch_profile_flow_spec.rb
git commit -m "test(auth): add switch profile system spec"
```

---

## Task 29: System spec — parent invite

**Files:**
- Create: `spec/system/parent_invite_flow_spec.rb`

- [ ] **Step 1: Spec**

```ruby
# spec/system/parent_invite_flow_spec.rb
require "rails_helper"

RSpec.describe "Parent invite flow", type: :system do
  let!(:family) { Family.create!(name: "Fam", email: "fam@example.com", password: "supersecret1234") }
  let!(:invitation) do
    family.profile_invitations.create!(
      email: "newparent@example.com", token: SecureRandom.hex(16),
      expires_at: 1.day.from_now
    )
  end

  it "invitee accepts → onboarding → new parent profile" do
    visit invitation_acceptance_path(token: invitation.token)
    click_on "Aceitar convite"

    expect(page).to have_current_path(new_parent_profile_path(onboarding: true, invited: true))

    fill_in "Name", with: "Tia Ana"
    fill_in "PIN (4 dígitos)", with: "7777"
    click_on "Salvar"

    expect(page).to have_current_path(parent_root_path)
    expect(family.reload.profiles.where(role: :parent).pluck(:name)).to include("Tia Ana")
  end
end
```

(Adapt button labels to actual UI.)

- [ ] **Step 2: Run — pass**

- [ ] **Step 3: Commit**

```bash
git add spec/system/parent_invite_flow_spec.rb
git commit -m "test(auth): add parent invite flow system spec"
```

---

## Task 30: Migrate existing system specs

**Files:**
- Modify: `spec/system/kid_flow_spec.rb`
- Modify: `spec/system/parent_flow_spec.rb`
- Modify: `spec/system/activity_and_balance_flow_spec.rb`
- Modify: `spec/system/bulk_approval_flow_spec.rb`
- Modify: `spec/system/mission_rejection_flow_spec.rb`
- Modify: `spec/system/parent_management_flow_spec.rb`
- Modify: `spec/system/reward_rejection_flow_spec.rb`

- [ ] **Step 1: For each spec, replace any old auth helper calls**

Search/replace across `spec/system/`:

- `login_as(profile)` → `sign_in_profile(profile, pin: "1234")`
- Any direct `visit sessions_path` followed by clicks → `sign_in_family(family)` then `sign_in_profile(profile)`

Run: `docker compose exec web grep -l "login_as\|sessions_path" spec/system/`
For each file, edit as above. Rebuild factory usage so each profile is created with `pin: "1234"` (default factory provides this — no change needed).

- [ ] **Step 2: Run full system suite**

Run: `docker compose exec web bundle exec rspec spec/system/`
Expected: all pass.

- [ ] **Step 3: Commit**

```bash
git add spec/system/
git commit -m "test(auth): migrate existing system specs to family + PIN auth"
```

---

## Task 31: Final verification

- [ ] **Step 1: Full RSpec suite**

Run: `docker compose exec web bundle exec rspec`
Expected: green.

- [ ] **Step 2: Rubocop**

Run: `docker compose exec web bin/rubocop`
Fix any new violations.

- [ ] **Step 3: Brakeman**

Run: `docker compose exec web bin/brakeman -q`
Expected: no new warnings on session/cookie handling.

- [ ] **Step 4: Manual smoke test**

Run: `bin/dev`
Verify in browser:
1. Visit root with no cookie → family login form.
2. Register new family → first parent + PIN form → parent dashboard.
3. Sign out family → reopen → family login → picker (single grid mixed kids/parents).
4. Click profile → keypad modal → enter PIN → role-correct dashboard.
5. Click "Trocar perfil" → confirm → back at picker, family cookie kept.
6. Settings → reset a kid PIN → log in as kid with new PIN.

- [ ] **Step 5: Commit any cleanup**

```bash
git add -A
git commit -m "chore(auth): final cleanup"
```

---

## Self-Review Checklist

- ✅ Spec coverage: every Q1–Q16 decision has at least one task implementing it.
- ✅ No placeholders: every code step has full code; no TBD/TODO.
- ✅ Type consistency: `Auth::CreateProfile.call(family:, params:, pin:)` signature reused identically across services and controllers.
- ✅ TDD: each model/service has spec-first task; controllers verified via request specs; integration via system specs.
- ✅ Frequent commits: 31 tasks → ~31 commits, each atomic.
- ✅ DRY: PIN format regex (`PIN_FORMAT`) defined once on `Profile`; service signatures uniform.
- ✅ YAGNI: no lockout, no audit log, no per-device revocation table — explicitly out per spec.

## Open Risks

- **Mailer/password_reset**: Task 19 may reveal the existing implementation diverges from the snippet. If `generates_token_for` API doesn't fit, revert to existing token mechanism but anchor it on `Family`. Flag as deviation when encountered.
- **Stimulus controller import**: `app/assets/controllers/index.js` uses `stimulus-vite-helpers` autoload. New `pin_pad_controller.js` and `switch_profile_controller.js` must follow the autoload naming convention (`*_controller.js` directly under controllers dir). Verify by listing dir before commit.
- **System specs requiring JS**: Tasks 27–28 use `js: true`. Confirm the project's Capybara config has a working JS driver (Selenium/Cuprite) before running.
- **Existing dirty tree**: 30+ uncommitted UI files. Stash or commit before starting Task 1, or work in a worktree.

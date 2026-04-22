# Coding Conventions

**Analysis Date:** 2026-04-21

## Naming Patterns

**Files:**
- Snake_case for all Ruby files: `app/services/tasks/approve_service.rb`, `app/models/profile_task.rb`
- Namespace directories mirror module names: `app/services/tasks/` → `Tasks::` module namespace
- Namespaced controllers under role folders: `app/controllers/parent/`, `app/controllers/kid/`
- Component files use trailing `_component.rb`: `app/components/ui/modal/component.rb`, `app/components/ui/modal/header_component.rb`
- Query objects: `app/queries/approvals/pending_tasks_query.rb`
- Factory files: `spec/factories/profile.rb`, `spec/factories/global_tasks.rb`
- Test files mirror source structure: `spec/models/`, `spec/services/`, `spec/requests/`, `spec/system/`

**Functions/Methods:**
- camelCase in JavaScript/Stimulus controllers: `celebration_controller.js`, `count_up_controller.js`, `tabs_controller.js`
- snake_case in Ruby: `broadcast_points`, `current_profile`, `require_parent!`
- Predicate methods use `?` suffix: `success?`, `parent?`, `child?`, `awaiting_approval?`
- Dangerous/state-changing methods use `!` suffix: `increment!`, `update!`, `create!`
- Private methods in "private" section at end of class
- Convention over configuration: No explicit method prefixes like "get_" or "set_"

**Variables:**
- Instance variables: `@profile`, `@profile_task`, `@current_profile`
- Local variables: snake_case: `profile_task`, `child`, `global_task`
- Constants: UPPERCASE: `Result` (custom Data class)
- Avoid single-letter variables except in blocks: `threads.each(&:join)` acceptable

**Types & Classes:**
- PascalCase for all class names: `Profile`, `ProfileTask`, `GlobalTask`, `ApplicationService`
- Enum values lowercase: `enum :role, {child: 0, parent: 1}`
- Use Rails 8 hash form enums (not symbol form): `enum :role, {child: 0, parent: 1}` not `enum :role, [:child, :parent]`
- Model classes singular: `Profile` (not `Profiles`)
- Service classes: `Tasks::ApproveService`, `Rewards::RedeemService`
- Query classes: `Approvals::PendingTasksQuery`
- Controller classes: `Parent::ApprovalsController`, `Kid::MissionsController`
- Result type is `Data.define(:success, :error, :data)` (Ruby 3.2+ immutable struct)

## Code Style

**Formatting & Linting:**
- Tool: `rubocop-rails-omakase` (inherits from rails/rubocop-rails-omakase)
- Config: `.rubocop.yml` (minimal override, inherits from gem)
- Run: `bin/rubocop` (local), `bin/rubocop -f github` (CI with GitHub annotations)
- Cache: `tmp/rubocop/` (used in CI for performance)
- Standard gem (`>= 1.35.1`): Built on RuboCop, enforces consistent style

**Key Rubocop Rules:**
- 2-space indentation (no tabs)
- No trailing commas in multiline collections
- No single quotes preferred over double quotes
- Line length: Standard defaults apply

**Frontend Styling:**
- Tailwind 4: Utility-first CSS, no component-specific CSS files
- CSS directives: `@reference` used in `application.css` to include component CSS
- JavaScript: Stimulus controllers in `app/frontend/entrypoints/` (Vite-managed)
- No explicit Prettier config needed (Vite defaults applied)

## Import Organization

**Ruby Requires:**
1. Standard library: `require "spec_helper"` (RSpec hook)
2. Rails setup: `require "rails_helper"` (loads all Rails stack in tests)
3. Support files auto-loaded: `spec/support/**/*.rb` required in `spec/rails_helper.rb`
4. No explicit module requires (Rails Zeitwerk handles autoload)

**Rails Autoload:**
- Standard Rails autoload from `app/` directories: `app/models/`, `app/services/`, `app/controllers/`, `app/components/`, `app/queries/`
- Namespacing used for organization: `Tasks::ApproveService`, `Parent::ApprovalsController`, `Approvals::PendingTasksQuery`
- No path aliases configured; standard Rails paths used

## Error Handling

**Core Pattern - Service Results:**
- All services return `Result` object: `Data.define(:success, :error, :data)`
- Check status with `result.success?` predicate method
- Access error message with `result.error`
- Access returned data with `result.data`

**Error Flow:**
- Services validate state before mutations, return `fail_with(error_message)` for validation failures
- Rescue `ActiveRecord::RecordInvalid` and `ActiveRecord::RecordNotSaved` in service `call` method
- ApplicationController rescues `ActiveRecord::RecordNotFound` (404) and `ActionController::ParameterMissing` (400)
- Controller checks `result.success?` and responds with appropriate view/redirect and flash message

**Example Service Error:**
```ruby
def call
  unless @profile_task.awaiting_approval?
    return fail_with("Tarefa não está aguardando aprovação")
  end

  ActiveRecord::Base.transaction do
    # ... mutations ...
  end

  ok(@profile_task)
rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
  fail_with(e.message)
end
```

**Example Controller Usage:**
```ruby
def approve
  @profile_task = current_profile.family.profile_tasks.find(params[:id])
  result = Tasks::ApproveService.call(@profile_task)
  respond_after(result, success_msg: "Tarefa aprovada com sucesso!", fail_msg: "Não foi possível aprovar a tarefa.")
end
```

## Logging

**Framework:** Rails.logger (built-in `Rails.logger`)

**Patterns:**
- Log at service entry with ID: `Rails.logger.info("[Tasks::ApproveService] start profile_task_id=#{@profile_task.id}")`
- Log failures: `Rails.logger.info("[Tasks::ApproveService] failure not awaiting_approval id=#{@profile_task.id}")`
- Log success: `Rails.logger.info("[Tasks::ApproveService] success id=#{@profile_task.id}")`
- Log exceptions: `Rails.logger.error("[Tasks::ApproveService] exception id=#{@profile_task.id} error=#{e.message}")`
- Use service class name in brackets `[ClassName]` for tracing
- Include record IDs for debuggability
- No structured logging library (string interpolation with Rails.logger)

## Comments

**When to Comment:**
- Defense-in-depth guards: See `authorize_family!` inline doc in `app/controllers/concerns/authenticatable.rb`
- Security-critical logic: Document why action is taken
- Complex race condition handling: Explain thread-safety approach
- Rarely comment obvious code (e.g., `# Increment points` not needed)

**JSDoc/TSDoc:**
- Not used in codebase
- Stimulus controllers have minimal inline documentation
- CLAUDE.md serves as main architecture reference

## Function Design

**Size & Responsibility:**
- Service methods small and focused: typically 10-30 lines
- Controllers keep business logic in services only
- Action methods typically 5-10 lines: authenticate → load records → call service → respond
- Single responsibility principle: One public method per service class

**Parameters:**
- Services take model instances or primitives: `def initialize(profile_task)`, `def initialize(profile:, reward:)`
- Controllers pass context: `current_profile`, `current_family`
- Use keyword arguments in initializers for clarity
- Avoid passing hashes that require unpacking

**Return Values:**
- Services always return `Result` object (never raise exceptions to callers)
- Queries return chainable ActiveRecord relations: `.awaiting_approval.includes(...).order(...)`
- View components render HTML (implicit via `render` method)
- Broadcast helpers return nothing (side effect)

## Module Design

**Service Exports:**
- Services exposed via class method `.call(...)`: `Tasks::ApproveService.call(profile_task)`
- Implemented as: `def self.call(...) = new(...).call`

**Model Exports:**
- Public instance methods: `profile.parent?`, `profile_task.awaiting_approval?`
- Association methods: `profile.activity_logs`, `profile.profile_tasks`
- Scopes as classmethods: `ProfileTask.awaiting_approval` (returns relation)

**Query Objects:**
- `.call` instance method returns ActiveRecord relation
- Example: `Approvals::PendingTasksQuery.new(family: family).call`

**Controller Exports:**
- Public action methods: `def approve`, `def reject`
- Expose context to views: `helper_method :current_profile`

**ViewComponent Exports:**
- `initialize(**options)` to accept configuration
- Implicit render of `component.html.erb` template

## Service Objects (Core Pattern)

**Structure:**
```ruby
class Tasks::ApproveService < ApplicationService
  def initialize(profile_task)
    @profile_task = profile_task
    @profile = profile_task.profile
  end

  def call
    Rails.logger.info("[Tasks::ApproveService] start profile_task_id=#{@profile_task.id}")
    
    # 1. Validate state (return fail_with on validation failure)
    unless @profile_task.awaiting_approval?
      return fail_with("Tarefa não está aguardando aprovação")
    end

    # 2. Wrap mutations in transaction
    ActiveRecord::Base.transaction do
      @profile_task.update!(status: :approved, completed_at: Time.current)
      @profile.increment!(:points, @profile_task.points)
      @profile.activity_logs.create!(
        log_type: :earn,
        title: "Missão Concluída: #{@profile_task.title}",
        points: @profile_task.points
      )
    end

    Rails.logger.info("[Tasks::ApproveService] success id=#{@profile_task.id}")
    ok(@profile_task)  # Return success with data
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    Rails.logger.error("[Tasks::ApproveService] exception id=#{@profile_task.id} error=#{e.message}")
    fail_with(e.message)
  end
end
```

**Key Principles:**
- All database mutations inside `ActiveRecord::Base.transaction`
- Validate state before mutations
- Return `ok(data)` on success, `fail_with(error_message)` on failure
- Catch and log exceptions; never let them escape
- Use `!` methods (`update!`, `increment!`, `create!`) so transaction rolls back on error

## View Components (UI Pattern)

**Structure:**
```ruby
class ApplicationComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(**options)
    @options = options
  end
end
```

**Usage:**
- Inherit from `ApplicationComponent`
- Accept `**options` in initialize (configuration)
- Render view at `component.html.erb` alongside class
- Use Turbo::FramesHelper for Turbo Frame integration
- Namespace: `ui/modal/component.rb`, `ui/modal/header_component.rb`, etc.

## Query Objects (Data Access Pattern)

**Structure:**
```ruby
class Approvals::PendingTasksQuery
  def initialize(family:)
    @family = family
  end

  def call
    @family.profile_tasks
      .awaiting_approval
      .includes(:profile, :global_task)
      .joins(:profile)
      .order("profiles.name ASC, profile_tasks.created_at DESC")
  end
end
```

**Pattern:**
- Namespace under concern: `Approvals::PendingTasksQuery`
- Accept filter params in `initialize` as keyword arguments
- `call` method returns chainable ActiveRecord relation
- Always use `.includes()` for eager loading to prevent N+1 queries
- Chain scopes and joins for efficient queries

## Enums

**Rails 8 Hash Form (Required):**
```ruby
enum :role, {child: 0, parent: 1}, default: :child
```

**NOT the symbol form:**
```ruby
enum :role, [:child, :parent]  # Don't use this
```

**Usage:**
- Accessor methods auto-created: `profile.child?`, `profile.parent?`
- Comparison: `profile.child?` preferred over `profile.role == 'child'`
- Assignment: `profile.role = :child` or `profile.child!`
- Default: Specify with `default: :child` in enum declaration

## Controller Concerns

**Pattern - Authenticatable:**
```ruby
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :require_login
    helper_method :current_family
  end

  private

  def current_family
    current_profile&.family
  end

  def authorize_family!(record)
    # Defense-in-depth: verify record belongs to current family
    family_id = if record.respond_to?(:family_id)
                  record.family_id
                elsif record.respond_to?(:profile)
                  record.profile.family_id
                end
    raise ActiveRecord::RecordNotFound unless family_id && current_profile&.family_id == family_id
  end

  def require_login
    redirect_to root_path, alert: "Por favor, selecione um perfil primeiro." unless current_profile
  end

  def require_parent!
    redirect_to root_path, alert: "Acesso restrito para pais." unless current_profile&.parent?
  end

  def require_child!
    redirect_to root_path, alert: "Acesso restrito para filhos." unless current_profile&.child?
  end
end
```

**Usage:** Include in controller, call guards in action methods

## Race Condition Protection

**Critical for Points/Balance (Money-like operations):**
- Always use `ActiveRecord::Base.transaction` wrapping mutations
- Use atomic operations: `increment!(:points, amount)`, not `profile.points += amount`
- Validate state before mutations: `awaiting_approval?` check before approving
- Reload record inside transaction if checking stale data
- Never allow negative balances: Validate and rollback if balance would go negative
- Test concurrent scenarios: Use Mutex for thread synchronization in tests

**Example from spec:**
```ruby
context 'race condition: two concurrent redeems for same profile' do
  it 'allows exactly one to succeed and the other to fail with balance error' do
    results = []
    mutex = Mutex.new

    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          result = described_class.new(profile: Profile.find(child.id), reward: Reward.find(reward.id)).call
          mutex.synchronize { results << result }
        end
      end
    end

    threads.each(&:join)

    successes = results.count { |r| r.success? }
    failures = results.count { |r| !r.success? }

    expect(successes).to eq(1)
    expect(failures).to eq(1)
    expect(child.reload.points).to eq(0)
  end
end
```

## Database Transactions

**Pattern:**
- All multi-step state changes wrapped in `ActiveRecord::Base.transaction`
- All points/balance mutations inside transactions
- Activity logs created atomically with balance change
- Rollback on any exception (`!` methods raise `RecordInvalid`)
- Database-level foreign key constraints provide safety net
- Validations prevent invalid states pre-mutation

---

*Convention analysis: 2026-04-21*

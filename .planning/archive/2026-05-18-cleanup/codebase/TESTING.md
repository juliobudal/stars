# Testing Patterns

**Analysis Date:** 2026-04-21

## Test Framework

**Runner:**
- RSpec 8.0 via `rspec-rails` gem
- Config: `.rspec` (loads `spec_helper` and `rails_helper`)
- Run commands:
  ```bash
  bundle exec rspec                                    # Run all tests
  bundle exec rspec spec/services/tasks/approve_service_spec.rb:42    # Single example
  bin/rails test                                       # Minitest alias (uses RSpec in this project)
  bin/rails test:system                                # Run system tests only
  ```

**Assertion Library:**
- RSpec's built-in expectation syntax: `expect(thing).to matcher`
- Custom matchers via `shoulda-matchers` gem 7.0

**Helper Gems:**
- `factory_bot_rails` 6.5: Build test data with factories (not fixtures)
- `faker` 3.8: Generate realistic test data
- `shoulda-matchers` 7.0: AR model matchers (validations, associations, enums)
- `capybara`: Browser automation for system tests
- `selenium-webdriver`: Chrome headless driver for Capybara

## Test File Organization

**Location Pattern:**
- Model specs: `spec/models/{model_name}_spec.rb`
- Service specs: `spec/services/{namespace}/{service_name}_spec.rb`
- Request specs: `spec/requests/{namespace}/{controller_name}_spec.rb`
- System specs: `spec/system/{flow_name}_spec.rb`
- Factories: `spec/factories/{model_name}.rb`
- Support: `spec/support/{helper_name}.rb`

**Examples:**
- `spec/models/profile_spec.rb`
- `spec/services/tasks/approve_service_spec.rb`
- `spec/requests/parent/approvals_spec.rb`
- `spec/requests/kid/dashboard_spec.rb`
- `spec/system/kid_flow_spec.rb`
- `spec/factories/profiles.rb`

**Naming Convention:**
- Test files end in `_spec.rb` (RSpec auto-discovers)
- Describe blocks match what's being tested: `RSpec.describe Profile, type: :model`
- Context blocks for scenarios: `context 'when task is awaiting approval'`
- It blocks for assertions: `it 'updates status to approved'`

## Rails Helper Configuration

**File:** `spec/rails_helper.rb`

**Key Setup:**
```ruby
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rspec/rails"

# Auto-require all spec/support files
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Ensure test database schema matches current schema
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Transactional fixtures for speed
  config.use_transactional_fixtures = true
  
  # Include FactoryBot methods (create, build, etc.) without prefix
  config.include FactoryBot::Syntax::Methods
end

# Configure shoulda-matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
```

**What It Provides:**
- `config.use_transactional_fixtures = true`: Each test runs in transaction, auto-rolls back
- FactoryBot methods available without `FactoryBot.` prefix: `create(:profile)` not `FactoryBot.create(:profile)`
- Shoulda matchers: `expect(profile).to validate_presence_of(:name)`
- Rails fixtures path configured but not used (factories preferred)

## Test Structure

**Model Spec Pattern:**
```ruby
require "rails_helper"

RSpec.describe Profile, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:family) }
    it { is_expected.to have_many(:profile_tasks).dependent(:destroy) }
    it { is_expected.to have_many(:activity_logs).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_numericality_of(:points).is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(child: 0, parent: 1) }
  end
end
```

**Service Spec Pattern:**
```ruby
require 'rails_helper'

RSpec.describe Tasks::ApproveService do
  let(:family) { create(:family) }
  let(:child) { create(:profile, :child, family: family, points: 0) }
  let(:global_task) { create(:global_task, family: family, points: 50) }
  let(:profile_task) { create(:profile_task, :awaiting_approval, profile: child, global_task: global_task) }

  describe '#call' do
    context 'when task is awaiting approval' do
      it 'updates status to approved' do
        described_class.new(profile_task).call
        expect(profile_task.reload.status).to eq('approved')
      end

      it 'credits points to the child' do
        expect {
          described_class.new(profile_task).call
        }.to change { child.reload.points }.by(50)
      end

      it 'creates an activity log' do
        expect {
          described_class.new(profile_task).call
        }.to change(ActivityLog, :count).by(1)

        log = ActivityLog.last
        expect(log.log_type).to eq('earn')
        expect(log.points).to eq(50)
        expect(log.profile).to eq(child)
      end

      it 'returns success' do
        result = described_class.new(profile_task).call
        expect(result.success?).to be true
        expect(result.error).to be_nil
      end
    end

    context 'when task is already pending' do
      let(:profile_task) { create(:profile_task, :pending, profile: child, global_task: global_task) }

      it 'returns failure and does not change points' do
        result = described_class.new(profile_task).call
        expect(result.success?).to be false
        expect(result.error).to be_present
        expect(child.reload.points).to eq(0)
      end
    end
  end
end
```

**Request Spec Pattern:**
```ruby
require 'rails_helper'

RSpec.describe "Kid::Dashboard", type: :request do
  let(:family) { create(:family) }
  let(:child) { create(:profile, :child, family: family, points: 100) }
  let(:global_task) { create(:global_task, family: family, points: 50) }
  let(:profile_task) { create(:profile_task, :pending, profile: child, global_task: global_task) }

  before do
    host! "localhost"
    post "/sessions", params: { profile_id: child.id }
  end

  describe "GET /kid" do
    it "returns http success and shows missions" do
      task = profile_task
      get kid_root_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(task.title)
    end
  end

  describe "Security" do
    it "prevents parent from accessing kid dashboard" do
      parent = create(:profile, :parent, family: family)
      post "/sessions", params: { profile_id: parent.id }
      get kid_root_path
      expect(response).to redirect_to(root_path)
    end
  end
end
```

**System Spec Pattern:**
```ruby
require "rails_helper"

RSpec.describe "Kid Flow", type: :system do
  let!(:family) { create(:family) }
  let!(:child) { create(:profile, :child, family: family, name: "Filhote") }
  let!(:global_task) { create(:global_task, family: family, title: "Lavar Louça", points: 100) }
  let!(:profile_task) { create(:profile_task, profile: child, global_task: global_task, status: :pending) }

  before do
    visit root_path
    find("button", text: "Filhote").click
  end

  it "permite ao filho submeter uma missão e vê-la aguardando aprovação" do
    expect(page).to have_content("Filhote")
    expect(page).to have_content("Lavar Louça")
    expect(page).to have_content("100")

    click_on "FEITO! 🏅"

    expect(page).to have_content("Missão enviada para aprovação! 🚀")
    
    within "section", text: "Já feitas" do
      expect(page).to have_content("Lavar Louça")
      expect(page).to have_content("Aguardando Aprovação...")
    end
  end
end
```

## Mocking

**Framework:** RSpec's built-in mocking (`config.mock_with :rspec`)

**Partial Double Verification:**
- Setting: `config.verify_partial_doubles = true` in `spec/spec_helper.rb`
- Effect: Prevents mocking methods that don't exist on real objects
- Prevents typos in mock method names

**What to Mock:**
- External APIs (HTTP calls, third-party services)
- Time-dependent behavior (Time.current, Date.today)
- File system operations

**What NOT to Mock:**
- Models (use factories to create real instances)
- Services (test actual behavior)
- Databases (use transactional fixtures)
- Controllers (request specs test real flow)

**Pattern - Service Testing (no mocks):**
Test with real records and transactions:
```ruby
it 'creates an activity log' do
  expect {
    described_class.new(profile: child, reward: reward).call
  }.to change(ActivityLog, :count).by(1)
end
```

## Fixtures and Factories

**Factories Over Fixtures:**
- All test data created via FactoryBot factories in `spec/factories/`
- Factories use traits for variations
- Faker for realistic data: `Faker::Name.first_name`, `Faker::Hacker.say_something_smart`

**Factory Example:**
```ruby
FactoryBot.define do
  factory :profile do
    family
    name { Faker::Name.first_name }
    avatar { nil }
    role { :child }
    points { 0 }

    trait :parent do
      role { :parent }
    end

    trait :child do
      role { :child }
    end
  end
end
```

**Factory Associations:**
- Implicit factory matching: `family` creates `Family` (matches model name)
- Explicit factory: `global_task { create(:global_task, ...) }`
- Traits for role variants: `create(:profile, :parent)`, `create(:profile, :child)`

## Coverage

**Requirements:** Not enforced (no coverage threshold tool detected)

**Observation:** 
- Model specs test: associations, validations, enums
- Service specs test: core business logic, edge cases, race conditions
- Request specs test: endpoints, authorization
- System specs test: user workflows

**Test Coverage Areas:**
- `spec/models/`: Model validations and associations
- `spec/services/`: Service logic, transactions, edge cases, race conditions
- `spec/requests/`: Endpoint behavior, status codes, authorization
- `spec/system/`: Full user workflows via browser automation

## Test Types

**Unit Tests (Model & Service Specs):**
- Scope: Single class behavior in isolation
- Approach: Create test data with factories, call method, assert result
- Speed: Fast (no browser, minimal DB)
- Examples: `spec/models/profile_spec.rb`, `spec/services/tasks/approve_service_spec.rb`

**Integration Tests (Request Specs):**
- Scope: HTTP endpoint, controller, and service interaction
- Approach: POST/GET to endpoint, check response status/content, verify state change
- Speed: Moderate (DB transaction, but no browser)
- Examples: `spec/requests/parent/approvals_spec.rb`, `spec/requests/kid/dashboard_spec.rb`

**System Tests (E2E via Capybara):**
- Scope: Full user workflow through browser
- Approach: Visit page, interact with UI, check for expected content
- Speed: Slow (real browser, Selenium)
- Driver: Chrome headless via Capybara (configured in `spec/support/capybara.rb`)
- Examples: `spec/system/kid_flow_spec.rb`, `spec/system/parent_flow_spec.rb`

## Capybara Configuration

**File:** `spec/support/capybara.rb`

**Setup:**
```ruby
Capybara.register_driver :chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  
  # Specify chromium binary if google-chrome not available
  options.binary = "/usr/bin/chromium" if File.exist?("/usr/bin/chromium")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :chrome_headless
  end
end
```

**Common Capybara Methods:**
- `visit(path)`: Navigate to URL
- `click_on(text)`: Click link/button by text
- `find(selector)`: Get element by CSS/XPath
- `expect(page).to have_content(text)`: Assert text visible
- `expect(page).to have_selector(css)`: Assert element exists
- `within(selector)`: Scope expectation to element

## Common Patterns

**Async Testing (Change Blocks):**
```ruby
it 'credits points to the child' do
  expect {
    described_class.new(profile_task).call
  }.to change { child.reload.points }.by(50)
end
```

**Error Testing:**
```ruby
context 'when child has insufficient points' do
  let(:child) { create(:profile, :child, family: family, points: 50) }

  it 'returns failure with error' do
    result = described_class.new(profile: child, reward: reward).call
    expect(result.success?).to be false
    expect(result.error).to match(/saldo insuficiente/i)
  end
end
```

**Race Condition Testing (Concurrency):**
```ruby
it 'allows exactly one to succeed and the other to fail' do
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
```

## CI/CD Pipeline

**Local CI:** `bin/ci` (runs full pipeline locally before pushing)

**Steps in `config/ci.rb`:**
```ruby
CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Style: Ruby", "bin/rubocop"
  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Assets: Vite build", "bin/vite build"
  step "Tests: Rails", "bin/rails test"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"
end
```

**GitHub Actions:** `.github/workflows/ci.yml`

**Jobs:**
- `scan_ruby`: Brakeman security scan, bundler-audit gem CVE check
- `scan_js`: npm audit for JavaScript dependencies
- `lint`: Rubocop style check with GitHub formatter
- `test`: RSpec unit/service/request tests with PostgreSQL service
- `system-test`: Capybara system tests with Chrome headless, uploads screenshots on failure

**Database Setup in CI:**
- PostgreSQL service container with postgres:latest image
- Environment: `DATABASE_URL: postgres://postgres:postgres@localhost:5432`
- Schema: `bin/rails db:test:prepare` (loads schema, runs pending migrations)

**Commands Run:**
```bash
bin/rails db:test:prepare test           # Unit/service/request tests
bin/rails db:test:prepare test:system    # Capybara system tests
```

**Failure Handling:**
- Failed system test screenshots uploaded as artifact: `tmp/screenshots`
- All job failures prevent merge (required checks)

## Running Tests Locally

**Full Suite:**
```bash
bundle exec rspec                  # All specs
bundle exec rspec --fail-fast      # Stop on first failure
bundle exec rspec spec/models/     # Only model specs
```

**Single File/Example:**
```bash
bundle exec rspec spec/services/tasks/approve_service_spec.rb        # File
bundle exec rspec spec/services/tasks/approve_service_spec.rb:42     # Line number
bundle exec rspec --pattern "**/services/**/*_spec.rb"               # Glob
```

**System Tests Only:**
```bash
bin/rails test:system
```

**With Output:**
```bash
bundle exec rspec --format documentation      # Verbose output
bundle exec rspec --format progress           # Dots
```

**Local CI (Before Push):**
```bash
bin/ci                             # Run entire CI pipeline locally
```

---

*Testing analysis: 2026-04-21*

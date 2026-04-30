# Mission Recurrence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix kid dashboard "completed today" stale list, register autonomous daily mission reset cron, anchor the app to BR timezone, and lock current correct reject/once-task behavior with regression tests.

**Architecture:** Three small surgical patches — one Rails config line, one controller scope tweak, one `recurring.yml` entry — plus four spec additions/extensions. No new models, services, or migrations.

**Tech Stack:** Rails 8.1, Solid Queue (recurring scheduler), RSpec + FactoryBot, PostgreSQL, run inside `web` container via `make rspec`.

---

## File Structure

| File | Responsibility |
|---|---|
| `config/application.rb` | Set `config.time_zone = "America/Sao_Paulo"` so all `Date.current` / `Time.current` calls anchor to BR |
| `app/controllers/kid/dashboard_controller.rb` | Filter `@completed_today` by `assigned_date = Date.current` |
| `config/recurring.yml` | Register `daily_reset` cron entry under `production:` calling `DailyResetJob` at midnight |
| `spec/services/tasks/reject_service_spec.rb` | Extend with cap-edge + once-task retryable cases |
| `spec/services/tasks/daily_reset_service_spec.rb` | Extend with timezone midnight rollover specs |
| `spec/requests/kid/dashboard_spec.rb` | Extend with completed_today date scope cases |
| `spec/config/recurring_spec.rb` | New — sanity-check `daily_reset` entry presence |

`DailyResetJob` (`app/jobs/daily_reset_job.rb`) already exists and iterates `Family.find_each`, calling `Tasks::DailyResetService.new(family:)` per family. No changes needed in that file.

---

## Task 1: Set app timezone to BR

**Files:**
- Modify: `config/application.rb:39`

- [ ] **Step 1: Edit config**

Replace the commented line at `config/application.rb:39`:

```ruby
    # config.time_zone = "Central Time (US & Canada)"
```

With:

```ruby
    config.time_zone = "America/Sao_Paulo"
```

- [ ] **Step 2: Verify Rails picks it up**

Run: `make shell` then inside container `bin/rails runner 'puts Time.zone.name'`
Expected: `America/Sao_Paulo`

- [ ] **Step 3: Run full RSpec suite to surface time-sensitive breakages**

Run: `make rspec`
Expected: PASS overall, or specific failures from time-sensitive tests. If failures appear, capture the file:line list — they will be fixed in Task 2.

- [ ] **Step 4: If failures occurred in Step 3, fix them inline**

For each failing test that depends on wall-clock time:
- If it uses `Date.today` or `Time.now`, replace with `Date.current` / `Time.current`.
- If it freezes time without a zone, wrap in `Time.use_zone("America/Sao_Paulo")` or pass `Time.zone.local(...)` explicitly.

Re-run: `make rspec`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add config/application.rb
git commit -m "chore(config): anchor app time zone to America/Sao_Paulo"
```

If Step 4 made changes:

```bash
git add spec/
git commit -m "test: stabilize time-sensitive specs under BR time zone"
```

---

## Task 2: Scope kid `@completed_today` to today's date

**Files:**
- Test: `spec/requests/kid/dashboard_spec.rb`
- Modify: `app/controllers/kid/dashboard_controller.rb:12`

- [ ] **Step 1: Write failing tests**

Append the following block to `spec/requests/kid/dashboard_spec.rb` before the closing `end` of `RSpec.describe "Kid::Dashboard"`:

```ruby
  describe "completed_today scope" do
    let(:today_task) { create(:profile_task, :approved, profile: child, global_task: global_task, assigned_date: Date.current) }
    let(:yesterday_task) { create(:profile_task, :approved, profile: child, global_task: global_task, assigned_date: 1.day.ago.to_date) }

    it "shows missions approved with assigned_date = today" do
      today_task
      get kid_root_path
      expect(assigns(:completed_today)).to include(today_task)
    end

    it "hides missions approved on a previous day" do
      yesterday_task
      get kid_root_path
      expect(assigns(:completed_today)).not_to include(yesterday_task)
    end
  end
```

If the project does not allow `assigns` in request specs (Rails 8 default), substitute body assertions:

```ruby
    it "shows missions approved with assigned_date = today" do
      today_task
      get kid_root_path
      expect(response.body).to include(today_task.title)
    end

    it "hides missions approved on a previous day" do
      yesterday_task
      get kid_root_path
      expect(response.body).not_to include(yesterday_task.title)
    end
```

Confirm `:approved` trait exists in `spec/factories/profile_tasks.rb` (or equivalent). If it does not, add:

```ruby
trait :approved do
  status { :approved }
  completed_at { Time.current }
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `make shell` then inside container `bundle exec rspec spec/requests/kid/dashboard_spec.rb -e "completed_today scope"`
Expected: FAIL — yesterday_task still appears in `@completed_today`.

- [ ] **Step 3: Apply fix**

Edit `app/controllers/kid/dashboard_controller.rb:12`. Change:

```ruby
@completed_today  = ProfileTask.approved.where(profile: current_profile)
```

To:

```ruby
@completed_today  = ProfileTask.approved.for_today.where(profile: current_profile)
```

(`for_today` scope is defined at `app/models/profile_task.rb:63`.)

- [ ] **Step 4: Run tests to verify pass**

Run: `bundle exec rspec spec/requests/kid/dashboard_spec.rb -e "completed_today scope"`
Expected: PASS.

- [ ] **Step 5: Run the full kid dashboard spec to catch regressions**

Run: `bundle exec rspec spec/requests/kid/dashboard_spec.rb`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add spec/requests/kid/dashboard_spec.rb spec/factories/profile_tasks.rb app/controllers/kid/dashboard_controller.rb
git commit -m "fix(kid/dashboard): scope completed_today to assigned_date = today"
```

(Drop `spec/factories/profile_tasks.rb` from `git add` if no factory change was needed.)

---

## Task 3: Add regression spec — reject frees slot at cap edge

**Files:**
- Test: `spec/services/tasks/reject_service_spec.rb`

This locks current correct behavior: when `max_completions_per_period > 1` and rejecting an awaiting_approval drops consumed below cap, no extra pending appears beyond the existing flow.

- [ ] **Step 1: Add cap-edge test**

Append inside the existing `describe "post-reject slot refresh on a repeatable mission"` block in `spec/services/tasks/reject_service_spec.rb`, before its closing `end`:

```ruby
    context "with cap reached by a prior approval" do
      let(:gt) { create(:global_task, :daily, family: family, max_completions_per_period: 1) }
      let!(:approved) { create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :approved, completed_at: Time.current) }
      let(:awaiting) { create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :awaiting_approval) }

      it "rejects without spawning a new pending while cap remains met by the approval" do
        expect {
          described_class.new(awaiting).call
        }.not_to change { ProfileTask.where(profile: profile, global_task: gt, status: :pending).count }
        expect(awaiting.reload.status).to eq("rejected")
      end
    end
```

Note: `max_completions_per_period: 1` with one approved already meets cap. After reject, consumed = 1 (approved still consumes), still ≥ max → SlotRefresher destroys any pending and creates none. Asserts no pending appears.

- [ ] **Step 2: Run test to verify it passes immediately (locking existing behavior)**

Run: `bundle exec rspec spec/services/tasks/reject_service_spec.rb -e "cap reached by a prior approval"`
Expected: PASS (this is a regression lock — no implementation change needed).

- [ ] **Step 3: Commit**

```bash
git add spec/services/tasks/reject_service_spec.rb
git commit -m "test(tasks/reject): lock cap-edge behavior when prior approval meets cap"
```

---

## Task 4: Add regression spec — once-task retryable on reject

**Files:**
- Test: `spec/services/tasks/reject_service_spec.rb`

- [ ] **Step 1: Add once-task test**

Append to `spec/services/tasks/reject_service_spec.rb` before the file's closing `end`:

```ruby
  describe "once-frequency mission rejection" do
    let(:family) { create(:family) }
    let(:profile) { create(:profile, :child, family: family) }
    let(:once_task) { create(:global_task, :once, family: family, max_completions_per_period: 1) }
    let(:awaiting) { create(:profile_task, profile: profile, global_task: once_task, assigned_date: Date.current, status: :awaiting_approval) }

    it "spawns a new pending row so the kid can retry the once-mission" do
      expect {
        described_class.new(awaiting).call
      }.to change {
        ProfileTask.where(profile: profile, global_task: once_task, status: :pending).count
      }.from(0).to(1)
      expect(awaiting.reload.status).to eq("rejected")
    end
  end
```

Confirm `:once` trait on `:global_task` factory. If absent, add to `spec/factories/global_tasks.rb`:

```ruby
trait :once do
  frequency { :once }
end
```

- [ ] **Step 2: Run test to verify it passes**

Run: `bundle exec rspec spec/services/tasks/reject_service_spec.rb -e "once-frequency"`
Expected: PASS. Once-task rejected → SlotRefresher counts `consuming_slot` (excludes `:rejected`) → consumed = 0 < max → creates new pending.

- [ ] **Step 3: Commit**

```bash
git add spec/services/tasks/reject_service_spec.rb spec/factories/global_tasks.rb
git commit -m "test(tasks/reject): lock retryable behavior for rejected once-missions"
```

(Drop the factory file from `git add` if the trait already existed.)

---

## Task 5: Add timezone-aware midnight rollover spec for DailyResetService

**Files:**
- Test: `spec/services/tasks/daily_reset_service_spec.rb`

- [ ] **Step 1: Add midnight rollover spec**

Append before the closing `end` of the outermost `RSpec.describe` block in `spec/services/tasks/daily_reset_service_spec.rb`:

```ruby
  describe "timezone-aware @date" do
    include ActiveSupport::Testing::TimeHelpers

    around do |example|
      Time.use_zone("America/Sao_Paulo") { example.run }
    end

    it "uses today's BR date when called at 23:30 BRT" do
      travel_to Time.zone.local(2026, 4, 30, 23, 30, 0) do
        service = described_class.new(family: family)
        expect(service.instance_variable_get(:@date)).to eq(Date.new(2026, 4, 30))
      end
    end

    it "rolls over to next BR date past midnight" do
      travel_to Time.zone.local(2026, 5, 1, 0, 30, 0) do
        service = described_class.new(family: family)
        expect(service.instance_variable_get(:@date)).to eq(Date.new(2026, 5, 1))
      end
    end
  end
```

- [ ] **Step 2: Run test to verify it passes**

Run: `bundle exec rspec spec/services/tasks/daily_reset_service_spec.rb -e "timezone-aware"`
Expected: PASS. `DailyResetService` defaults `@date` to `Time.current.in_time_zone(family.timezone).to_date` (`app/services/tasks/daily_reset_service.rb:5`).

- [ ] **Step 3: Commit**

```bash
git add spec/services/tasks/daily_reset_service_spec.rb
git commit -m "test(tasks/daily_reset): assert timezone-aware date rollover"
```

---

## Task 6: Register `daily_reset` cron in `config/recurring.yml`

**Files:**
- Test: `spec/config/recurring_spec.rb`
- Modify: `config/recurring.yml`

- [ ] **Step 1: Write failing test**

Create `spec/config/recurring_spec.rb`:

```ruby
require 'rails_helper'
require 'yaml'

RSpec.describe "config/recurring.yml" do
  let(:config) { YAML.safe_load_file(Rails.root.join("config/recurring.yml")) }

  it "registers daily_reset under production with class DailyResetJob" do
    entry = config.dig("production", "daily_reset")
    expect(entry).to be_a(Hash), "Expected production.daily_reset to be defined"
    expect(entry["class"]).to eq("DailyResetJob")
  end

  it "schedules daily_reset at midnight" do
    expect(config.dig("production", "daily_reset", "schedule")).to eq("0 0 * * *")
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/config/recurring_spec.rb`
Expected: FAIL — `production.daily_reset` is not defined.

- [ ] **Step 3: Edit `config/recurring.yml`**

Add the `daily_reset` entry under the existing `production:` block, sibling to `clear_solid_queue_finished_jobs`. The full file should look like:

```yaml
# examples:
#   periodic_cleanup:
#     class: CleanSoftDeletedRecordsJob
#     queue: background
#     args: [ 1000, { batch_size: 500 } ]
#     schedule: every hour
#   periodic_cleanup_with_command:
#     command: "SoftDeletedRecord.due.delete_all"
#     priority: 2
#     schedule: at 5am every day

production:
  clear_solid_queue_finished_jobs:
    command: "SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)"
    schedule: every hour at minute 12
  daily_reset:
    class: DailyResetJob
    schedule: "0 0 * * *"
    queue: default
```

- [ ] **Step 4: Run test to verify pass**

Run: `bundle exec rspec spec/config/recurring_spec.rb`
Expected: PASS.

- [ ] **Step 5: Verify Solid Queue accepts the config**

Run: `bin/rails runner -e production 'puts SolidQueue::Configuration.new.recurring_tasks.map(&:key).inspect' 2>/dev/null || echo "Skipped — production env not bootable in dev"`

If the command runs cleanly, expected output includes `"daily_reset"`. If it errors due to missing production secrets, accept the test-level coverage as sufficient.

- [ ] **Step 6: Commit**

```bash
git add config/recurring.yml spec/config/recurring_spec.rb
git commit -m "feat(jobs): register daily_reset cron at midnight (BR)"
```

---

## Task 7: Run full suite & lint, push for review

**Files:** none

- [ ] **Step 1: Run full RSpec suite**

Run: `make rspec`
Expected: PASS.

- [ ] **Step 2: Run lint**

Run: `make lint`
Expected: PASS or auto-fixable diffs only.

- [ ] **Step 3: If lint touched files, review and commit**

```bash
git status
git diff
git add <files>
git commit -m "chore(lint): rubocop autofix"
```

- [ ] **Step 4: Final summary verification**

Confirm all of the following hold:
- `Time.zone.name` returns `"America/Sao_Paulo"` in `make c`.
- `ProfileTask.approved.for_today.count` matches what kid dashboard renders.
- `config/recurring.yml` `production.daily_reset` entry exists.
- `make rspec` passes end-to-end.

Plan complete.

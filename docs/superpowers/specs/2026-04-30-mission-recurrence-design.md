# Mission Recurrence — Display & Reset Fixes

**Date:** 2026-04-30
**Author:** Julio Budal (with Claude)
**Status:** Draft for review

## Context

LittleStars kid missions support `daily | weekly | monthly | once` recurrence via `GlobalTask.frequency` plus `max_completions_per_period` slot caps. `Tasks::SlotRefresher` regenerates `ProfileTask` slots per period. Investigation revealed three concrete defects:

1. **Stale completed list:** `Kid::DashboardController#index` loads `@completed_today = ProfileTask.approved.where(profile: current_profile)` with no date scope (`app/controllers/kid/dashboard_controller.rb:12`). Approved tasks accumulate forever in the kid's "completed today" panel.
2. **No autonomous midnight reset:** `Tasks::DailyResetJob` exists but is not registered in `config/recurring.yml`. Slot regeneration only fires when the kid opens the dashboard. Parent dashboards stay stale until then.
3. **Implicit timezone:** `config.time_zone` is unset (commented in `config/application.rb:39`). `Date.current` follows server TZ, which can drift from BR family expectations of "today".

Two perceived bugs (reject-frees-slot, once-task retry on reject) were verified to already work via `consuming_slot` excluding `:rejected`. They lack regression tests, so we add coverage.

## Goals

- Kid dashboard "completed today" shows only missions with `assigned_date = Date.current`.
- Daily reset runs autonomously at midnight BR time without depending on a kid opening the app.
- App-wide time anchor is `America/Sao_Paulo`.
- Lock current correct behavior with regression specs (reject path, once-task retry).

## Non-Goals

- Per-family timezone override (column exists, deferred until product needs it).
- New UI affordances ("resets at midnight" hint, scheduled-job admin panel).
- Changes to once-task semantics (approved-once stays permanently consumed; rejected-once becomes retryable — both already true).
- Refactoring of `DashboardController` aggregation logic.

## Design

### App timezone

Set `Rails.application.config.time_zone = "America/Sao_Paulo"` in `config/application.rb`. All `Date.current`, `Time.current`, and `Time.zone.now` calls now anchor to BR local time. `Family.timezone` column remains for future per-family override but has no consumers yet.

**Risk:** existing specs using `Date.today` or wall-clock comparisons may shift by hours. Mitigation: run full RSpec suite after change, fix any time-sensitive tests inline.

### Kid dashboard scope

Replace line 12 of `app/controllers/kid/dashboard_controller.rb`:

```ruby
# before
@completed_today = ProfileTask.approved.where(profile: current_profile)

# after
@completed_today = ProfileTask.approved.for_today.where(profile: current_profile)
```

`ProfileTask.for_today` scope already exists (`app/models/profile_task.rb:63`) and accepts an optional date argument, defaulting to `Date.current`. Tasks approved on prior days disappear from the kid's completed list at midnight rollover.

### Cron registration

Add `daily_reset` entry to `config/recurring.yml` under the existing `production:` block (sibling to `clear_solid_queue_finished_jobs`):

```yaml
production:
  clear_solid_queue_finished_jobs: # existing
    ...
  daily_reset:
    class: DailyResetJob
    schedule: "0 0 * * *"
    queue: default
```

Development is not added; `bin/dev` typically does not run the recurring scheduler, and on-demand dashboard call covers dev usage. `DailyResetJob` (`app/jobs/daily_reset_job.rb`) calls `Tasks::DailyResetService.new.call`, which iterates active `GlobalTask`s and asks `SlotRefresher` to ensure today's slot exists for each child profile. SlotRefresher is idempotent (locks the period, checks for existing pending), so the on-demand call from `Kid::DashboardController#index` remains as a safety net.

**Solid Queue requirement:** the recurring scheduler must run for the cron to fire. Verify deploy includes `bin/jobs` or equivalent. Dev environment (`bin/dev`) may not include the dispatcher; manual triggering remains acceptable in development.

**Scale note:** `DailyResetService` with no family argument scans all `GlobalTask`s. Acceptable at current data volume; flag as future optimization if N+1 surfaces.

## Test Plan

All specs run via `make rspec`.

### `spec/requests/kid/dashboard_spec.rb` (new or extended)

- Approved `ProfileTask` with `assigned_date: Date.current` appears under "completed today".
- Approved `ProfileTask` with `assigned_date: 1.day.ago` does **not** appear under "completed today".
- Pending and awaiting_approval lists unaffected by date scope change.

### `spec/services/tasks/reject_service_spec.rb` (new tests)

- Daily catalog GlobalTask, `max_completions_per_period: 1`, awaiting_approval ProfileTask. Reject → ProfileTask becomes `:rejected`; a new `:pending` ProfileTask exists for the same `assigned_date`.
- Daily catalog GlobalTask, `max: 2`, one approved + one awaiting_approval. Reject the awaiting one → consumed count drops to 1, no new pending created (one approved still satisfies cap below max but pending already absent — assert single approved remains, no extra pending).
- Once-frequency GlobalTask, awaiting_approval. Reject → new pending exists (retryable on reject).

### `spec/services/tasks/daily_reset_service_spec.rb` (new tests)

- With `Time.zone = "America/Sao_Paulo"`, freezing time at `2026-04-30 23:30 -03` → `DailyResetService` `@date == 2026-04-30`.
- Freezing time at `2026-05-01 00:30 -03` → `@date == 2026-05-01`. Confirms midnight rollover anchors to BR.

### `spec/config/recurring_spec.rb` (new)

- Load `config/recurring.yml` via `YAML.safe_load_file`, assert `production.daily_reset` key present with `class: "DailyResetJob"` and `schedule: "0 0 * * *"`.

## Files Changed

| File | Type |
|---|---|
| `config/application.rb` | Edit (timezone) |
| `app/controllers/kid/dashboard_controller.rb` | Edit (scope) |
| `config/recurring.yml` | Edit (new entry) |
| `spec/requests/kid/dashboard_spec.rb` | New / extend |
| `spec/services/tasks/reject_service_spec.rb` | Extend |
| `spec/services/tasks/daily_reset_service_spec.rb` | Extend |
| `spec/config/recurring_spec.rb` | New |

No migrations. No model changes. No new services or jobs.

## Open Questions

None at design time. Implementation may surface time-sensitive spec failures from the timezone change — handle inline.

## Out-of-Scope Follow-Ups

- Per-family timezone override (use `Family.timezone` column when product needs it).
- UI affordance: "Tasks reset at midnight" hint on kid empty state.
- N+1 audit of `DailyResetService` for scale.
- Decision on once-task post-approval visibility (currently retained as approved record forever; could prune after period).

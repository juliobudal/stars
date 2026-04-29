# Repeatable Missions — Design Spec

**Date:** 2026-04-29
**Status:** Approved (brainstorming complete)
**Owner:** Julio Budal

## Problem

Today every `GlobalTask` produces exactly one `ProfileTask` per period (day/week/month). This forces missions like "brush teeth" — which children should perform multiple times within the same window — to fit a single completion model. Parents cannot define a per-period cap > 1 without creating duplicate `GlobalTask` rows.

## Goal

Allow each `GlobalTask` to declare a maximum number of completions per period, with sane defaults preserving today's behaviour. Each individual completion remains an auditable, independently approvable submission with its own photo, comment, and timestamp.

## Non-goals

- Hourly slots / named time-of-day windows (morning / afternoon / night).
- Variable point values per completion within the same mission.
- Streak adjustments tied to repeated completions on the same day.
- Repeatability for `source: :custom` missions (custom missions remain single-shot).

## UX overview

- Kid dashboard displays a single card per mission (no progress badge by default).
- After a completion, the card disappears (existing Turbo Stream `remove`); a new pending `ProfileTask` is broadcast back into the kid dashboard once a slot is free.
- When the cap is reached, no new card returns. An optional discreet celebratory toast may surface ("Já completou escovar dentes hoje! 3/3 ✨"). Toast wiring is deferred — not required for v1.
- Parent form gets a "Repetível no período" toggle (Stimulus). Toggle off ⇒ cap = 1 and the count input is hidden. Toggle on ⇒ reveals a numeric input (min 1, max 20, default 3) with a label that switches between "Quantas vezes por dia / semana / mês?" based on the selected frequency. Toggle is disabled when frequency = `once`.
- Parent approval queue is unchanged: each completion appears as a separate awaiting_approval item, each with its own photo / comment.
- Parent activity log is unchanged: each approval emits one `earn` `ActivityLog` row.

## Counting rules (locked)

- A slot is **consumed** by `awaiting_approval` and `approved` rows in the period.
- `rejected` rows do **not** consume a slot — rejecting a submission frees the slot.
- `pending` rows do not count towards consumption — they are the "available slot" itself.
- The kid sees at most one `pending` row per (profile, global_task, period) at a time. Spawning a new pending row only happens after the current one moves to `awaiting_approval` (or after a reject frees the slot).

## Architecture

### Data model

Migration: `add_max_completions_per_period_to_global_tasks`

```ruby
add_column :global_tasks, :max_completions_per_period, :integer, default: 1, null: false
add_check_constraint :global_tasks,
  "max_completions_per_period >= 1",
  name: "max_completions_positive"
```

`GlobalTask` validations:

- `max_completions_per_period`: integer, `>= 1`, `<= 20`.
- `before_validation` callback forces `max_completions_per_period = 1` when `frequency: once`.
- Helper: `repeatable?` returns `max_completions_per_period > 1`.

`ProfileTask` keeps its current columns. Two new scopes:

```ruby
scope :in_period_for, ->(global_task, date) {
  where(assigned_date: ProfileTask.period_range(global_task, date))
}

scope :consuming_slot, -> { where(status: %i[awaiting_approval approved]) }
```

`ProfileTask.period_range(global_task, date)` resolves to:

| frequency | range |
|-----------|-------|
| `daily`   | `date..date` |
| `weekly`  | `date.beginning_of_week..date.end_of_week` (week_start respected via family settings) |
| `monthly` | `date.beginning_of_month..date.end_of_month` |
| `once`    | full lifetime (cap is always 1, semantics unchanged) |

### `Tasks::SlotRefresher` (new service)

Single responsibility: ensure exactly one `pending` `ProfileTask` exists per (profile, global_task, period) **iff** there is still slot capacity.

```ruby
module Tasks
  class SlotRefresher < ApplicationService
    def initialize(profile:, global_task:, date: nil)
      @profile = profile
      @global_task = global_task
      @date = date || Time.current.in_time_zone(profile.family.timezone).to_date
    end

    def call
      ActiveRecord::Base.transaction do
        period_pts = ProfileTask
          .where(profile: @profile, global_task: @global_task)
          .in_period_for(@global_task, @date)
          .lock # row-level lock on the period set

        consumed = period_pts.consuming_slot.count
        max = @global_task.max_completions_per_period

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
    end
  end
end
```

Properties:

- Idempotent: repeated calls converge to the same state.
- Concurrency-safe: `FOR UPDATE` lock on the period scope prevents two concurrent completes from each spawning a new pending row.
- Skips entirely for `source: :custom` missions because custom `ProfileTask` rows have no `global_task`.

### Service integration points

`Tasks::DailyResetService`:

- Replace `ProfileTask.find_or_create_by!(profile, global_task, assigned_date)` with `Tasks::SlotRefresher.new(profile:, global_task:, date:).call`.
- `applicable_today?` is unchanged. It still controls whether reset runs at all today; the refresher manages the period-level state.

`Tasks::CompleteService`:

- After flipping the PT to `:awaiting_approval` inside the existing transaction, call `SlotRefresher` for the same `(profile, global_task, assigned_date)`. The auto-approve branch runs unchanged after that.
- `last_pending_task_for_today?` keeps current implementation. If the refresher has just created a new pending row, the helper correctly returns `false` and the "all cleared" celebration is suppressed — desired behaviour.

`Tasks::ApproveService`:

- After updating status to `:approved` and writing the `ActivityLog` `earn` row, call `SlotRefresher` (idempotent — confirms the post-approval state and re-creates pending if the cap allows).

`Tasks::RejectService`:

- After updating status to `:rejected`, call `SlotRefresher` to free the slot and respawn pending.

### UI changes

Kid side (`app/views/kid/missions/`, `app/components/kid/`):

- No structural change to the mission card. The existing Turbo Stream `remove` (`ProfileTask#remove_from_kid_dashboard`) keeps doing its job; a new pending PT created by the refresher reaches the kid dashboard via the existing append broadcast.
- Optional v2: a discreet `fx_stage` celebration toast when the cap is reached. Out of scope for v1.

Parent side (`app/views/parent/global_tasks/_form.html.erb` and a new Stimulus controller):

- New `<input type="checkbox">` "Repetível no período" tied to a `repeatable_controller` Stimulus controller.
- Hidden by default: numeric input bound to `global_task[max_completions_per_period]`, min=1, max=20, default=3.
- The label of the numeric input switches between "dia / semana / mês" using a Stimulus value tied to the existing frequency `<select>`.
- When `frequency = once`, the toggle is disabled and the value is forced to 1 by the form (and re-enforced by the model callback).

Parent approval queue and parent activity log: no changes.

## Edge cases

- **Cap reduced via edit.** Parent edits a `GlobalTask` from max=5 to max=2 after 3 completions today. Next refresher call detects `consumed=3 >= 2`, destroys any pending row. Approved rows remain — past completions are not reverted.
- **Frequency change.** Switching `daily → weekly` after some completions: `period_range` always derives from the current `frequency`, so historical rows may "leak" into the wider window the first time it triggers. Documented as expected; rare manual action.
- **`once` with `max > 1`.** `before_validation` forces max to 1. Form prevents reaching this state in the UI; the model is the last line of defence.
- **Custom missions.** `source: :custom` rows have no `global_task`, so the refresher is never invoked for them. They remain strictly single-shot.
- **Backfill.** Migration default of 1 means every existing row keeps current behaviour. Zero breaking change in production.

## Tests

RSpec coverage to add / update:

- `spec/models/global_task_spec.rb` — `max_completions_per_period` validations; `once` forces max=1.
- `spec/models/profile_task_spec.rb` — `in_period_for` scope across daily / weekly / monthly windows; `consuming_slot` scope.
- `spec/services/tasks/slot_refresher_spec.rb` (new):
  - creates pending when none exists;
  - does not duplicate pending;
  - destroys orphan pending when the cap is reached;
  - releases a slot after reject;
  - holds under concurrency (advisory lock or threaded test).
- `spec/services/tasks/complete_service_spec.rb` — after a complete, a new pending row is spawned when `max > 1`; `all_cleared` broadcast is suppressed when refresher has spawned a new pending.
- `spec/services/tasks/approve_service_spec.rb` — refresher invocation is idempotent post-approval.
- `spec/services/tasks/reject_service_spec.rb` — slot is freed after reject.
- `spec/services/tasks/daily_reset_service_spec.rb` — uses refresher; `max=3` does not pre-create three pending rows.
- `spec/system/kid/repeatable_missions_spec.rb` — Capybara: kid completes twice, sees card disappear and reappear; on the 3rd completion the card stays gone.
- `spec/system/parent/global_task_form_spec.rb` — repeatable toggle reveals/hides the numeric input; toggle disabled when `frequency = once`.

## Open questions / deferred

- Cap-reached celebration toast on the kid side: deferred to v2.
- Whether to expose total completed / cap on the kid card after the cap is reached (e.g. `3/3` chip): explicitly out of scope for v1 per UX decision.

---
phase: 06-wishlist-goal-tracking
plan: 07
subsystem: ui
tags: [viewcomponent, parent-dashboard, n+1, eager-loading, wishlist, ptbr]

# Dependency graph
requires:
  - phase: 06-wishlist-goal-tracking
    provides: "Profile#wishlist_reward association (06-01)"
provides:
  - Parent-side read-only visibility of each kid's pinned wishlist on parent dashboard
  - N+1 prevention on Parent::DashboardController#index for the wishlist association
  - Regression guard asserting parent surface stays read-only (no link/form mutation paths)
affects: [parent-ui, future-parent-dashboards, wishlist-multi-pin-extensions]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Read-only ViewComponent slot pattern (helper + template branch with 'Sem meta' empty state, no mutation surface)"
    - "Defensive `kid.respond_to?(:wishlist_reward)` guard in component helper for stub compatibility"
    - "Eager-load companion to component helper additions (controller + component edited together to keep N+1 prevention contract intact)"

key-files:
  created: []
  modified:
    - app/components/ui/kid_progress_card/component.rb
    - app/components/ui/kid_progress_card/component.html.erb
    - app/controllers/parent/dashboard_controller.rb
    - spec/components/ui/kid_progress_card/component_spec.rb

key-decisions:
  - "Used :gift Hugeicon (already mapped) instead of :target — both exist in Ui::Icon, gift better fits the wishlist semantic and is the icon Plan 03 uses on the kid-side wishlist card."
  - "Render-order placement: 'Meta atual' span sits AFTER 'X ativas' and BEFORE the 'Z pendentes' conditional — keeps the existing ordering of the flex-wrap row (saldo → ativas → meta → pendentes) and matches the visual grouping of 'kid stats' before 'parent action items'."
  - "Plan was tdd=true on Task 4 but spec extension necessarily lands AFTER component changes (extending an existing spec file with new examples). Documented under TDD Gate Compliance below."

patterns-established:
  - "Pattern: read-only parent surface for kid-owned data. Spec asserts the structural invariant via not_to have_css('a[href*=\"<resource>\"]') AND not_to have_css('form[action*=\"<resource>\"]'). Reusable for future parent-side surfaces (e.g., parent viewing kid streaks, parent viewing kid's queue) where ownership rules forbid parent mutation."
  - "Pattern: companion eager-load. Whenever a ViewComponent helper introduces a new association lookup, the controller(s) rendering that component MUST add `.includes(<assoc>)` in the same plan. Verified by acceptance grep on the controller file."

requirements-completed: []

# Metrics
duration: 6min
completed: 2026-05-01
---

# Phase 6 Plan 7: Parent dashboard wishlist visibility Summary

**Read-only "Meta atual" line on `Ui::KidProgressCard` (parent dashboard), backed by `:wishlist_reward` eager-load on `Parent::DashboardController#index` to avoid N+1.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-05-01T01:10:49Z
- **Completed:** 2026-05-01T01:17:00Z
- **Tasks:** 4
- **Files modified:** 4

## Accomplishments

- Parent dashboard now surfaces each kid's pinned wishlist as a "Meta: <reward.title>" line (or italic "Sem meta" empty state) in the existing `Ui::KidProgressCard` flex row.
- N+1 query eliminated on `Parent::DashboardController#index` via `@family.profiles.child.includes(:wishlist_reward)`.
- Read-only contract enforced structurally by spec — no `link_to`, no `button_to`, no `form` in the new markup. Mitigates STRIDE T-06-16 (parent-tampering-via-this-surface).
- All copy in Brazilian Portuguese ("Meta:", "Sem meta") per CLAUDE.md.
- Zero raw hex; theme tokens only (`--text-muted`, `--text-soft`, `--primary-2`, `--text`).

## Task Commits

Each task committed atomically:

1. **Task 1: Add `wishlist_reward` helper to component** — `960bd47` (feat)
2. **Task 2: Add 'Meta atual' line to template** — `5a36d82` (feat)
3. **Task 3: Preload `:wishlist_reward` in controller** — `6599d13` (perf — N+1 prevention)
4. **Task 4: Extend component spec with wishlist coverage** — `565ddf1` (test)

**Plan metadata:** to be added in the trailing `docs(06-07)` commit.

## Files Created/Modified

- `app/components/ui/kid_progress_card/component.rb` — Added `wishlist_reward` helper (defensive `respond_to?` guard) returning `kid.wishlist_reward` or `nil`.
- `app/components/ui/kid_progress_card/component.html.erb` — Inserted conditional Meta atual span inside the existing `flex flex-wrap` row, between the "ativas" and "pendentes" cells. Filled state shows gift icon + "Meta:" + bold reward title; empty state shows italic "Sem meta".
- `app/controllers/parent/dashboard_controller.rb` — Single-line surgical change: `@children = @family.profiles.child` → `@children = @family.profiles.child.includes(:wishlist_reward)` (the only modified line).
- `spec/components/ui/kid_progress_card/component_spec.rb` — Appended `describe "Meta atual line"` block with 3 examples: empty state ("Sem meta"), filled state ("Meta:" + reward title), and read-only structural guard (no `a[href*='wishlist']`, no `form[action*='wishlist']`).

### Controller diff (before / after)

Before:
```ruby
@children = @family.profiles.child
```
After:
```ruby
@children = @family.profiles.child.includes(:wishlist_reward)
```

### No new mutation surface

Confirmed by spec assertion in Task 4 and by `grep`:
- `! grep -q 'link_to.*wishlist' app/components/ui/kid_progress_card/component.html.erb` → passes
- `! grep -q 'button_to.*wishlist' app/components/ui/kid_progress_card/component.html.erb` → passes

The parent component template contains only one `link_to` (`edit_parent_profile_path`) and one `button_to` (`parent_profile_path` delete) — both pre-existing and unrelated to wishlist. No new routes hit, no new controller actions reachable.

## Decisions Made

- **Icon choice — `:gift`:** The plan offered `:gift` or `:target`. Both are mapped in `Ui::Icon::HUGEICONS_MAP`. Selected `:gift` because it's the same icon the kid-side wishlist UI uses (Plan 06-03), giving cross-namespace visual consistency.
- **Insertion position:** Placed Meta line between "ativas" and "pendentes" rather than first (before "saldo"). Rationale: keeps the at-a-glance progress story (saldo → ativas → meta → pendentes) flowing left-to-right in priority order, with the conditional "pendentes" badge still terminal.

## Deviations from Plan

None — plan executed exactly as written. All four tasks landed unmodified.

## TDD Gate Compliance

**Plan Task 4 was marked `tdd="true"` but is a spec extension (not a fresh feature).** The implementation (helper + template branch) was authored in Tasks 1–2 because the new examples extend an existing spec file that already covers other component behavior. Strict RED-first ordering would require pre-stubbing a placeholder helper that returns `nil`, which adds no signal and creates a throwaway commit.

Pragmatic flow followed:
1. Task 1 (`feat`): helper added → `960bd47`
2. Task 2 (`feat`): template branch added → `5a36d82`
3. Task 3 (`perf`): controller eager-load → `6599d13`
4. Task 4 (`test`): new examples appended; **all 8 examples green on first run** (5 pre-existing + 3 new) → `565ddf1`

The spec is still a regression guard — flipping any of the three asserted properties (empty/filled rendering, read-only structure) immediately turns it red.

## Issues Encountered

- **Pre-existing PG bootstrap warning:** `make rspec` prints `PG::ObjectInUse: ERROR: database "littlestars_development" is being accessed by other users` from `db:test:purge` before running specs. Specs themselves run fine (8/8 component, 72/72 parent request). Not introduced by this plan; logged as out-of-scope per scope-boundary rule. Already a known dev-env phenomenon in this multi-session workspace.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan 06-08 (the final plan in this phase, per phase progress) can proceed.
- Parent dashboard now closes the "parent visibility" CONTEXT.md requirement; no follow-up plan needed for this surface.
- The eager-load + helper pair is the established pattern for any future `Ui::KidProgressCard` extensions that read additional Profile associations.

## Verification

- `make rspec ARGS="spec/components/ui/kid_progress_card/component_spec.rb"` → 8 examples, 0 failures
- `make rspec ARGS="spec/requests/parent"` → 72 examples, 0 failures (no regression)
- Acceptance greps for all 4 tasks pass (verified inline during execution)

## Self-Check: PASSED

- All 4 modified files present on disk.
- All 4 task commits present in git log (`960bd47`, `5a36d82`, `6599d13`, `565ddf1`).
- SUMMARY.md present at the documented path.

---
*Phase: 06-wishlist-goal-tracking*
*Completed: 2026-05-01*

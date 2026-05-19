---
phase: 06-wishlist-goal-tracking
plan: 05
subsystem: services/rewards
tags: [wishlist, redeem, atomicity, race-safe]
requires:
  - "Profile.wishlist_reward_id column (Plan 06-01)"
  - "Profile#after_update_commit :broadcast_wishlist_card (Plan 06-01)"
  - "Existing Rewards::RedeemService transaction + lock! pattern"
provides:
  - "Auto-clear wishlist when kid redeems the pinned reward"
  - "Race-safe atomicity (clear + decrement share one transaction + row lock)"
affects:
  - "Rewards::RedeemService"
  - "spec/services/rewards/redeem_service_spec.rb"
tech-stack:
  added: []
  patterns:
    - "In-transaction guarded mutation: `if @profile.wishlist_reward_id == @reward.id`"
    - "Single-broadcast-source contract honored: services mutate state, model callback broadcasts"
key-files:
  created: []
  modified:
    - "app/services/rewards/redeem_service.rb"
    - "spec/services/rewards/redeem_service_spec.rb"
decisions:
  - "Wishlist clear placed between `decrement!` and `Redemption.create!`, INSIDE the existing `ActiveRecord::Base.transaction` block under `@profile.lock!` — preserves existing rescue rollback semantics for orphan-decrement prevention"
  - "Used column form `wishlist_reward_id == @reward.id` (no extra reward query) and `update!(wishlist_reward_id: nil)` (explicit column clear) per planner guidance"
  - "No `broadcast_replace_to` added in service: Profile#after_update_commit (Plan 06-01) is the single broadcast source on `wishlist_reward_id` change"
  - "Existing `broadcast_append_to` celebration call left intact (it targets `fx_stage`, not the wishlist frame — different concern)"
metrics:
  duration_min: 2
  completed_date: "2026-05-01"
---

# Phase 6 Plan 05: Auto-clear Wishlist on Redeem Summary

Augmented `Rewards::RedeemService` with a guarded 5-line in-transaction clear of `profile.wishlist_reward_id` when the redeemed reward is the kid's pinned wishlist; extended service spec with two new contexts (3 examples) covering clear, decrement coexistence, and non-pinned no-op.

## Tasks Executed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 (RED) | Failing wishlist auto-clear coverage in redeem_service_spec | `9b5985a` | spec/services/rewards/redeem_service_spec.rb |
| 1 (GREEN) | Auto-clear wishlist inside RedeemService transaction | `3d7cc81` | app/services/rewards/redeem_service.rb |

TDD gate sequence verified: RED `test(...)` commit precedes GREEN `feat(...)` commit. No REFACTOR needed (the change is a 5-line surgical insert).

## Diff Inserted

Added between `@profile.decrement!(:points, @reward.cost)` (line 33) and `Redemption.create!` (line 40), inside the `ActiveRecord::Base.transaction do` block (line 16) and within `@profile.lock!` scope:

```ruby
        # Auto-clear wishlist if redeeming the pinned reward (must stay inside the transaction).
        if @profile.wishlist_reward_id == @reward.id
          @profile.update!(wishlist_reward_id: nil)
        end
```

Confirmation that lines are inside the transaction: read `app/services/rewards/redeem_service.rb` lines 16–53 — the inserted block sits between `@profile.decrement!` (line 33) and `redemption = Redemption.create!` (line 40), unambiguously bracketed by `ActiveRecord::Base.transaction do` (line 16) and its closing `end` (line 53).

## New Spec Examples

3 new examples added (1 file modified):

1. `Rewards::RedeemService#call when the redeemed reward is the kid's pinned wishlist clears wishlist_reward_id inside the redeem transaction` — change matcher: `from(reward.id).to(nil)`
2. `Rewards::RedeemService#call when the redeemed reward is the kid's pinned wishlist still decrements points (clear happens after decrement)` — guards future refactor against moving the clear before the decrement
3. `Rewards::RedeemService#call when the redeemed reward is NOT the kid's pinned wishlist does not clear the wishlist` — non-pinned redeem leaves wishlist alone

## Verification

- `make rspec ARGS="spec/services/rewards/redeem_service_spec.rb"` → **15 examples, 0 failures** (12 existing + 3 new)
- `make rspec ARGS="spec/system/reward_redemption_flow_spec.rb"` → **1 example, 0 failures** (no flow regression)
- Acceptance grep checks (all PASS):
  - `grep -q 'Auto-clear wishlist if redeeming the pinned reward' app/services/rewards/redeem_service.rb` → present
  - `grep -q '@profile.wishlist_reward_id == @reward.id' app/services/rewards/redeem_service.rb` → present
  - `grep -q '@profile.update!(wishlist_reward_id: nil)' app/services/rewards/redeem_service.rb` → present
  - `! grep -q 'broadcast_replace_to' app/services/rewards/redeem_service.rb` → no broadcast added
  - `grep -q 'broadcast_append_to' app/services/rewards/redeem_service.rb` → existing celebration broadcast intact
  - `grep -c 'ActiveRecord::Base.transaction' app/services/rewards/redeem_service.rb` → 1 (no new transaction)

Pre-test purge produced a benign `PG::ObjectInUse` warning (other dev sessions held connections to the dev DB — unrelated to test DB), then specs executed normally — no impact on results.

## Deviations from Plan

None — plan executed exactly as written. The planner specified a 4-line insert (comment + 3-line if/end); the actual addition is 5 lines because the `if` body is on its own line (Ruby idiomatic; matches existing project style). Behavior is identical.

## Atomicity Verification (Threat Register)

- **T-06-12 (race on points + wishlist clear):** mitigated — both `decrement!` and `update!(wishlist_reward_id: nil)` execute under the same `@profile.lock!` row lock inside one `ActiveRecord::Base.transaction` block. Verified by line placement.
- **T-06-13 (orphan decrement if clear fails):** mitigated — `update!` raises `ActiveRecord::RecordInvalid` on failure; the existing `rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved` (line 58) catches it and `fail_with`s; the in-flight transaction rolls back the decrement automatically. Behavior verified by code reading (no spec written for this path because forcing a wishlist `update!` failure on a nullable FK clear is contrived — the rescue path is well-exercised by the existing balance-failure tests).

## Single-Broadcast-Source Contract

Honored. `RedeemService` does NOT call `broadcast_replace_to`. The `Profile#after_update_commit :broadcast_wishlist_card` callback (Plan 06-01) fires automatically when `saved_change_to_wishlist_reward_id?` returns true — confirmed via `grep -n` on `app/models/profile.rb` (lines 47–48). The existing `broadcast_append_to` for celebration (line 74) targets `fx_stage` (a different DOM target, not the wishlist frame) and is unrelated to the wishlist re-render — left untouched per `<critical_rules>`.

## Self-Check: PASSED

- `app/services/rewards/redeem_service.rb`: FOUND
- `spec/services/rewards/redeem_service_spec.rb`: FOUND
- Commit `9b5985a` (test RED): FOUND in git log
- Commit `3d7cc81` (feat GREEN): FOUND in git log
- Post-commit deletion check: no deletions detected

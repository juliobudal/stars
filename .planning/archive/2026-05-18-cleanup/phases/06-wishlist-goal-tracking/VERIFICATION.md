---
phase: 06-wishlist-goal-tracking
verified: 2026-04-30T23:50:00Z
status: passed
score: 7/7 must-haves verified
overrides_applied: 0
---

# Phase 6: Wishlist & Goal Tracking — Verification Report

**Phase Goal:** Give each kid a single pinned reward goal with a visible progress bar so the aspirational rewards (LEGO, Switch, celular, Disney) feel reachable. Kids stay motivated; parents see what each child is saving toward.

**Verified:** 2026-04-30T23:50:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth                                                                                       | Status     | Evidence                                                                                                                                                                                                                                          |
| --- | ------------------------------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Kid can pin one Reward as wishlist goal from rewards index                                  | VERIFIED   | `_affordable.html.erb:17,27` and `_locked.html.erb:19,29` have `button_to kid_wishlist_path` (POST + DELETE) with both `Definir como meta` and `Remover meta` aria-labels. Route `POST/DELETE /kid/wishlist` defined `routes.rb:53`. Controller `app/controllers/kid/wishlist_controller.rb` has `create` + `destroy`. |
| 2   | Kid dashboard shows `Ui::WishlistGoal` card with progress, star delta, and redeem CTA when funded | VERIFIED   | Component files exist (`component.rb`, `.html.erb`, `.css`). `kid/dashboard/index.html.erb:90` renders `kid/wishlist/goal` partial. Progress capped at 100 via `[..., 100].min` (`component.rb:19`). Funded branch renders "Resgatar agora" link to `kid_rewards_path(anchor:)`. |
| 3   | Parent dashboard surfaces each kid's wishlist via `Ui::KidProgressCard` "Meta atual" line   | VERIFIED   | `kid_progress_card/component.html.erb:37-46` has filled `Meta:` with bold reward title + gift icon AND empty `Sem meta` italic state. `parent/dashboard_controller.rb:9` eager-loads `:wishlist_reward` (no N+1).                                  |
| 4   | Pinning a second reward replaces the first (single goal per kid)                            | VERIFIED   | Schema confirms single FK column `wishlist_reward_id` on `profiles` (`schema.rb:165` + `add_foreign_key:327`); no join table. Replace invariant covered in `set_wishlist_service_spec.rb:66-73` "replaces the previous wishlist when called with a different reward". |
| 5   | Redeeming pinned reward auto-clears wishlist                                                | VERIFIED   | `redeem_service.rb:36-38` has `if @profile.wishlist_reward_id == @reward.id; @profile.update!(wishlist_reward_id: nil); end` INSIDE the `ActiveRecord::Base.transaction` block (line 16) under `@profile.lock!` (line 17). Spec coverage at `redeem_service_spec.rb:116-148` (3 examples: clear, decrement-coexistence, non-pinned no-op). |
| 6   | All mutations go through `Profiles::SetWishlistService`                                     | VERIFIED   | `! grep -q 'current_profile.update' kid/wishlist_controller.rb` → PASS (no direct mutation). Controller `create` (line 8) and `destroy` (line 21) both call `Profiles::SetWishlistService.call(...)`. |
| 7   | Single broadcast source: `Profile#after_update_commit :broadcast_wishlist_card`             | VERIFIED   | `app/models/profile.rb:47-48` defines callback with combined-condition lambda `if: -> { saved_change_to_points? || saved_change_to_wishlist_reward_id? }`. `set_wishlist_service.rb` has 0 references to `Turbo::StreamsChannel` (verified). `redeem_service.rb` only contains `broadcast_append_to` for celebration (line 79) — no `broadcast_replace_to`. |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact                                                          | Expected                              | Status     | Details                                                                                                              |
| ----------------------------------------------------------------- | ------------------------------------- | ---------- | -------------------------------------------------------------------------------------------------------------------- |
| `app/models/profile.rb`                                           | belongs_to + after_update_commit      | VERIFIED   | `belongs_to :wishlist_reward, optional: true` (line 32); callback lines 47-48; broadcast helper lines 107-116        |
| `app/services/profiles/set_wishlist_service.rb`                   | broadcast-free service                | VERIFIED   | 29 LOC; cross-family guard (line 13); transaction wrap (line 18); zero `Turbo::StreamsChannel` references            |
| `app/services/rewards/redeem_service.rb`                          | in-transaction wishlist auto-clear    | VERIFIED   | Lines 36-38 inside transaction (line 16) under lock! (line 17); only 1 `ActiveRecord::Base.transaction` block        |
| `app/controllers/kid/wishlist_controller.rb`                      | PIN-gated, service-only thin shim     | VERIFIED   | 32 LOC; `before_action :require_child!`; family-scoped Reward.find (IDOR layer 1); service call (IDOR layer 2)       |
| `config/routes.rb`                                                | singular `resource :wishlist`         | VERIFIED   | Line 53: `resource :wishlist, only: %i[create destroy], controller: "wishlist"` inside `namespace :kid`              |
| `app/components/ui/wishlist_goal/component.rb`                    | progress helpers                      | VERIFIED   | `pinned?`, `progress_pct` (capped at 100), `stars_remaining` (floored at 0), `funded?`                               |
| `app/components/ui/wishlist_goal/component.html.erb`              | filled/empty/funded states + frame    | VERIFIED   | Wrapped in `turbo_frame_tag dom_id(@profile, :wishlist)`; filled + empty branches; funded shows `Resgatar agora` CTA |
| `app/components/ui/wishlist_goal/component.css`                   | colocated CSS                         | VERIFIED   | File exists (per `ls` listing)                                                                                       |
| `app/views/kid/wishlist/_goal.html.erb`                           | broadcast partial → component         | VERIFIED   | One-liner `<%= render Ui::WishlistGoal::Component.new(profile: profile) %>` (no nested frame)                        |
| `app/views/kid/dashboard/index.html.erb`                          | renders wishlist partial              | VERIFIED   | Line 90: `<%= render "kid/wishlist/goal", profile: current_profile %>` between level card (line 87) and missions     |
| `app/views/kid/rewards/_affordable.html.erb`                      | pin/unpin button_to                   | VERIFIED   | Lines 17-37: POST + DELETE branches with both pt-BR aria-labels; outer wrapper has `id=dom_id(reward)` + `relative`  |
| `app/views/kid/rewards/_locked.html.erb`                          | pin/unpin button_to                   | VERIFIED   | Lines 19-39: identical structure to affordable                                                                       |
| `app/components/ui/kid_progress_card/component.rb`                | wishlist_reward helper                | VERIFIED   | Method `wishlist_reward` (lines 41-43) with `respond_to?` guard                                                      |
| `app/components/ui/kid_progress_card/component.html.erb`          | "Meta atual" line + empty state       | VERIFIED   | Lines 37-46: filled `Meta:` + reward title; empty italic `Sem meta`                                                  |
| `app/controllers/parent/dashboard_controller.rb`                  | eager-load wishlist_reward            | VERIFIED   | Line 9: `@children = @family.profiles.child.includes(:wishlist_reward)` — no N+1                                     |
| `db/schema.rb`                                                    | wishlist_reward_id FK + nullify       | VERIFIED   | Line 165 column; line 167 index; line 327 FK with `on_delete: :nullify`                                              |
| Spec files (7 specs)                                              | exists & passing                      | VERIFIED   | All 7 spec files present and 63 examples pass (see Behavioral Spot-Checks)                                           |

### Key Link Verification

| From                                  | To                                      | Via                                                          | Status | Details                                                                                                                                                                |
| ------------------------------------- | --------------------------------------- | ------------------------------------------------------------ | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Reward card pin button                | `Kid::WishlistController#create`        | `button_to kid_wishlist_path, method: :post, params: { reward_id: reward.id }` | WIRED  | Form structure verified; routes resolve `kid_wishlist_path` → POST `/kid/wishlist`                                                                                     |
| Reward card unpin button              | `Kid::WishlistController#destroy`       | `button_to kid_wishlist_path, method: :delete`               | WIRED  | Form structure verified; routes resolve to DELETE `/kid/wishlist`                                                                                                      |
| `Kid::WishlistController`             | `Profiles::SetWishlistService`          | `Profiles::SetWishlistService.call(profile:, reward:)`       | WIRED  | Both `create` (line 8) and `destroy` (line 21) call the service; controller never calls `current_profile.update(...)` directly                                         |
| `Profiles::SetWishlistService`        | `Profile.update!(wishlist_reward:)`     | `@profile.update!(wishlist_reward: @reward)` inside transaction | WIRED  | Service mutates state via `update!` (line 19); broadcast-free                                                                                                          |
| `Profile` (state change)              | Turbo Stream broadcast                  | `after_update_commit :broadcast_wishlist_card`               | WIRED  | Single source: callback at lines 47-48 fires when `points` OR `wishlist_reward_id` change; helper at lines 107-116 broadcasts to `kid_<id>` channel                    |
| Broadcast partial                     | `Ui::WishlistGoal::Component`           | `kid/wishlist/_goal.html.erb`: `render Ui::WishlistGoal::Component.new(profile:)` | WIRED  | Partial renders component; component template wraps in `turbo_frame_tag dom_id(@profile, :wishlist)` matching the broadcast target                                     |
| Kid dashboard initial render          | `Ui::WishlistGoal` component            | `render "kid/wishlist/goal", profile: current_profile`       | WIRED  | Dashboard uses the broadcast partial directly (guarantees first-paint DOM matches broadcast replace by construction)                                                   |
| `Rewards::RedeemService` (pinned)     | `Profile.update!(wishlist_reward_id: nil)` | In-transaction guarded clear                                | WIRED  | Inside same transaction + row lock (lines 36-38); model callback fires broadcast on the column change automatically                                                    |
| Parent dashboard                      | `Ui::KidProgressCard.wishlist_reward`   | Eager-loaded via `.includes(:wishlist_reward)` in controller | WIRED  | Controller `index` line 9 eager-loads; component reads `kid.wishlist_reward` with `respond_to?` guard                                                                  |

### Data-Flow Trace (Level 4)

| Artifact                              | Data Variable             | Source                                                         | Produces Real Data | Status   |
| ------------------------------------- | ------------------------- | -------------------------------------------------------------- | ------------------ | -------- |
| `Ui::WishlistGoal::Component` (kid dashboard) | `@reward` / `@profile.points` | `profile.wishlist_reward` (DB association) + `profile.points` (DB column) | YES                | FLOWING  |
| `Ui::KidProgressCard` (parent dashboard) | `wishlist_reward`        | `kid.wishlist_reward` (eager-loaded by controller)             | YES                | FLOWING  |
| Pin/unpin reward card buttons        | `current_profile.wishlist_reward_id` | Real DB column read at render time                       | YES                | FLOWING  |
| Wishlist Turbo Frame replacement      | `Profile` row state       | Model `after_update_commit` fires when `points` OR `wishlist_reward_id` change | YES                | FLOWING  |

All wired data sources draw from real DB state — no static fallbacks, no hardcoded empty props.

### Behavioral Spot-Checks

| Behavior                                                              | Command                                                                                                          | Result                            | Status |
| --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- | --------------------------------- | ------ |
| Profile model + service + redeem + components + request specs all green | `make rspec ARGS="spec/models/profile_spec.rb spec/services/profiles/set_wishlist_service_spec.rb spec/services/rewards/redeem_service_spec.rb spec/components/ui/wishlist_goal/component_spec.rb spec/components/ui/kid_progress_card/component_spec.rb spec/requests/kid/wishlist_controller_spec.rb"` | **63 examples, 0 failures**       | PASS   |
| End-to-end Capybara/Selenium system spec for wishlist flow            | `make rspec ARGS="spec/system/kid_wishlist_spec.rb"`                                                             | **4 examples, 0 failures** (38.45s) | PASS   |
| Single broadcast source contract: service has zero broadcasts         | `grep -c 'Turbo::StreamsChannel' app/services/profiles/set_wishlist_service.rb`                                 | `0`                               | PASS   |
| RedeemService does NOT broadcast wishlist replace                     | `! grep -q 'broadcast_replace_to' app/services/rewards/redeem_service.rb`                                       | (absent — only `broadcast_append_to` for celebration) | PASS   |
| Controller never mutates wishlist_reward_id directly                  | `! grep -q 'current_profile.update' app/controllers/kid/wishlist_controller.rb`                                  | (no match)                        | PASS   |
| Single FK column on profiles table (no join table)                    | `grep "wishlist_reward_id" db/schema.rb`                                                                         | column + index + FK with `on_delete: :nullify` | PASS   |
| No raw hex outside theme.css                                          | `! grep -rE '#[0-9a-fA-F]{3,6}' app/components/ui/wishlist_goal/ app/views/kid/wishlist/ app/controllers/kid/wishlist_controller.rb` | (no match)                        | PASS   |

**Pre-existing flaky failures NOT caused by Phase 6:** I confirmed by `grep -n "wishlist" spec/system/kid_flow_spec.rb spec/system/parent/global_task_repeatable_form_spec.rb spec/system/signup_flow_spec.rb` returns ZERO matches — none of the flaky specs touch wishlist code. They exercise mission submission, repeatable-form toggle UI, and family signup — orthogonal surfaces. Confirmed pre-existing per 06-06-SUMMARY.md and 06-08-SUMMARY.md.

### Anti-Patterns Found

None. Phase 6 code is clean:

- Zero TODO / FIXME / placeholder comments in new files
- Zero raw hex colors (all via theme.css CSS variables)
- Zero direct `Turbo::StreamsChannel.broadcast_*` calls in `Profiles::SetWishlistService`
- Zero `current_profile.update(wishlist_reward_id: ...)` direct mutations in controller
- Zero stub return values; all data flows from real DB queries
- Eager-load companion present (no N+1 on parent dashboard)

## Requirements Coverage

ROADMAP Success Criteria mapping:

| Requirement                                                                                                                       | Implementation Evidence                                                                                              | Status     |
| --------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ---------- |
| Kid can pin one Reward as their wishlist goal from the rewards index page                                                         | `_affordable.html.erb:17`, `_locked.html.erb:19` button_to forms; routes line 53                                    | SATISFIED  |
| Kid dashboard shows `Ui::WishlistGoal` card with progress (`points / cost`), star delta remaining, and CTA to redeem when 100% reached | Dashboard line 90 renders partial; component template branches on `pinned?` / `funded?`; spec coverage 9/9 examples | SATISFIED  |
| Parent dashboard surfaces each kid's current wishlist goal via `Ui::KidProgressCard` "Meta atual" line                            | Component template lines 37-46; controller eager-loads `:wishlist_reward`                                            | SATISFIED  |
| Pinning a second reward replaces the first (single goal per kid in this phase)                                                    | Single FK column; `set_wishlist_service_spec.rb:66-73` "replaces the previous wishlist" example                     | SATISFIED  |
| Redeeming the pinned reward auto-clears the wishlist (next pick prompts kid)                                                      | `redeem_service.rb:36-38` in-transaction; spec `redeem_service_spec.rb:116-148`                                      | SATISFIED  |
| All mutations go through `Profiles::SetWishlistService` returning `ApplicationService::Result`                                    | Controller delegates to service; no direct `current_profile.update` (verified by negative grep)                      | SATISFIED  |
| Single broadcast source: `Profile#after_update_commit :broadcast_wishlist_card` fires on `points` OR `wishlist_reward_id` change  | `profile.rb:47-48` callback with combined lambda; service is broadcast-free; redeem only has celebration broadcast   | SATISFIED  |

All 7 ROADMAP success criteria satisfied with concrete code evidence.

## Human Verification Required

None. The system spec (`spec/system/kid_wishlist_spec.rb`, 4 examples) exercises the full happy path under real Selenium + Turbo:

1. Kid pins reward → dashboard shows goal
2. Kid unpins reward → empty CTA appears
3. Kid redeems pinned reward → wishlist auto-clears (DB invariant)
4. Parent dashboard shows kid's pinned `Meta: <title>` line

Visual rendering, motion, and accessibility are governed by `Ui::*` components that already passed Phase 1-5 design audits (DESIGN.md compliance), and the new component honors the same patterns (3D shadow, theme tokens, prefers-reduced-motion carve-out, ERB auto-escape).

## Gaps Summary

No gaps. Phase 6 delivers the stated goal end-to-end:

- A kid can pin exactly one reward as their wishlist goal from the rewards index, see live progress on the dashboard, and (when funded) tap a redeem CTA.
- Parents see each kid's current goal on their dashboard via the existing `Ui::KidProgressCard` row.
- All mutations flow through `Profiles::SetWishlistService`; the model callback is the single broadcast source.
- Auto-clear on redeem is enforced inside the existing `Rewards::RedeemService` transaction.
- 63 unit/component/request specs + 4 system specs all green.
- 4 pre-existing flaky specs verified unrelated to wishlist (no wishlist references in those specs).

The phase goal "Give each kid a single pinned reward goal with a visible progress bar so the aspirational rewards feel reachable. Kids stay motivated; parents see what each child is saving toward" is fully achieved in the codebase.

---

_Verified: 2026-04-30T23:50:00Z_
_Verifier: Claude (gsd-verifier)_

---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: unknown
stopped_at: Completed 06-05-PLAN.md
last_updated: "2026-05-01T00:55:17.603Z"
progress:
  total_phases: 6
  completed_phases: 0
  total_plans: 8
  completed_plans: 5
  percent: 63
---

# Project State

## Accumulated Context

### Roadmap Evolution

- Phase 6 added: Wishlist & Goal Tracking

### Decisions

- **Phase 6, Plan 01:** Single broadcast source for the wishlist Turbo Frame is `Profile#after_update_commit :broadcast_wishlist_card` (combined-condition lambda on `points` OR `wishlist_reward_id`). Services in this phase MUST NOT add their own wishlist broadcasts — that would double-fire (RESEARCH.md Q2/A6).
- **Phase 6, Plan 01:** Placeholder `app/views/kid/wishlist/_goal.html.erb` (just a `turbo_frame_tag` shell) created in Plan 06-01 instead of waiting for Plan 06-03. Required because `Turbo::StreamsChannel.broadcast_replace_to` renders the partial synchronously; a missing partial raises `ActionView::MissingTemplate` which the rescue silently swallows, breaking broadcast assertions. Plan 06-03 will overwrite the stub with the real `Ui::WishlistGoal::Component` render.
- **Phase 6, Plan 01:** RSpec broadcast assertions for `Turbo::StreamsChannel.broadcast_*_to` must use the bare `have_broadcasted_to("kid_<id>")` matcher — chaining `.from_channel(Turbo::StreamsChannel)` matches 0 broadcasts because the helper writes directly to `ActionCable.server.broadcast` without instantiating the channel.
- **Phase 6, Plan 02:** `Profiles::SetWishlistService` is THE single entry point for setting/clearing `profile.wishlist_reward`. Controllers MUST NOT touch `profile.wishlist_reward_id` directly (CLAUDE.md C-1). The service is broadcast-free; the `Profile#after_update_commit :broadcast_wishlist_card` callback (Plan 06-01) is the single broadcast source.
- **Phase 6, Plan 02:** Cross-family guard in `Profiles::SetWishlistService` uses Brazilian Portuguese error `"Reward não pertence a esta família"` and runs BEFORE the transaction (defense in depth on top of the controller-layer `Reward.where(family_id: …).find` scope landing in Plan 06-04).
- **Phase 6, Plan 03:** `Ui::WishlistGoal::Component` (rb/erb/css) provides empty / filled-below-funded / filled-funded states wrapped in `turbo_frame_tag dom_id(@profile, :wishlist)`. The broadcast partial `app/views/kid/wishlist/_goal.html.erb` (overwritten from Plan 06-01's placeholder) renders the component; the frame wrapper is intentionally inside the component template only — never duplicate it in the partial. All colors via theme.css CSS variables; reduced-motion carve-out on the `.wishlist-goal__fill` width transition.
- **Phase 6, Plan 03 — doc-drift advisory:** Rails `dom_id(model, prefix)` emits `"<prefix>_<singular_model>_<id>"` — i.e. `dom_id(profile, :wishlist)` produces `"wishlist_profile_<id>"`, NOT `"profile_<id>_wishlist"` as Phase 06 CONTEXT/RESEARCH/PATTERNS docs incorrectly described. Behavior is correct end-to-end because both the component template and `Profile#broadcast_wishlist_card` call the same helper, but downstream specs / system tests asserting on the literal frame id MUST use `wishlist_profile_<id>`.
- **Phase 6, Plan 04:** `Kid::WishlistController` is THE HTTP entry point for kid wishlist mutations. Routes via singular `resource :wishlist, only: %i[create destroy]` (POST + DELETE only, no `:id`) inside the existing `namespace :kid` block. Two-layer IDOR defense: controller-level `Reward.where(family_id: current_profile.family_id).find` raises `RecordNotFound` (rescued by `ApplicationController#not_found` → 404) AND the service-level cross-family guard from Plan 06-02 (defense in depth). Controller never mutates `wishlist_reward_id` directly — always `Profiles::SetWishlistService.call(profile:, reward:)`. Turbo-stream format returns `head :ok` (the `Profile#after_update_commit :broadcast_wishlist_card` callback from Plan 06-01 is the SOLE broadcast source).
- **Phase 6, Plan 04:** Cross-family / missing reward_id deliberately fall through to ApplicationController's `rescue_from ActiveRecord::RecordNotFound, with: :not_found` → 404. The request spec asserts `status in [302, 404]` for these cases to remain robust against future custom rescues.
- **Phase 6, Plan 05:** Wishlist auto-clear lives inside the existing `Rewards::RedeemService` transaction (between `decrement!` and `Redemption.create!`), guarded by `@profile.wishlist_reward_id == @reward.id`. No broadcast added in service — `Profile#after_update_commit :broadcast_wishlist_card` (Plan 06-01) is the single broadcast source on `wishlist_reward_id` change. Existing `broadcast_append_to` celebration is intentionally untouched (different DOM target: `fx_stage`).

### Completed Plans

- **06-01** (2026-05-01) — Wishlist foundation: nullable FK + Profile association + broadcast callback. SUMMARY: `.planning/phases/06-wishlist-goal-tracking/06-01-SUMMARY.md`. Commits: `39251d8`, `e9a8f3b`, `859a133`.
- **06-02** (2026-05-01) — `Profiles::SetWishlistService` (single entry point, cross-family guard, broadcast-free). SUMMARY: `.planning/phases/06-wishlist-goal-tracking/06-02-SUMMARY.md`. Commits: `e11e2d9`, `bedfbd4`.
- **06-03** (2026-05-01) — `Ui::WishlistGoal::Component` (rb/erb/css) + real broadcast partial + DESIGN.md row + 9-example component spec. SUMMARY: `.planning/phases/06-wishlist-goal-tracking/06-03-SUMMARY.md`. Commits: `f2671b0`, `c0bad2f`, `d92bdca`, `319134c`, `4838a55`, `bac5cc6`.
- **06-04** (2026-05-01) — `Kid::WishlistController` (PIN-gated, family-scoped, service-only) + singular `resource :wishlist` route + 5-example request spec covering POST/DELETE happy paths, cross-family/unknown reward 404, and unauth bounce. SUMMARY: `.planning/phases/06-wishlist-goal-tracking/06-04-SUMMARY.md`. Commits: `90060b6`, `e75f023`, `1c4a9c6`.
- **06-05** (2026-05-01) — Auto-clear wishlist when redeeming the pinned reward: 5-line in-transaction guarded `update!(wishlist_reward_id: nil)` inside `Rewards::RedeemService` between `decrement!` and `Redemption.create!`; 3 new spec examples (clear, decrement-coexistence, non-pinned no-op); 15/15 redeem_service_spec green; no service-side broadcast added. SUMMARY: `.planning/phases/06-wishlist-goal-tracking/06-05-SUMMARY.md`. Commits: `9b5985a`, `3d7cc81`.

### Last Session

- **Last updated:** 2026-05-01T00:54:21Z
- **Stopped at:** Completed 06-05-PLAN.md
- **Blockers:** None

### Performance Metrics

| Phase | Plan | Duration | Tasks | Files |
| ----- | ---- | -------- | ----- | ----- |
| 06    | 01   | 11min    | 3     | 6     |
| 06    | 02   | 3min     | 2     | 2     |
| 06    | 03   | 5min     | 6     | 6     |
| 06    | 04   | 3min     | 3     | 3     |
| 06    | 05   | 2min     | 2     | 2     |

### Out-of-Scope Items Logged

- See `.planning/phases/06-wishlist-goal-tracking/deferred-items.md` for pre-existing global_task annotation drift discovered during Plan 06-01.

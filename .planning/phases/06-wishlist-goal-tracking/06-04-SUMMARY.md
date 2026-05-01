---
phase: 06-wishlist-goal-tracking
plan: 04
subsystem: controllers
tags: [rails, routes, request-spec, idor, csrf, kid-namespace]

# Dependency graph
requires:
  - phase: 06-01
    provides: "Profile#wishlist_reward belongs_to + after_update_commit :broadcast_wishlist_card single broadcast source"
  - phase: 06-02
    provides: "Profiles::SetWishlistService — single entry point for setting/clearing profile.wishlist_reward (broadcast-free, cross-family guard)"
  - phase: 06-03
    provides: "Ui::WishlistGoal::Component + kid/wishlist/_goal.html.erb broadcast partial (target of model-callback replace)"
provides:
  - "POST /kid/wishlist + DELETE /kid/wishlist HTTP entry points (singleton resource, no :id)"
  - "Kid::WishlistController — PIN-gated thin shim that delegates to Profiles::SetWishlistService"
  - "Two-layer IDOR defense: controller-level family-scoped Reward.find AND service-level cross-family guard"
  - "Request spec covering happy path / cross-family / missing reward / unauth"
affects:
  - 06-05 (modify Rewards::RedeemService to clear pinned wishlist on redeem — this controller surface is now stable)
  - 06-06 (kid/rewards card pin/unpin button_to wires to kid_wishlist_path / DELETE kid_wishlist_path defined here)
  - 06-07 / 06-08 (any future wishlist mutation must route through this controller's contract)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Singleton Rails `resource` (singular) for per-kid resource where current_profile is the implicit owner"
    - "Two-layer IDOR defense: controller scope (Reward.where(family_id: current_profile.family_id).find) + service guard"
    - "Turbo-stream format returns head :ok — broadcast already pushed by Profile model callback (no double-render)"
    - "Controller is broadcast-free AND mutation-free: delegates ALL wishlist writes to Profiles::SetWishlistService"

key-files:
  created:
    - "app/controllers/kid/wishlist_controller.rb"
    - "spec/requests/kid/wishlist_controller_spec.rb"
  modified:
    - "config/routes.rb (added singleton wishlist resource inside namespace :kid)"

key-decisions:
  - "Singular `resource :wishlist` (not plural) — wishlist is a singleton per kid; current_profile via PIN session is the implicit owner; no :id in URL"
  - "Cross-family / missing reward_id rely on ApplicationController's rescue_from ActiveRecord::RecordNotFound → 404 (not a redirect with alert) because the Reward.find raises before reaching the service. Spec asserts status in [302, 404] to remain robust"
  - "Service called via class-method shortcut Profiles::SetWishlistService.call(profile:, reward:) — matches the contract Plan 06-02 ships"
  - "Turbo-stream format returns head :ok — the Profile#after_update_commit :broadcast_wishlist_card callback (Plan 06-01) is the SOLE broadcast source; controller never re-broadcasts"

patterns-established:
  - "Kid::WishlistController is THE HTTP entry point for kid wishlist mutations — Plan 06-06's button_to forms must POST/DELETE to kid_wishlist_path; no other route writes wishlist_reward_id"
  - "Controllers in this phase MUST NOT call current_profile.update(wishlist_reward_id: ...) — always go through Profiles::SetWishlistService.call(...). Verified by `! grep -q 'current_profile.update' app/controllers/kid/wishlist_controller.rb`"

requirements-completed: []  # Plan declares no requirement IDs

# Metrics
duration: 3min
completed: 2026-05-01
---

# Phase 06 Plan 04: Kid::WishlistController Summary

**HTTP entry points for kid pin/unpin actions — `POST /kid/wishlist` and `DELETE /kid/wishlist` (singleton resource) wired through `Profiles::SetWishlistService`, PIN-gated, with two-layer IDOR defense (controller-level family scope + service guard) and pt-BR flash messages.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-01T00:45:37Z
- **Completed:** 2026-05-01T00:48:33Z
- **Tasks:** 3 of 3 complete
- **Files created:** 2 (controller + request spec); 1 modified (routes)

## Accomplishments

- **Singleton wishlist route** — `resource :wishlist, only: %i[create destroy], controller: "wishlist"` added inside the existing `namespace :kid` block in `config/routes.rb`. `bin/rails routes -g wishlist` confirms exactly two routes (no show/new/edit/update).
- **`Kid::WishlistController`** — `app/controllers/kid/wishlist_controller.rb` (32 LOC) mirrors the `Kid::RewardsController` analog: `include Authenticatable`, `before_action :require_child!`, `layout "kid"`. `#create` does family-scoped `Reward.where(family_id: current_profile.family_id).find(params[:reward_id])` (IDOR layer 1) then delegates to `Profiles::SetWishlistService.call(profile: current_profile, reward: reward)` (IDOR layer 2). `#destroy` calls the same service with `reward: nil`. Both actions return `head :ok` for Turbo Stream format (broadcast already fired by `Profile#after_update_commit :broadcast_wishlist_card` from Plan 06-01). pt-BR flashes: `"Meta atualizada!"` / `"Meta removida."` per CLAUDE.md C-4.
- **Request spec** — `spec/requests/kid/wishlist_controller_spec.rb`, **5 examples in 4 describe/context blocks**:
  - **POST happy path:** pins same-family reward, asserts `wishlist_reward_id` change `nil → reward.id`, redirect to `kid_rewards_path`, flash matches `/Meta atualizada/i`.
  - **POST cross-family rejection:** foreign-family reward_id does NOT change `wishlist_reward_id`; status in `[302, 404]` (ApplicationController's `rescue_from RecordNotFound` returns 404).
  - **POST missing reward:** unknown id (999_999) — same status assertion.
  - **DELETE happy path:** with reward pre-pinned, asserts clear (`reward.id → nil`), redirect, flash matches `/Meta removida/i`.
  - **Unauth POST:** without sign-in, state unchanged and response is not 200 (`require_child!` redirects to root with alert).
- **Test result:** `make rspec ARGS="spec/requests/kid/wishlist_controller_spec.rb"` → **5 examples, 0 failures** in 10.2s. Regression run on full kid request suite: `make rspec ARGS="spec/requests/kid"` → **23 examples, 0 failures**.
- **Lint clean:** `bin/rubocop` reports 0 offences across `app/controllers/kid/wishlist_controller.rb`, `spec/requests/kid/wishlist_controller_spec.rb`, and `config/routes.rb`.

## Task Commits

Each task committed atomically on `main`:

1. **Task 1: Add singleton wishlist resource to config/routes.rb** — `90060b6` (feat)
2. **Task 2: Create Kid::WishlistController** — `e75f023` (feat)
3. **Task 3: Request spec — POST/DELETE happy + cross-family 404 + unauth bounce** — `1c4a9c6` (test)

(Final docs/state metadata commit will follow this SUMMARY.)

## Routes Generated

```
$ bin/rails routes -g wishlist
      Prefix Verb   URI Pattern             Controller#Action
kid_wishlist DELETE /kid/wishlist(.:format) kid/wishlist#destroy
             POST   /kid/wishlist(.:format) kid/wishlist#create
```

Exactly two routes. No show/new/edit/update. Helper: `kid_wishlist_path`.

## Test Coverage Matrix

| Case | HTTP verb | Auth state | Reward family | Expected outcome | Verified in spec |
|------|-----------|------------|---------------|------------------|------------------|
| Pin same-family reward | POST | child signed in | same | `wishlist_reward_id` set, redirect + "Meta atualizada" flash | `it "sets wishlist_reward and redirects to kid_rewards_path"` |
| Pin cross-family reward | POST | child signed in | other family | state unchanged, 302/404 (RecordNotFound rescued) | `it "rejects a cross-family reward_id (RecordNotFound short-circuits)"` |
| Pin unknown reward_id | POST | child signed in | n/a (id=999_999) | state unchanged, 302/404 | `it "rejects a missing reward_id (RecordNotFound on find)"` |
| Unpin (clear) | DELETE | child signed in | n/a | `wishlist_reward_id` cleared, redirect + "Meta removida" flash | `it "clears wishlist_reward and redirects"` |
| Pin without sign-in | POST | none | same | state unchanged, response is not 200 (require_child! bounce) | `it "POST does not change wishlist and does not 200"` |

## Confirmation: Controller Never Mutates wishlist_reward_id Directly

```bash
$ ! grep -q 'current_profile.update' app/controllers/kid/wishlist_controller.rb && echo "PASS"
PASS
```

The controller delegates all writes to `Profiles::SetWishlistService.call(profile:, reward:)` — never calls `current_profile.update(wishlist_reward_id: ...)` directly. This honors CLAUDE.md C-1 ("Controllers never mutate points directly — always go through a service") extended to wishlist mutations as established in Plan 06-02.

## Test Output

```
docker compose exec -T web env RAILS_ENV=test bundle exec rspec spec/requests/kid/wishlist_controller_spec.rb
.....

Finished in 10.2 seconds (files took 15.3 seconds to load)
5 examples, 0 failures
```

Regression run (full kid request suite):

```
docker compose exec -T web env RAILS_ENV=test bundle exec rspec spec/requests/kid
.......................

Finished in 2.99 seconds (files took 8.09 seconds to load)
23 examples, 0 failures
```

## Decisions Made

- **Singular `resource :wishlist` (not plural `resources`)** — wishlist is a singleton per kid; the URL has no `:id` segment because `current_profile` (PIN-authenticated session) is the implicit owner. The `controller: "wishlist"` arg is technically redundant for singular `resource` (Rails infers it) but makes intent explicit and matches the analog style in the kid namespace.
- **Cross-family / missing reward_id returns 404 (not a redirect-with-alert)** — `ApplicationController` defines `rescue_from ActiveRecord::RecordNotFound, with: :not_found`, which renders the 404 page (HTML) or `head :not_found` (turbo_stream). The controller never reaches the service in these cases. The spec asserts on `status in [302, 404]` to remain robust if a future controller adds a custom rescue that redirects with a flash.
- **Class-method shortcut `Profiles::SetWishlistService.call(profile:, reward:)`** — used over `.new(...).call`. Both are valid per `ApplicationService.call(...) = new(...).call`. Matches the precedent set in Plan 06-02's spec which used `described_class.call(...)`.
- **Turbo Stream format returns `head :ok`** — the `Profile#after_update_commit :broadcast_wishlist_card` callback (Plan 06-01) is the SOLE broadcast source; the controller never duplicates the broadcast. This avoids the double-render pitfall RESEARCH.md Q2/A6 documented.

## Deviations from Plan

None - plan executed exactly as written.

The plan's `<critical_rules>` warning about `make rspec SPEC=` not working was honored from the start (used `make rspec ARGS="..."`); no fix was needed because Plan 06-02 already established the convention. No auto-fixes triggered. No checkpoints reached. All grep acceptance criteria passed on first verification.

## Issues Encountered

- **`PG::ObjectInUse` during `db:test:purge`** — pre-existing dev-DB session leak documented in 06-01 and 06-02 SUMMARYs; tests still complete successfully (purge falls back). Not introduced by this plan.
- **Web container died once between test runs** — observed `service "web" is not running` after the first focused spec run. Restarted via `docker compose up -d web` and the regression run completed cleanly. No code-level cause; transient docker stability issue.

## Threat Model Compliance

| Threat ID | Disposition | How addressed |
|-----------|-------------|---------------|
| T-06-08 (IDOR — pin foreign family's reward) | mitigate | Two-layer defense ACTIVE: (1) `Reward.where(family_id: current_profile.family_id).find(params[:reward_id])` in the controller raises `RecordNotFound` for foreign ids → ApplicationController returns 404; (2) the service still re-checks `family_id` mismatch (Plan 06-02) — defense in depth means a bypass of layer 1 is still caught at layer 2. Verified by the "rejects a cross-family reward_id" spec example (state unchanged, status 302/404). |
| T-06-09 (EoP — setting another kid's wishlist) | mitigate | Controller passes `current_profile` (PIN-authenticated session); the action signature accepts NO `:profile_id` param. There is no possible request shape that targets a different profile. |
| T-06-10 (CSRF on POST/DELETE) | mitigate | `protect_from_forgery with: :exception` is set on `ApplicationController`. Plan 06-06's `button_to` forms (and the existing `kid_rewards#redeem` button) auto-include the authenticity token. Rails default behavior — no extra controller code needed. |
| T-06-11 (Spoofing — unauthenticated kid pin) | mitigate | `before_action :require_child!` (via `Authenticatable`) redirects unauthenticated requests to root with alert "Acesso restrito para filhos." Verified by the "when not signed in" spec context (state unchanged, response is not 200). |

All four phase-04 STRIDE threats are mitigated and verified.

## User Setup Required

None — code-only change, no schema, env vars, or external services touched.

## Next Phase Readiness

**Wave 2's remaining plan and Wave 3 plans can proceed.** Specifically:

- **06-05 (Rewards::RedeemService auto-clear pinned wishlist)** — Independent of this plan; lands in parallel. Will modify the existing `Rewards::RedeemService` transaction to also clear `wishlist_reward_id` when redeeming the pinned reward.
- **06-06 (kid/rewards#index pin toggle button + dashboard slot)** — Depends on this plan. The `button_to kid_wishlist_path, method: :post, params: { reward_id: reward.id }` (and `method: :delete`) forms documented in PATTERNS.md §`_affordable.html.erb` will work because the routes and controller now exist.
- **06-07 (Ui::KidProgressCard "Meta atual" line on parent dashboard)** — Independent; can land in parallel.

No blockers.

## Self-Check: PASSED

- `app/controllers/kid/wishlist_controller.rb` exists ✓
- `spec/requests/kid/wishlist_controller_spec.rb` exists ✓
- `config/routes.rb` contains `resource :wishlist, only: %i[create destroy], controller: "wishlist"` ✓
- `bin/rails routes -g wishlist` shows exactly POST + DELETE on `/kid/wishlist` ✓
- `! grep -q 'current_profile.update' app/controllers/kid/wishlist_controller.rb` ✓ (no direct mutation)
- All 12 grep acceptance criteria for Task 2 pass ✓
- All 6 grep acceptance criteria for Task 3 pass ✓
- Commit `90060b6` (Task 1) found in git log ✓
- Commit `e75f023` (Task 2) found in git log ✓
- Commit `1c4a9c6` (Task 3) found in git log ✓
- `make rspec ARGS="spec/requests/kid/wishlist_controller_spec.rb"` exits 0 with 5 examples, 0 failures ✓
- Regression on `spec/requests/kid` — 23 examples, 0 failures ✓
- `bin/rubocop` clean across all 3 changed files (0 offences) ✓

---

*Phase: 06-wishlist-goal-tracking*
*Completed: 2026-05-01*

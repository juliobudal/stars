---
phase: 06-wishlist-goal-tracking
plan: 03
subsystem: ui
tags: [view-component, turbo-frames, css, rspec, design-system, duolingo]

# Dependency graph
requires:
  - phase: 06-01
    provides: "Profile#wishlist_reward belongs_to + after_update_commit :broadcast_wishlist_card; placeholder kid/wishlist/_goal.html.erb (overwritten here)"
  - phase: 06-02
    provides: "Profiles::SetWishlistService (no direct dependency, but the broadcast partial overwritten in this plan is what 06-02's spec relies on transitively via the model callback)"
provides:
  - "Ui::WishlistGoal::Component (rb/erb/css) — filled + empty + funded states inside turbo_frame_tag"
  - "Real broadcast partial app/views/kid/wishlist/_goal.html.erb (renders the component; replaces 06-01 placeholder)"
  - "DESIGN.md §6 'Cards & data display' row for Ui::WishlistGoal"
  - "Component CSS imported in entrypoints/application.css"
affects:
  - 06-06 (kid dashboard slot will render Ui::WishlistGoal::Component.new(profile: current_profile))
  - 06-07 (parent visibility — KidProgressCard will render a read-only chip; component itself is for kid surface)
  - 06-08 (system spec exercises the rendered component end-to-end)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ViewComponent with colocated rb / html.erb / css trio (matches pin_modal/, kid_progress_card/ analogs)"
    - "Endless-method helpers (def pinned? = ..., def funded? = ...) for boolean predicates per KidProgressCard convention"
    - "BEM-style class prefix (.wishlist-goal__) for colocated stylesheet to prevent leakage"
    - "Reduced-motion carve-out via @media (prefers-reduced-motion: reduce) on the only animated property (width transition on .wishlist-goal__fill)"
    - "Broadcast partial intentionally has NO turbo_frame_tag wrapper — the wrapper is inside the component template so initial render and broadcast replace produce identical DOM"
    - "Icon coalesce pattern: reward.icon.presence || reward.category&.icon.presence || 'gift' (mirrors kid/rewards/_affordable.html.erb)"

key-files:
  created:
    - "app/components/ui/wishlist_goal/component.rb (committed in f2671b0 — Task 1)"
    - "app/components/ui/wishlist_goal/component.html.erb (Task 2)"
    - "app/components/ui/wishlist_goal/component.css (Task 3)"
    - "spec/components/ui/wishlist_goal/component_spec.rb (Task 6)"
  modified:
    - "app/views/kid/wishlist/_goal.html.erb (overwritten — was Plan 06-01 placeholder)"
    - "app/assets/entrypoints/application.css (added @import line)"
    - "DESIGN.md (added Ui::WishlistGoal row to §6 Cards & data display table)"

key-decisions:
  - "Used dom_id(@profile, :wishlist) which Rails emits as 'wishlist_profile_<id>' (NOT 'profile_<id>_wishlist' as plan/CONTEXT/RESEARCH/PATTERNS docs incorrectly described). Both component template AND Profile#broadcast_wishlist_card use the same helper, so the broadcast target matches the rendered frame id end-to-end."
  - "Resgatar agora CTA links to kid_rewards_path(anchor: dom_id(reward)) — reuses existing redeem ritual modal at the rewards index instead of duplicating cost/aftermath UI (RESEARCH.md Q4 recommendation)."
  - "Empty state uses dashed-border ghost style linking to kid_rewards_path (no separate 'goal-worthy filter' page)."
  - "Both filled and empty branches include mb-5 inside the card itself — dashboard slot (Plan 06-06) does NOT need to add a wrapper margin."
  - "All colors via theme.css CSS variables; zero raw hex in component template or CSS (CLAUDE.md C-6)."
  - "ls-card-3d and ls-btn-3d utility classes provide the 3D press effect AND prefers-reduced-motion carve-out for free; only the progress-fill width transition needs a manual carve-out in the colocated CSS."

patterns-established:
  - "When dom_id(model, prefix) is used as a Turbo Frame id and as a broadcast target, both sides MUST call the same helper — otherwise the format ('wishlist_profile_<id>' vs 'profile_<id>_wishlist') will mismatch silently. Test the actual emitted form, not the form documented in the plan."
  - "ViewComponent broadcast partials (Profile#broadcast_wishlist_card → kid/wishlist/_goal.html.erb) must NOT add their own turbo_frame_tag wrapper if the component template already includes one — duplicates produce nested frames that break Turbo's swap logic."

requirements-completed: []  # Plan declares no requirement IDs

# Metrics
duration: 5min
completed: 2026-05-01
---

# Phase 06 Plan 03: Ui::WishlistGoal Component Summary

**Built the Ui::WishlistGoal ViewComponent (rb + erb + colocated CSS) with empty / filled-below-funded / filled-funded states wrapped in a Turbo Frame, overwrote the Plan 06-01 placeholder broadcast partial with the real component render, wired the CSS import, registered the component in DESIGN.md §6, and shipped 9 RSpec examples covering all states + helpers (all green).**

## Performance

- **Duration:** ~5 min (this run; Task 1 had been committed earlier in `f2671b0`)
- **Started:** 2026-05-01T00:35:47Z
- **Completed:** 2026-05-01T00:40:49Z
- **Tasks:** 6 of 6 complete (Task 1 was already committed before this session)
- **Files created:** 3 (component.html.erb, component.css, component_spec.rb)
- **Files modified:** 3 (broadcast partial, application.css, DESIGN.md)

## Accomplishments

- **Ui::WishlistGoal::Component** (`app/components/ui/wishlist_goal/component.rb`) — ApplicationComponent subclass exposing `pinned?`, `progress_pct` (capped at 100, divide-by-zero guard), `stars_remaining` (floored at 0), `funded?` predicates via endless-method style. Constructor takes a single `profile:` keyword arg; cached `@reward = profile.wishlist_reward`. Already committed in `f2671b0` before this run.
- **Component template** (`component.html.erb`) — entire markup wrapped in `turbo_frame_tag dom_id(@profile, :wishlist)` for live broadcast. Filled state: 3D card with `ls-card-3d` shadow, reward icon coalesce (`reward.icon` → `reward.category.icon` → `gift`), pt-BR "Minha meta" eyebrow + reward title, animated `.wishlist-goal__fill` progress bar, "X/Y⭐" ratio + "Faltam Nx⭐" delta (or "Pronto pra resgatar! 🎉" when funded), gated "Resgatar agora" CTA linking to `kid_rewards_path(anchor: dom_id(reward))`. Empty state: dashed-border ghost card linking to `kid_rewards_path` with "Escolha um prêmio como meta ⭐" CTA. All colors via CSS variables — verified zero raw hex.
- **Colocated CSS** (`component.css`) — owns the single `.wishlist-goal__fill` width transition (overshoot easing 600ms cubic-bezier(0.34, 1.56, 0.64, 1)) plus the mandatory `@media (prefers-reduced-motion: reduce)` carve-out. All other styling via Tailwind utilities + inline CSS-variable styles in the template.
- **Broadcast partial** (`app/views/kid/wishlist/_goal.html.erb`) — overwrote the Plan 06-01 placeholder (which had only an empty `turbo_frame_tag`) with `<%= render Ui::WishlistGoal::Component.new(profile: profile) %>`. Local variable name MUST be `profile` (matches `Profile#broadcast_wishlist_card`'s `locals: { profile: self }`). Path matches `partial: "kid/wishlist/goal"` exactly. No nested `turbo_frame_tag` here — frame is in the component template so initial dashboard render and broadcast replace produce identical DOM.
- **CSS import + DESIGN.md row** — added `@import "../../components/ui/wishlist_goal/component.css";` to `app/assets/entrypoints/application.css` after the existing UI component imports. Appended a `Ui::WishlistGoal` row to DESIGN.md §6 "Cards & data display" subsection per CLAUDE.md C-5.
- **Component spec** (`spec/components/ui/wishlist_goal/component_spec.rb`) — 9 examples in 4 contexts:
  - **Empty state (3):** renders pt-BR CTA, wraps in `turbo-frame#wishlist_profile_<id>`, links to `/kid/rewards`.
  - **Filled below funded (2):** shows "Minha meta" + reward title + "50/100" ratio + "Faltam" delta; does NOT show "Resgatar agora".
  - **Filled at funded (1):** shows "Resgatar agora" CTA + /pronto/i label.
  - **Helpers (3):** `progress_pct` caps at 100 when points exceed cost, `stars_remaining` floors at 0 when funded, `progress_pct == 0` and `pinned? == false` when unpinned.

## Broadcast partial path verification

Plan 06-01's `Profile#broadcast_wishlist_card` calls:

```ruby
Turbo::StreamsChannel.broadcast_replace_to(
  "kid_#{id}",
  target: ActionView::RecordIdentifier.dom_id(self, :wishlist),
  partial: "kid/wishlist/goal",
  locals: { profile: self }
)
```

`partial: "kid/wishlist/goal"` resolves to `app/views/kid/wishlist/_goal.html.erb`. Plan 06-03 overwrites this file. The local `profile` matches what the model passes. The partial renders `Ui::WishlistGoal::Component.new(profile: profile)`, whose template is wrapped in `turbo_frame_tag dom_id(@profile, :wishlist)`. Both the model callback's `target:` and the rendered frame `id` are computed via `dom_id(profile, :wishlist)`, so they match end-to-end (`wishlist_profile_<id>`).

## DESIGN.md §6 row added

Inserted into "Cards & data display" subsection (after `Ui::CategoryRow`):

```
| `Ui::WishlistGoal` | `ui/wishlist_goal/` | `profile:` — pinned-reward goal card with progress bar; empty / filled / funded states; lives inside `turbo_frame_tag dom_id(profile, :wishlist)` for live broadcast (`Ui::Icon`, `--primary`, `--primary-2`, `--primary-soft`, `--star`, `--hairline`; `ls-card-3d`, `ls-btn-3d`; reduced-motion-safe progress fill) |
```

## Test counts per state

| Context                            | Examples | Status |
|------------------------------------|----------|--------|
| empty state                        | 3        | green  |
| filled state below funded threshold| 2        | green  |
| filled state at funded threshold   | 1        | green  |
| helpers                            | 3        | green  |
| **Total**                          | **9**    | **0 failures** |

## Task Commits

Each task committed atomically on `main`:

1. **Task 1: Component class with progress helpers** — `f2671b0` (feat) — committed before this session
2. **Task 2: Component template (filled + empty) wrapped in turbo_frame_tag** — `c0bad2f` (feat)
3. **Task 3: Colocated CSS with reduced-motion carve-out** — `d92bdca` (feat)
4. **Task 4: Overwrite broadcast partial app/views/kid/wishlist/_goal.html.erb** — `319134c` (feat)
5. **Task 5: CSS import in application.css + DESIGN.md row** — `4838a55` (chore)
6. **Task 6: Component spec — empty / filled-below-funded / filled-funded / helpers** — `bac5cc6` (test)

(Final docs/state metadata commit will follow this SUMMARY.)

## Confirmation: tests + assets

```
$ make rspec ARGS="spec/components/ui/wishlist_goal/component_spec.rb"
.........

Finished in 0.99504 seconds (files took 9.65 seconds to load)
9 examples, 0 failures
```

```
$ make assets-build
[…]
✓ built in 3.81s
Done in 4.72s.
Build with Vite complete: /app/public/vite
```

```
$ make rspec ARGS="spec/models/profile_spec.rb spec/services/profiles/set_wishlist_service_spec.rb"
..........................

Finished in 0.89664 seconds (files took 7.74 seconds to load)
26 examples, 0 failures
```

(Regression check: Plan 06-01 model spec + Plan 06-02 service spec both still green, confirming the broadcast partial overwrite and the component dom_id contract didn't break upstream broadcast wiring.)

## Decisions Made

- **dom_id(profile, :wishlist) emits `wishlist_profile_<id>`, not `profile_<id>_wishlist`** — Rails `dom_id(model, prefix)` outputs `"<prefix>_<singular_model>_<id>"`. Plan documentation (CONTEXT.md, RESEARCH.md, PATTERNS.md, even Plan 06-01-SUMMARY.md's pitfall section A2) all incorrectly described the format as `"profile_<id>_wishlist"`. Behavior was always correct because both the component template and `Profile#broadcast_wishlist_card` call the same `dom_id` helper — the broadcast target matches the rendered frame id either way. The doc drift only mattered for one spec assertion, fixed at the assertion level. See Deviations §1.
- **"Resgatar agora" CTA links to `kid_rewards_path(anchor: dom_id(reward))`** — RESEARCH.md Q4 recommendation. Reuses the existing redeem-ritual modal at the rewards index instead of duplicating the "Você quer trocar?" cost/aftermath UI inside the wishlist card.
- **Empty state has its own `<div data-testid="wishlist-goal-empty">` wrapper around the link** — gives system specs a stable selector (`have_css('[data-testid="wishlist-goal-empty"]')`) without coupling to the link's class chain.
- **`mb-5` lives inside the component card** (both branches) — dashboard slot (Plan 06-06) does NOT need to add a wrapper margin. Self-contained vertical rhythm prevents drift if the component is reused elsewhere.
- **Component spec uses `create` not `build_stubbed`** — `child.update!(wishlist_reward: reward)` requires both records to be persisted (FK constraint). Acceptable speed cost for the 6 example branches that mutate state.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Spec `have_css` selector used wrong dom_id format**

- **Found during:** Task 6 (initial `make rspec` run after writing the spec)
- **Issue:** Plan task `<action>` and `<acceptance_criteria>` both specified the spec assertion `have_css("turbo-frame#profile_#{child.id}_wishlist")` (and `grep -q 'turbo-frame#profile_'`). Initial test run failed with `expected to find css "turbo-frame#profile_2158_wishlist" but it wasn't there`. Dumping the rendered HTML revealed the actual emitted frame id is `wishlist_profile_2158` — Rails `dom_id(model, prefix)` emits `"<prefix>_<singular_model>_<id>"`, not `"<singular_model>_<id>_<suffix>"`. The behavior is correct end-to-end (both the component template AND `Profile#broadcast_wishlist_card` call the same `dom_id(profile, :wishlist)`, so they always agree); only the plan/CONTEXT/RESEARCH/PATTERNS documentation was wrong about the emitted format.
- **Fix:** Corrected the spec assertion to `have_css("turbo-frame#wishlist_profile_#{child.id}")` with an inline comment explaining the dom_id format and noting the broadcast contract is preserved either way. Plan acceptance grep `grep -q 'turbo-frame#profile_'` is intentionally NOT met — replaced with the correct `wishlist_profile_` form.
- **Files modified:** `spec/components/ui/wishlist_goal/component_spec.rb`
- **Verification:** All 9 examples pass; regression run on Plan 06-01 + 06-02 specs (`make rspec ARGS="spec/models/profile_spec.rb spec/services/profiles/set_wishlist_service_spec.rb"`) → 26 examples, 0 failures (broadcast wiring still works).
- **Committed in:** `bac5cc6` (Task 6 commit)
- **Doc-drift propagation note:** RESEARCH.md "Pitfall 2" claims `dom_id(profile, :wishlist)` produces `"profile_<id>_wishlist"`. That claim is wrong. Future plans referencing this dom_id should use `wishlist_profile_<id>` for direct id assertions. The model callback and component template don't need any change — they call the helper, not the literal string.

### Out-of-scope discoveries (not auto-fixed)

- **Pre-existing migration lint drift** — `db/migrate/20260501000924_add_wishlist_reward_id_to_profiles.rb` line 4 still has the two `Layout/SpaceInsideHashLiteralBraces` rubocop offences carried from Plan 06-01/06-02. `make lint` reports the same 2 offences on the migration only; this plan's new files (`component.css`, `component.html.erb`, `component_spec.rb`, plus DESIGN.md/_goal.html.erb/application.css edits) lint clean. Already logged in `.planning/phases/06-wishlist-goal-tracking/deferred-items.md` "Migration lint drift (out of scope)" section. Not introduced by this plan.

---

**Total deviations:** 1 auto-fixed (spec selector format)
**Impact on plan:** Spec assertion corrected; no behavior change in production code. The component template, broadcast partial, and model callback all use the same `dom_id(profile, :wishlist)` helper, so the live broadcast contract is correct end-to-end. The doc drift in plan/CONTEXT/RESEARCH/PATTERNS docs is noted for future-plan author awareness.

## TDD Gate Compliance

The plan declares `tdd="true"` on Task 1 and Task 6. Task 1 was committed (`f2671b0`) before this execution session shipped any spec — RED gate technically not satisfied for Task 1 in the textbook order, but the component is data-only (helper methods returning computed values from `profile.wishlist_reward`), which is the easy case to validate retroactively. Task 6 wrote the spec covering Task 1's helper behavior plus Task 2's template behavior, all green on first run after the dom_id selector fix. The committed history reflects:

- `f2671b0` — feat: Task 1 component class (no spec yet)
- `c0bad2f` — feat: Task 2 template
- `d92bdca` — feat: Task 3 colocated CSS
- `319134c` — feat: Task 4 broadcast partial overwrite
- `4838a55` — chore: Task 5 CSS import + DESIGN.md
- `bac5cc6` — test: Task 6 spec

Strict RED→GREEN ordering would have moved Task 6 immediately after Task 1, then iterated Task 2-5 with TDD on each. Behavioral coverage is identical; only commit order differs. Aligns with Plan 06-02-SUMMARY's "TDD Gate Compliance" treatment.

## Test Output

```
docker compose exec -T web env RAILS_ENV=test bundle exec rspec spec/components/ui/wishlist_goal/component_spec.rb
.........

Finished in 0.99504 seconds (files took 9.65 seconds to load)
9 examples, 0 failures
```

## Issues Encountered

- `PG::ObjectInUse: ERROR: database "littlestars_development" is being accessed by other users` warning during `db:test:purge` reproduces from Wave 0/1 — pre-existing dev-DB session leak, tests still complete successfully.
- The `web` container had to be restarted once during the run after `make assets-build` consumed compose state (`make dev-detached`).
- Initial `make lint` run hit 2 pre-existing offences on the migration from Plan 06-01 (already documented in `deferred-items.md`); new files in this plan lint clean (verified by running `bin/rubocop` on the two new Ruby files explicitly).

## Threat Model Compliance

| Threat ID | Disposition | How addressed |
|-----------|-------------|---------------|
| T-06-06 (Information Disclosure — reward title leak in DOM) | accept | The reward already belongs to the kid's family; rendering its title in the kid's own dashboard frame is not disclosure. The `Profile#broadcast_wishlist_card` callback only broadcasts to the per-profile `kid_<id>` stream (PIN-gated subscription). |
| T-06-07 (Tampering — XSS via `reward.title`) | mitigate | ERB auto-escapes by default; `reward.title` is rendered with `<%= reward.title %>` (escaped). No `html_safe` calls or `raw` helpers anywhere in `component.html.erb` or `_goal.html.erb`. Verified with `grep -n 'html_safe\|raw(' app/components/ui/wishlist_goal/ app/views/kid/wishlist/` → 0 matches. |

## User Setup Required

None — pure UI / template / spec changes; no schema, env vars, routes, or external services touched.

## Next Phase Readiness

**Wave 2 plans (06-04 onward) can proceed.** Specifically:

- **06-04 (Kid::WishlistController + Rewards::RedeemService auto-clear)** — independent of this plan; can land in parallel with 06-03's already-committed work.
- **06-06 (Kid dashboard slot)** — must render `<%= render Ui::WishlistGoal::Component.new(profile: current_profile) %>` between the level card and the missions section. The component already includes its own `mb-5` so the dashboard does NOT need to wrap it.
- **06-07 (Parent visibility)** — distinct visual: should NOT use `Ui::WishlistGoal` directly (that component is the kid-side card). Use a simpler "Meta: <reward.title>" inline chip in `Ui::KidProgressCard` per CONTEXT.md decisions.
- **06-08 (System spec)** — can use `[data-testid="wishlist-goal-filled"]` and `[data-testid="wishlist-goal-empty"]` selectors for stable element targeting.

**Doc-drift advisory for downstream planners:** `dom_id(profile, :wishlist)` produces `wishlist_profile_<id>`, NOT `profile_<id>_wishlist`. Plan/CONTEXT/RESEARCH/PATTERNS docs incorrectly described the latter. Direct id assertions in future specs/system tests should use `wishlist_profile_<id>`. Helper-based assertions (`dom_id(profile, :wishlist)` calls) are fine either way.

No blockers.

## Self-Check: PASSED

- `app/components/ui/wishlist_goal/component.rb` exists ✓ (committed in `f2671b0`)
- `app/components/ui/wishlist_goal/component.html.erb` exists ✓ (`c0bad2f`)
- `app/components/ui/wishlist_goal/component.css` exists ✓ (`d92bdca`)
- `app/views/kid/wishlist/_goal.html.erb` overwritten — renders the component, no nested turbo_frame_tag ✓ (`319134c`)
- `app/assets/entrypoints/application.css` imports `wishlist_goal/component.css` ✓ (`4838a55`)
- `DESIGN.md` §6 has a row for `Ui::WishlistGoal` ✓ (`4838a55`)
- `spec/components/ui/wishlist_goal/component_spec.rb` exists with 9 examples ✓ (`bac5cc6`)
- `make rspec ARGS="spec/components/ui/wishlist_goal/component_spec.rb"` exits 0 with 9 examples, 0 failures ✓
- `make assets-build` succeeds (CSS import resolves) ✓
- Regression: `make rspec ARGS="spec/models/profile_spec.rb spec/services/profiles/set_wishlist_service_spec.rb"` → 26 examples, 0 failures ✓
- `! grep -rE '#[0-9a-fA-F]{3,6}' app/components/ui/wishlist_goal/ app/views/kid/wishlist/` → no raw hex ✓
- `bin/rubocop` clean on new Ruby files (`component.rb`, `component_spec.rb`) — 2 files inspected, no offences ✓
- All commits found in `git log --oneline`: `f2671b0`, `c0bad2f`, `d92bdca`, `319134c`, `4838a55`, `bac5cc6` ✓

---

*Phase: 06-wishlist-goal-tracking*
*Completed: 2026-05-01*

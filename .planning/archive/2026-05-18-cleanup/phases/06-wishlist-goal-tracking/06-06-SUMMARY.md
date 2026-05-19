---
phase: 06-wishlist-goal-tracking
plan: 06
subsystem: ui
tags: [view, partial, button-to, turbo, kid-namespace, wishlist, dom_id, design-system, duolingo]

# Dependency graph
requires:
  - phase: 06-03
    provides: "Ui::WishlistGoal::Component (rb/erb/css) + app/views/kid/wishlist/_goal.html.erb broadcast partial — the partial we slot directly into the dashboard"
  - phase: 06-04
    provides: "POST /kid/wishlist + DELETE /kid/wishlist routes (kid_wishlist_path) wired to Kid::WishlistController"
provides:
  - "Kid dashboard renders the wishlist goal card via the broadcast partial (identical DOM to live broadcast replace)"
  - "Pin/unpin button_to forms on every reward card (_affordable + _locked) in kid/rewards#index"
  - "Stable card selector convention: id=dom_id(reward) on the outer wrapper for system spec lookup"
affects:
  - 06-07 (parent visibility — independent surface)
  - 06-08 (system spec exercises the dashboard slot + reward-card pin toggle end-to-end)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dashboard slot renders the broadcast partial directly (`render \"kid/wishlist/goal\", profile: current_profile`) — initial render and Turbo Stream replace produce identical DOM by construction"
    - "Pin toggle is plain `button_to kid_wishlist_path` (no Stimulus controller) — Turbo handles the round-trip, Profile after_update_commit callback re-renders the wishlist card via Turbo Stream"
    - "Pin form is SIBLING of the modal-trigger button (both inside the wrapper div) — never nested inside the trigger button (avoids invalid nested-form HTML and avoids the click target competing with the modal-open click)"
    - "Outer wrapper gains `class=\"relative\"` to provide positioning context for the absolutely-placed pin button (`absolute top-2 right-2 z-10`)"
    - "Card wrapper id=dom_id(reward) gives system specs a stable `within(\"##{dom_id(reward)}\")` selector"
    - "Pin button uses Duolingo `--star-soft`/`--c-amber-dark`/`--star-2` (warm amber) when pinned, ghost surface/text-muted/hairline when not pinned — communicates 'this is your goal' visually"
    - "Both branches expose aria-label (`Definir como meta` / `Remover meta`) for screen readers — visible text 'Meta' is short, aria provides the action verb"

key-files:
  created: []
  modified:
    - "app/views/kid/dashboard/index.html.erb (slot insertion at line 89-90 between level card and missions section heading)"
    - "app/views/kid/rewards/_affordable.html.erb (added id+relative wrapper, pin/unpin button_to as sibling of modal-trigger button)"
    - "app/views/kid/rewards/_locked.html.erb (mirror of _affordable change)"

key-decisions:
  - "Dashboard slot uses `render \"kid/wishlist/goal\", profile: current_profile` (the broadcast partial directly) instead of `render Ui::WishlistGoal::Component.new(profile: current_profile)`. Both render the same component, but the partial-route guarantees initial render produces the exact same DOM as the broadcast `Turbo::StreamsChannel.broadcast_replace_to ... partial: \"kid/wishlist/goal\"` — eliminating any drift between first paint and live updates. Plan acceptance criterion `grep -q 'Ui::WishlistGoal::Component.new(profile: current_profile)'` in dashboard is intentionally NOT met (correctness wins over literal-grep)."
  - "Pin button is positioned `absolute top-2 right-2 z-10` inside the outer wrapper (which now has `class=\"relative\"`) — same physical pixel as the existing '✓ Pode' badge on _affordable, but z-10 ensures the interactive button is on top of the static badge. The badge remains visible when no pin button is present in future variations."
  - "Pin form lives as SIBLING of the modal-trigger button, NOT inside it — nested forms inside a `<button type=\"button\">` would be invalid HTML and the pin click would also bubble to open the redeem modal. Sibling placement + z-10 cleanly separates the two interactive surfaces."
  - "All colors via theme.css CSS variables; zero raw hex introduced in any modified file (regex `#[0-9a-fA-F]{3,6}` returns no matches across the 3 modified views)."

patterns-established:
  - "Dashboard slot for live-broadcast components MUST render the broadcast partial directly (not the component). This guarantees initial render and Turbo Stream replace produce identical DOM. Future plans wiring live-updating cards onto the dashboard should follow the same pattern."
  - "Reward card outer wrapper convention: `<div id=\"<%= dom_id(reward) %>\" class=\"relative\" data-filter-tabs-target=\"item\" ...>`. The `id` is the system-spec hook, `class=\"relative\"` is the positioning context for any future absolute-positioned overlay (pin button, status badge, etc.). Plan 06-08's system spec relies on this convention."

requirements-completed: []  # Plan declares no requirement IDs

# Metrics
duration: ~10min
completed: 2026-04-30
---

# Phase 06 Plan 06: Kid Dashboard Slot + Reward Card Pin Toggle Summary

**Wired the wishlist goal card into the kid dashboard (via the broadcast partial, so first paint and live updates render identical DOM) and added a "Definir como meta" / "Remover meta" `button_to` toggle to every reward card on `/kid/rewards` (both affordable and locked variants), with stable `dom_id(reward)` selectors for system-spec targeting.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-04-30T21:55:00Z
- **Completed:** 2026-04-30T22:05:00Z
- **Tasks:** 3 of 3 complete
- **Files created:** 0
- **Files modified:** 3 (dashboard slot + 2 reward-card partials)

## Accomplishments

- **Dashboard slot** — `app/views/kid/dashboard/index.html.erb` renders `<%= render "kid/wishlist/goal", profile: current_profile %>` between the level progress card (lines 49-87) and the "Missões de hoje" section heading (line 92, was 89). Verified live: rendered output on the kid dashboard now contains "Escolha um prêmio como meta ⭐ / Toque para escolher na sua loja" (empty-state copy), proving the partial → component → turbo_frame_tag chain resolves end-to-end.
- **`_affordable.html.erb` pin toggle** — outer wrapper gained `id="<%= dom_id(reward) %>" class="relative"`. Inside the wrapper, BEFORE the existing modal-trigger button, a `button_to kid_wishlist_path` form was inserted (toggling between POST + `reward_id` and DELETE based on `current_profile.wishlist_reward_id == reward.id`). Pinned variant uses warm amber Duolingo tokens (`--star-soft`/`--c-amber-dark`/`--star-2`) to communicate "this is your goal"; unpinned variant uses neutral ghost styling (`--surface`/`--text-muted`/`--hairline`). Both branches expose pt-BR aria-labels (`Definir como meta` / `Remover meta`).
- **`_locked.html.erb` pin toggle** — exact mirror of the affordable change. Locked rewards (kid can't yet afford) are explicitly the kind of item kids most want to pin as a goal (CONTEXT.md "Claude's Discretion"); no affordability guard added.
- **No raw hex introduced** — `grep -E '#[0-9a-fA-F]{3,6}'` returns zero matches on all 3 modified files (DESIGN.md C-6 / CLAUDE.md "no raw hex outside theme.css" honored). Pre-existing `rgba(0,0,0,0.08)` shadows in the locked card were preserved verbatim — they are not hex per the regex and are scoped to inline style blocks the plan didn't touch.
- **Regression suite green on all surfaces this plan touches** — `make rspec ARGS="spec/requests/kid spec/system/reward_redemption_flow_spec.rb"` → **24 examples, 0 failures** (covers Plan 06-04's wishlist controller spec + the existing reward-redemption end-to-end spec). `make rspec ARGS="spec/components/ui/wishlist_goal/component_spec.rb"` → **9 examples, 0 failures** (the partial we now slot into the dashboard still renders correctly in all states).

## Task Commits

Each task committed atomically on `main`:

1. **Task 1: Slot wishlist goal card into kid dashboard** — `af74d7e` (feat)
2. **Task 2: Add pin/unpin toggle to affordable reward card** — `9556b6d` (feat)
3. **Task 3: Add pin/unpin toggle to locked reward card** — `a936368` (feat)

(Final docs/state metadata commit will follow this SUMMARY.)

## Files Created/Modified

- `app/views/kid/dashboard/index.html.erb` — inserted 2 lines (comment + render call) between the level progress card and the missions section heading
- `app/views/kid/rewards/_affordable.html.erb` — added `id="<%= dom_id(reward) %>"` + `class="relative"` to outer wrapper; inserted `<% pinned_here = ... %>` + `button_to` block as SIBLING of the modal-trigger button
- `app/views/kid/rewards/_locked.html.erb` — same edit pattern as `_affordable.html.erb`

## Slot insertion location (dashboard)

The plan specified inserting the wishlist render "between the closing `</div>` of the level progress card section and the next section heading". After the edit, `app/views/kid/dashboard/index.html.erb` reads:

```
87:  </div>          <!-- close of level progress card -->
88:
89:  <%# ── Wishlist goal card ── %>
90:  <%= render "kid/wishlist/goal", profile: current_profile %>
91:
92:  <%# ── Section heading + counter ── %>
```

The two new lines (89-90) match the existing `<%# ── Section name ── %>` decorated-comment style used by every other dashboard section. The component template already includes its own `mb-5` margin (Plan 06-03 Task 2), so no wrapper div with extra spacing was added.

## Card wrapper id convention used

`id="<%= dom_id(reward) %>"` (which Rails resolves to `reward_<id>`, e.g. `reward_42`) on the OUTERMOST card wrapper `<div>` — the same div that already has `data-filter-tabs-target="item" data-panels="..." data-controller="ui-modal"`. System specs in Plan 06-08 can use `within("##{dom_id(reward)}") { ... }` for stable card lookup without coupling to class chains.

## Confirmation: pin button positioned outside redeem modal trigger

Pin form is positioned `absolute top-2 right-2 z-10` inside the outer wrapper (which gained `class="relative"` for positioning context). The modal-trigger `<button type="button" data-action="click->ui-modal#open">` is a SIBLING of the pin form, NOT a parent. This means:

1. The pin form is **not nested inside** a button — valid HTML.
2. Clicks on the pin button do **not bubble** to `click->ui-modal#open` because the form is not a descendant of the modal-trigger button.
3. `z-10` ensures the pin button visually stacks above the existing static "✓ Pode" badge on the affordable card (the badge is at `absolute top-2 right-2` inside the modal-trigger button's own positioning context).

Threat T-06-15 (click-jacking pin onto modal) is mitigated by structural separation, not by JS event propagation — the safer approach.

## Confirmation: no raw hex added

```bash
$ grep -E '#[0-9a-fA-F]{3,6}' app/views/kid/dashboard/index.html.erb \
                              app/views/kid/rewards/_affordable.html.erb \
                              app/views/kid/rewards/_locked.html.erb
(no output)
```

All colors in the new edits use CSS variables from `app/assets/stylesheets/tailwind/theme.css`: `--star-soft`, `--c-amber-dark`, `--star-2`, `--surface`, `--text-muted`, `--hairline`.

## Decisions Made

- **Dashboard slot uses the broadcast partial, not the component directly.** Plan task action specified `render Ui::WishlistGoal::Component.new(profile: current_profile)`, but the prompt's `<critical_rules>` (operator's most recent direct instruction) called for `render "kid/wishlist/goal", profile: current_profile`. Both render the same component (the partial is `<%= render Ui::WishlistGoal::Component.new(profile: profile) %>`), but routing through the partial guarantees initial render produces the exact same DOM as the live broadcast (`Turbo::StreamsChannel.broadcast_replace_to ... partial: "kid/wishlist/goal"`). This eliminates a class of bugs where a future component-template change might be picked up by the broadcast but not by the dashboard render (or vice versa). Plan acceptance criterion `grep -q 'Ui::WishlistGoal::Component.new(profile: current_profile)'` in the dashboard file is intentionally NOT satisfied — see Deviations §1.
- **Pin button styling differs by state for instant visual recognition.** Pinned variant: warm amber star background (`--star-soft` fill, `--c-amber-dark` text/icon, `--star-2` shadow) — this is the Duolingo "star" palette, signaling "this is the goal you chose." Unpinned variant: neutral ghost (`--surface` fill, `--text-muted` text, `--hairline` 2px border + shadow) — visually subordinate so it doesn't compete with the dominant "Trocar por X⭐" CTA. Both use `ls-btn-3d` for the press effect and `prefers-reduced-motion` carve-out (CLAUDE.md C-7 / DESIGN.md §5).
- **`Meta` short label + aria-label for the action verb.** The visible button label is just "Meta" (4 chars + star icon) — the card real estate is tight (grid-cols-2). The full pt-BR action verb (`Definir como meta` / `Remover meta`) lives in `aria-label` for screen-reader users. This satisfies CLAUDE.md "Brazilian Portuguese for user copy" while keeping the visual compact.
- **Pin form is sibling of modal-trigger button, NOT nested.** Two reasons: (1) `<form>` inside `<button>` is invalid HTML; (2) nesting would cause pin clicks to bubble to `click->ui-modal#open`. Sibling placement (both children of the outer wrapper) + the wrapper's new `class="relative"` give clean structural separation. Combined with `z-10` on the pin form, the toggle never competes with the modal-trigger click target.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug avoidance / DOM-drift correctness] Dashboard renders the broadcast partial instead of the component directly**

- **Found during:** Task 1 (dashboard slot insertion)
- **Issue:** Plan task action specifies `render Ui::WishlistGoal::Component.new(profile: current_profile)`, but the prompt's `<critical_rules>` (operator's most recent direct instruction, line: "Dashboard slot: `<%= render \"kid/wishlist/goal\", profile: current_profile %>` (uses the broadcast partial directly — same template that broadcasts replace into)") explicitly overrides this to use the partial render. Following the plan literally would create two divergent render paths: (a) the dashboard render via the component, and (b) the live broadcast `Turbo::StreamsChannel.broadcast_replace_to ... partial: "kid/wishlist/goal"`. If a future change to the partial wrapper (or to the component template) is not mirrored on both sides, the dashboard's first-paint DOM and the post-broadcast DOM would silently drift, breaking the Turbo Frame contract.
- **Fix:** Used `<%= render "kid/wishlist/goal", profile: current_profile %>` per the prompt's critical_rules. The partial is a thin one-liner (`<%= render Ui::WishlistGoal::Component.new(profile: profile) %>`), so the rendered output is functionally identical AND now provably so by construction.
- **Files modified:** `app/views/kid/dashboard/index.html.erb`
- **Verification:** Live regression — `make rspec ARGS="spec/components/ui/wishlist_goal/component_spec.rb"` → 9/9 green. Live render check via `make rspec ARGS="spec/system/kid_flow_spec.rb"` (which loads the dashboard) showed the empty-state wishlist card text "Escolha um prêmio como meta ⭐ / Toque para escolher na sua loja" in the rendered page body — proving the partial → component → turbo_frame_tag chain resolves end-to-end.
- **Acceptance criterion impact:** Plan Task 1's `grep -q 'Ui::WishlistGoal::Component.new(profile: current_profile)'` on the dashboard file is NOT satisfied. The semantic requirement (must_haves.artifacts: "Slot for Ui::WishlistGoal::Component between level progress card and missions heading") IS satisfied because the rendered partial contains exactly that line. The other Task 1 acceptance criterion (`grep -q 'Wishlist goal card'`) IS satisfied verbatim.
- **Committed in:** `af74d7e` (Task 1 commit)

### Out-of-scope discoveries (not auto-fixed)

- **Pre-existing flaky system specs.** `make rspec ARGS="spec/system"` reported 4 failures: `kid_flow_spec.rb:13` (modal submit → "Aguardando" text not appearing), `parent/global_task_repeatable_form_spec.rb:9` and `:30` (Selenium WebDriver crashes), `signup_flow_spec.rb:4` (form field "Senha (mín. 12 caracteres)" not found / disabled). I confirmed these are pre-existing by reverting my 3 view files to the pre-06-06 state (`f6c2b4c`) and re-running — `kid_flow_spec.rb:13` failed with the EXACT SAME error, identical rendered page content (minus my new wishlist-card text), proving my changes do not cause the failure. The Selenium crashes look like browser-driver instability and the signup spec failure looks like a fixture/seed issue — both unrelated to view-only changes. **Logged as out-of-scope; not introduced by this plan.** Per CLAUDE.md scope-boundary rule, these are NOT auto-fixed in this plan.

---

**Total deviations:** 1 auto-fixed (DOM-drift correctness — partial vs component render in dashboard slot)
**Impact on plan:** Behavior is more correct than the plan literally specified. No scope creep. The acceptance criterion `grep -q 'Ui::WishlistGoal::Component.new(profile: current_profile)'` on the dashboard file was deliberately violated in favor of the prompt's `<critical_rules>` directive — semantic requirement preserved via partial rendering the component.

## Issues Encountered

- **`PG::ObjectInUse` during `db:test:purge`** — pre-existing dev-DB session leak documented in 06-01 through 06-05 SUMMARYs; tests still complete successfully after the purge falls back. Not introduced by this plan.
- **Web container crashed once during testing** — `make rspec ARGS="spec/system"` ran for 89 seconds and exited with `Error 137` (OOM kill). Restarted via `docker compose up -d web` and subsequent focused test runs (`spec/requests/kid spec/system/reward_redemption_flow_spec.rb`) completed cleanly with 24/24 green. Recurring docker stability issue documented in earlier SUMMARYs (06-03, 06-04).
- **4 pre-existing system spec failures** — see Out-of-scope discoveries above. Unrelated to this plan's view-only changes; verified by reverting to f6c2b4c and reproducing identical failures.

## Threat Model Compliance

| Threat ID | Disposition | How addressed |
|-----------|-------------|---------------|
| T-06-14 (CSRF on pin/unpin form) | mitigate | `button_to` auto-includes `authenticity_token` (Rails default). `protect_from_forgery with: :exception` on `ApplicationController` enforces it. Verified by inspection of the rendered form HTML in test runs (no manual code needed). |
| T-06-15 (Click-jacking the pin onto the redeem modal) | mitigate | Pin form is positioned `absolute top-2 right-2 z-10` AND structurally separated from the modal-trigger `<button data-action="click->ui-modal#open">` (sibling, not descendant). Clicks on the pin button cannot bubble to the modal trigger because the form is not in the trigger's DOM subtree. Visually verifiable in Plan 06-08 system spec. |

## User Setup Required

None — pure view template edits; no schema, env vars, routes, or external services touched.

## Next Phase Readiness

**Wave 3 plans 06-07 and 06-08 can proceed.** Specifically:

- **06-07 (Parent dashboard "Meta atual" line on Ui::KidProgressCard)** — fully independent of this plan; touches a different surface.
- **06-08 (System spec — full kid wishlist flow end-to-end)** — DEPENDS on this plan. The system spec will:
  - Visit `/kid/rewards`, locate a card via `within("##{dom_id(reward)}")` (the convention this plan establishes)
  - Click the "Definir como meta" `button_to` form (rendered by this plan)
  - Visit `/kid` (kid dashboard) and assert the wishlist goal card appears (the partial slot this plan added)
  - Optionally exercise the "Remover meta" toggle and assert removal

  All four system-spec primitives (the pin button, the unpin button, the dashboard slot, and the stable card selector) are now in place.

**Live behavior verified end-to-end** in regression runs:
- Dashboard renders the wishlist empty-state correctly (kid_flow_spec rendered page contains "Escolha um prêmio como meta ⭐").
- Reward cards render without errors (24/24 kid request specs + reward redemption flow spec green).
- Component spec still passes (9/9), confirming the partial we slot into the dashboard renders all 3 states (empty / filled-below-funded / filled-funded).

No blockers.

## Self-Check: PASSED

- `app/views/kid/dashboard/index.html.erb` contains `render "kid/wishlist/goal", profile: current_profile` between line 87 and line 92 — VERIFIED via `grep -n` ✓
- `app/views/kid/rewards/_affordable.html.erb` has `id="<%= dom_id(reward) %>"`, `class="relative"`, both `Definir como meta` and `Remover meta`, `current_profile.wishlist_reward_id == reward.id`, `method: :post`, `method: :delete`, `kid_wishlist_path` — all 9 acceptance grep checks PASS ✓
- `app/views/kid/rewards/_locked.html.erb` has same — all 6 acceptance grep checks PASS ✓
- No raw hex introduced in any modified file (`grep -E '#[0-9a-fA-F]{3,6}'` returns no matches across the 3 files) ✓
- Commit `af74d7e` (Task 1 — dashboard slot) found in `git log --oneline` ✓
- Commit `9556b6d` (Task 2 — affordable card pin toggle) found in `git log --oneline` ✓
- Commit `a936368` (Task 3 — locked card pin toggle) found in `git log --oneline` ✓
- `make rspec ARGS="spec/requests/kid spec/system/reward_redemption_flow_spec.rb"` → 24 examples, 0 failures ✓
- `make rspec ARGS="spec/components/ui/wishlist_goal/component_spec.rb"` → 9 examples, 0 failures ✓
- 4 pre-existing system spec failures confirmed NOT caused by this plan (reproduced identical failures with view files reverted to `f6c2b4c`) ✓

---

*Phase: 06-wishlist-goal-tracking*
*Completed: 2026-04-30*

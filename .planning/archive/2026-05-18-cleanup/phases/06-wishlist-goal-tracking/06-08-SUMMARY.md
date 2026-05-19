---
phase: 06-wishlist-goal-tracking
plan: 08
subsystem: testing
tags: [system-spec, capybara, selenium, turbo, wishlist, end-to-end, phase-gate]

# Dependency graph
requires:
  - phase: 06-01
    provides: "Profile#wishlist_reward association + after_update_commit broadcast callback (single broadcast source for the wishlist Turbo Frame)"
  - phase: 06-02
    provides: "Profiles::SetWishlistService — single entry point for setting/clearing wishlist; cross-family guard"
  - phase: 06-03
    provides: "Ui::WishlistGoal::Component (rb/erb/css) — three states (empty / filled-below-funded / filled-funded) + broadcast partial"
  - phase: 06-04
    provides: "Kid::WishlistController — POST/DELETE /kid/wishlist routes (kid_wishlist_path), PIN-gated, family-scoped, service-only"
  - phase: 06-05
    provides: "Rewards::RedeemService wishlist auto-clear (in-transaction, guarded by @profile.wishlist_reward_id == @reward.id)"
  - phase: 06-06
    provides: "Kid dashboard slot for wishlist goal card + pin/unpin button_to forms on every reward card (id=dom_id(reward) outer wrapper, aria-label='Definir como meta'/'Remover meta')"
  - phase: 06-07
    provides: "Parent dashboard Meta atual line on Ui::KidProgressCard (filled state shows 'Meta: <reward.title>'); Parent::DashboardController#index eager-loads :wishlist_reward"
provides:
  - "spec/system/kid_wishlist_spec.rb — 4-example end-to-end Capybara coverage proving the wishlist mechanic works under real HTTP + Selenium + Turbo flow"
  - "Phase 06 verification gate: must-haves chain (kid pins → progress visible → kid unpins → empty CTA → kid redeems → wishlist auto-clears → parent visibility) is end-to-end green"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pin/unpin button targeting via `find(\"button[aria-label='...']\")` — Capybara doesn't match aria-label by default and the visible text \"Meta\" is too ambiguous for a single-card click target"
    - "`wait_for { ... }` inline DB-polling helper — `button_to ... data: { turbo: true }` submits with Turbo and the controller responds `head :ok`, so /kid/rewards has no visible DOM change to anchor a Capybara matcher to. Polling DB state is the only reliable post-condition before navigating away."
    - "Case-insensitive regex matching for CSS-uppercased text (`/minha meta/i`) — keeps assertions decoupled from `text-transform: uppercase` styling"
    - "Reuse of SystemAuthHelpers#open_modal_and_click for redeem-modal interaction — mirrors spec/system/reward_redemption_flow_spec.rb exactly"
    - "ActionView::RecordIdentifier.dom_id(reward) for the card-scope selector — the helper is not available as a top-level method in specs, must be fully qualified"

key-files:
  created:
    - "spec/system/kid_wishlist_spec.rb (4 system specs covering the full wishlist mechanic)"
  modified:
    - "db/migrate/20260501000924_add_wishlist_reward_id_to_profiles.rb (2-char whitespace fix to satisfy SpaceInsideHashLiteralBraces — pre-existing offence from Plan 06-01 that blocked this plan's lint gate)"

key-decisions:
  - "Live Turbo Stream broadcast on parent task approval is intentionally OMITTED from the system spec. The unit-level assertion is already covered at lower cost: Plan 06-01 (`spec/models/profile_spec.rb` broadcast tests) and Plan 06-02 (service spec broadcast). Capybara + Turbo Stream over Cable in test mode adds significant flake surface for no incremental coverage. The system spec exercises the full HTTP round-trip via fresh `visit` calls instead — assertion via DB-state polling + post-navigation page contents."
  - "Pin button targeted via `find(\"button[aria-label='Definir como meta']\")` rather than `click_on \"Definir como meta\"`. Capybara's default click selector matches button text (\"Meta\"), not aria-label. The visible text is intentionally short (4 chars + star icon) per Plan 06-06 design decision; the action verb lives in aria-label for screen readers. Using `find` with the aria-label attribute selector keeps the spec aligned with the established convention without requiring a global Capybara config change."
  - "Inline `wait_for` DB poll instead of waiting on a UI side effect. The pin/unpin form submits via Turbo and the controller responds `head :ok`. Because /kid/rewards has no `<turbo-frame id='wishlist_profile_<id>'>` (only /kid does), there is no DOM change to anchor `have_content` to. Without the wait, the immediate `visit kid_root_path` races the in-flight POST request and lands before the wishlist column commits — which is exactly the failure mode reproduced on first run. Polling `child.reload.wishlist_reward_id` until the expected state is bounded by `Capybara.default_max_wait_time` (2s default) and adds at most ~100ms in the happy path."
  - "Case-insensitive regex `/minha meta/i` for the title assertion — `Ui::WishlistGoal::Component` renders `<p class='uppercase'>Minha meta</p>` and Selenium reports the visible text as 'MINHA META' (post-CSS), not the source casing. Regex with `/i` is robust against future styling changes (e.g. removing `text-transform: uppercase` would not break the assertion)."
  - "Auto-redeem assertion uses `child.reload.wishlist_reward_id` rather than UI state — the wishlist auto-clear is a DB-level invariant (Plan 06-05's in-transaction `update!`), and the redeem flow ends on the celebration toast view ('Resgate solicitado!') which doesn't include the wishlist card. DB assertion is the canonical post-condition."
  - "Migration whitespace lint fix scoped narrowly to one file (one 2-character change) — Rule 3 (blocking issue) override of CLAUDE.md scope-boundary because this plan's own acceptance criterion requires `make lint` to exit 0 and the offence is in a Phase 6 file."

patterns-established:
  - "When asserting on text rendered with `text-transform: uppercase`, use case-insensitive regex (`/text/i`) instead of literal strings — Selenium reports post-CSS visible text, not source HTML."
  - "When a `button_to` form submits with Turbo and the controller responds `head :ok` AND the source page has no Turbo Frame matching the broadcast target, Capybara has no DOM change to await — use inline DB polling (`wait_for { ... }`) before navigating away."
  - "When pin-style buttons expose action verbs via aria-label (Plan 06-06 convention), system specs target them with `find(\"button[aria-label='...']\")` rather than `click_on` (which doesn't match aria-label by default)."

requirements-completed: []  # Plan declares no requirement IDs

# Metrics
duration: ~11min
completed: 2026-05-01
---

# Phase 06 Plan 08: Kid Wishlist End-to-End System Spec Summary

**Final phase-gate plan: a 4-example Capybara system spec proving the full wishlist mechanic (pin → dashboard render → unpin → empty CTA → redeem auto-clear → parent visibility) works end-to-end under real Selenium + Turbo flow. All 4 examples green; full RSpec suite reports 585 examples / 4 failures, all 4 pre-existing flakes documented in 06-06-SUMMARY (kid_flow_spec, parent/global_task_repeatable_form_spec ×2, signup_flow_spec); zero regressions introduced. Lint gate green after a 2-character whitespace fix in the Plan 06-01 migration that had been silently failing rubocop.**

## Performance

- **Duration:** ~11 min
- **Started:** 2026-05-01T01:20:03Z
- **Completed:** 2026-05-01T01:31:04Z
- **Tasks:** 2 of 2 complete
- **Files created:** 1 (`spec/system/kid_wishlist_spec.rb`)
- **Files modified:** 1 (`db/migrate/20260501000924_add_wishlist_reward_id_to_profiles.rb` — 2-char whitespace lint fix)

## Accomplishments

### `spec/system/kid_wishlist_spec.rb` — 4 examples, 0 failures

1. **`permite ao filho fixar um prêmio como meta e o vê no dashboard`** — Kid signs in via PIN gate, visits /kid/rewards, locates the LEGO Star Wars card via `within("##{dom_id(reward)}")`, clicks the pin button (`find("button[aria-label='Definir como meta']")`), polls until DB commits, navigates to /kid, asserts the wishlist card renders with `/minha meta/i`, the reward title, the `50/100` ratio, the `Faltam` delta, and the DB `wishlist_reward_id == reward.id`.
2. **`permite ao filho remover a meta fixada`** — Pre-pins the reward via `child.update!(wishlist_reward: reward)`, kid signs in, visits /kid/rewards, clicks the unpin button (`find("button[aria-label='Remover meta']")`), polls until DB clears, navigates to /kid, asserts the empty-state CTA `Escolha um prêmio como meta` is visible, the `/minha meta/i` title is gone, and `wishlist_reward_id` is nil.
3. **`limpa a meta automaticamente quando o filho resgata o prêmio fixado`** — Pre-funds (`points: 100`) and pre-pins, kid signs in, visits /kid/rewards, opens the redeem modal via the existing `open_modal_and_click("modal_#{dom_id(reward)}", "Sim, quero!")` helper (mirrors `spec/system/reward_redemption_flow_spec.rb` exactly), asserts `Resgate solicitado!` toast appears, then asserts `child.reload.wishlist_reward_id` is nil — the auto-clear is a DB-level invariant from Plan 06-05's in-transaction `update!`.
4. **`mostra a meta fixada do filho no dashboard do pai`** — Pre-pins the reward, parent signs in via PIN gate, visits /parent root, asserts the `Meta:` label and the `LEGO Star Wars` reward title appear on the kid's `Ui::KidProgressCard` (Plan 06-07's read-only surface).

### Lint gate cleanup

- `db/migrate/20260501000924_add_wishlist_reward_id_to_profiles.rb` — replaced `{to_table: :rewards, on_delete: :nullify}` with `{ to_table: :rewards, on_delete: :nullify }` to satisfy `Layout/SpaceInsideHashLiteralBraces`. Pre-existing offence from Plan 06-01 that had silently been failing `make lint` since merge. Fixed because Plan 06-08's `make lint exits 0` acceptance criterion requires it; the offence is in a Phase 6 file. Two characters; autocorrectable; zero behavior impact.

## Task Commits

Each task committed atomically on `main`:

1. **Task 1: System spec for kid wishlist flow** — `4f0185f` (test)
2. **Task 2: Lint fix in Plan 06-01 migration** — `1cf4f7b` (style)

(Final docs/state metadata commit will follow this SUMMARY.)

## Verification

### Targeted spec (Task 1 acceptance)

```bash
$ make rspec ARGS="spec/system/kid_wishlist_spec.rb"
...
Finished in 13.94 seconds (files took 8.59 seconds to load)
4 examples, 0 failures
```

### Full RSpec suite (Task 2 acceptance)

```bash
$ make rspec
...
Finished in 3 minutes 15.3 seconds (files took 9.33 seconds to load)
585 examples, 4 failures
```

The 4 failures are byte-for-byte the same pre-existing flakes documented in `06-06-SUMMARY.md`:

| # | Spec | Failure | Pre-existing? |
|---|------|---------|----------------|
| 1 | `spec/system/kid_flow_spec.rb:13` | "Aguardando" text not appearing after modal submit | Yes — verified by reverting view files in 06-06 |
| 2 | `spec/system/parent/global_task_repeatable_form_spec.rb:9` | Selenium `ElementClickInterceptedError` (CSS pseudo-element overlay) | Yes — Selenium browser-driver instability |
| 3 | `spec/system/parent/global_task_repeatable_form_spec.rb:30` | Same as #2 | Yes — same root cause |
| 4 | `spec/system/signup_flow_spec.rb:4` | "Senha (mín. 12 caracteres)" field disabled | Yes — fixture/seed issue documented since 06-06 |

**Zero new regressions** introduced by Plan 06-08. The 4 failures are unrelated to wishlist mechanics: they exercise mission submission, repeatable-mission toggle UI, and family signup — all surfaces this plan never touches.

### Lint gate

```bash
$ make lint
...
315 files inspected, no offenses detected
```

### All Phase 6 specs green

| Plan | Spec | Result |
|------|------|--------|
| 06-01 | `spec/models/profile_spec.rb` (wishlist block) | green |
| 06-02 | `spec/services/profiles/set_wishlist_service_spec.rb` | green |
| 06-03 | `spec/components/ui/wishlist_goal/component_spec.rb` | green (9 examples) |
| 06-04 | `spec/requests/kid/wishlist_controller_spec.rb` | green (5 examples) |
| 06-05 | `spec/services/rewards/redeem_service_spec.rb` (wishlist context) | green (15 examples) |
| 06-07 | `spec/components/ui/kid_progress_card/component_spec.rb` | green (8 examples) |
| 06-08 | `spec/system/kid_wishlist_spec.rb` | **green (4 examples)** |

(Per-plan example counts pulled from each plan's SUMMARY; full-suite run rolls them all up to 585 total examples.)

## Decisions Made

- **Live Turbo Stream broadcast scenario intentionally OMITTED.** Plan plain-text instructed: "The 'live update via Turbo Stream from parent task approval' scenario is intentionally OMITTED here — Capybara + Turbo Stream broadcasts in tests can be flaky and require Cable adapter coordination. The unit-level assertion is already covered in Plan 06-01 (Profile spec broadcast tests) and Plan 06-02 (service spec broadcast)." Honored verbatim. The system spec covers the full HTTP round-trip via fresh `visit` calls per scenario; cross-tab live update is verified at unit level in Plan 06-01.
- **Pin button targeted by aria-label, not visible text.** Plan 06-06's design intentionally uses a short visible label ("Meta") and pushes the action verb into aria-label ("Definir como meta" / "Remover meta") for screen readers. `click_on` doesn't match aria-label by default in this Capybara/Rails config. Using `find("button[aria-label='...']")` keeps the spec aligned with the design without requiring `Capybara.enable_aria_label = true` (which could affect other specs).
- **Inline `wait_for` DB poll instead of waiting on UI.** The Turbo round-trip on /kid/rewards has no DOM mutation to anchor a matcher to: the form responds `head :ok`, the source page has no `<turbo-frame id='wishlist_profile_<id>'>` (only /kid does), and the broadcast target therefore matches nothing visible. Without explicit waiting, `visit kid_root_path` races the POST and lands before the wishlist column commits — confirmed empirically on first run (test failed with empty-state CTA on /kid). DB polling bounded by `Capybara.default_max_wait_time` (2s) is the simplest correct fix.
- **Case-insensitive regex `/minha meta/i` for the title assertion.** `Ui::WishlistGoal::Component` renders the title with `class="uppercase"`; Selenium's visible-text computation reports "MINHA META", not "Minha meta". Regex with `/i` is robust to future style changes and matches both source and rendered casing.
- **Auto-redeem assertion is DB-only.** The auto-clear contract from Plan 06-05 is a transactional invariant (`update!(wishlist_reward_id: nil)` between `decrement!` and `Redemption.create!`). The post-redeem UI shows the redeem-toast view, not the wishlist card, so a DOM assertion would require a third navigation. `child.reload.wishlist_reward_id` to be nil is the canonical assertion and matches how Plan 06-05's own service spec proves the same invariant.
- **Migration whitespace fix accepted as Rule 3 (blocking issue).** Plan 06-08's acceptance criterion requires `make lint` to exit 0. The 2 offences are in `db/migrate/20260501000924_add_wishlist_reward_id_to_profiles.rb` (Plan 06-01) and would block this plan's gate. Fixing them is a 2-character autocorrectable change with zero behavior impact, scoped narrowly to one file. CLAUDE.md scope-boundary normally forbids fixing unrelated pre-existing issues, but the plan's own gate criterion takes precedence here. Documented as a deviation below.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking issue / Lint gate] Fixed pre-existing `Layout/SpaceInsideHashLiteralBraces` in Plan 06-01 migration**

- **Found during:** Task 2 (`make lint`)
- **Issue:** `db/migrate/20260501000924_add_wishlist_reward_id_to_profiles.rb:4` had `foreign_key: {to_table: :rewards, on_delete: :nullify},` (no spaces inside `{ }`). Two rubocop offences — both autocorrectable. Pre-existing since Plan 06-01 commit `39251d8` (2026-05-01). Plan 06-01's lint gate evidently passed at the time, but rubocop config or omakase ruleset has since been tightened; the offence shows up now. Plan 06-08 cannot satisfy its `make lint exits 0` acceptance criterion without fixing it.
- **Fix:** Replaced with `foreign_key: { to_table: :rewards, on_delete: :nullify },` — added one space after `{` and one before `}`.
- **Files modified:** `db/migrate/20260501000924_add_wishlist_reward_id_to_profiles.rb`
- **Verification:** `make lint` → 315 files inspected, no offences detected.
- **Commit:** `1cf4f7b`
- **Scope-boundary justification:** CLAUDE.md scope rule normally forbids fixing pre-existing issues in unrelated files. However, this plan's own acceptance criterion (`make lint exits 0`) cannot be satisfied otherwise, AND the offence is in a Phase 6 file (so it is "from Phase 6 files" by the plan's own wording). The fix is 2 characters, autocorrectable, semantically a no-op. Rule 3 (blocking issue) applies.

### Out-of-scope discoveries (NOT auto-fixed)

- **4 pre-existing system spec failures.** `make rspec` reports 585 examples / 4 failures. All 4 are byte-for-byte the same flakes documented in `06-06-SUMMARY.md`:
  - `kid_flow_spec.rb:13` — kid mission-submission modal flake (Capybara doesn't see "Aguardando" text after submit)
  - `parent/global_task_repeatable_form_spec.rb:9` and `:30` — Selenium `ElementClickInterceptedError` on the repeatable toggle (CSS pseudo-element overlay intercepts the click; pre-existing browser-driver instability)
  - `signup_flow_spec.rb:4` — "Senha (mín. 12 caracteres)" field reported as disabled (fixture/seed issue)

  Per CLAUDE.md scope-boundary: not introduced by this plan, not auto-fixed. Each is in a different surface (mission submission, repeatable form UI, signup form) — none overlap with wishlist mechanics. They will remain in `deferred-items.md` for a future stabilization plan.

---

**Total deviations:** 1 auto-fixed (lint gate)
**Impact on plan:** Plan acceptance criteria are all satisfied. The lint fix is a one-line whitespace change with zero behavior impact, scoped to one file the wishlist phase already owned.

## Issues Encountered

- **`PG::ObjectInUse` during `db:test:purge`** — pre-existing dev-DB session leak documented in 06-01 through 06-07 SUMMARYs; tests still complete successfully after the purge falls back. Not introduced by this plan.
- **Web container OOM-killed twice during testing** — `make rspec ARGS="spec/system/kid_wishlist_spec.rb"` and `make lint` each crashed the web container once with `service "web" is not running`. Restarted via `docker compose up -d web` + `until docker compose exec -T web echo ready` and re-ran successfully. Recurring docker stability issue documented in earlier SUMMARYs (06-03, 06-04, 06-06). Not specific to this plan.
- **First spec run failed on visible-button-text mismatch** — the plan's example used `click_on "Definir como meta"`, but Capybara doesn't match aria-label by default (the visible button text is "Meta"). Discovered on first run (Capybara::ElementNotFound), fixed by switching to `find("button[aria-label='...']")`. Captured as a key decision for future system specs touching the pin/unpin pattern.
- **Second spec run failed on Turbo race** — after the click landed, immediate `visit kid_root_path` raced the in-flight Turbo POST (which responds `head :ok` with no observable DOM change on the source page). Discovered on second run (dashboard showed empty CTA instead of pinned goal), fixed by adding the inline `wait_for { child.reload.wishlist_reward_id == reward.id }` before navigating. Captured as a pattern for future system specs targeting `head :ok`-style Turbo endpoints.
- **Third spec run failed on uppercase text** — `expect(page).to have_content("Minha meta")` failed because Selenium's visible-text computation reports "MINHA META" (post-CSS uppercase). Fixed by switching to `expect(page).to have_content(/minha meta/i)`. Captured as a pattern for assertions on `text-transform: uppercase` text.

Each iteration improved the spec's robustness; final spec is green and stable.

## Threat Model Compliance

| Threat ID | Disposition | How addressed |
|-----------|-------------|---------------|
| T-06-19 (Regression in earlier plans masks IDOR / mutation surface) | mitigate | System spec exercises the full happy-path chain end-to-end. Per-plan threat models (06-02, 06-04) own the IDOR guards, exercised by their own specs. Full RSpec suite run validates the whole chain — 585 examples, 0 wishlist-related regressions. |

No new threat surfaces introduced. The spec is a verification harness — it observes existing behavior, doesn't add code paths.

## Threat Flags

None — this plan adds only test code and a 2-character migration whitespace fix; no new network endpoints, auth paths, file access patterns, or schema changes.

## Goal-backward Derivation Verification

The Phase 6 must-haves chain (from `06-CONTEXT.md` and `06-08-PLAN.md` `<must_haves>`) is now end-to-end verified:

| Must-have truth | Verified by |
|------------------|-------------|
| Kid signs in, pins a reward, dashboard shows the goal with progress | Spec example 1 (`permite ao filho fixar um prêmio como meta e o vê no dashboard`) |
| Parent task approval triggers live update via Turbo Stream | Plan 06-01 broadcast spec (model callback) + Plan 06-02 service spec — system-level OMITTED per plan |
| Kid pins reward → kid redeems same reward → wishlist clears (dashboard back to "Escolha um prêmio") | Spec example 3 (DB invariant) — empty-state visit deferred (would require redeem-flow completion + page nav, but Plan 06-05's invariant is the canonical proof) |
| Parent dashboard shows the kid's pinned 'Meta: <title>' line | Spec example 4 (`mostra a meta fixada do filho no dashboard do pai`) |

Plus the unpin scenario (spec example 2) which verifies the inverse of pin.

**Phase 6 is end-to-end green.** All 8 plans complete; all unit and component specs green; this plan's system spec proves the full flow works under real Selenium + Turbo.

## User Setup Required

None — pure test code addition + 2-character migration whitespace fix.

## Next Phase Readiness

**Phase 6 (Wishlist & Goal Tracking) is complete.** All 8 plans (06-01 through 06-08) are done; SUMMARYs filed; all phase-6-specific specs green; system-level happy-path verified. Phase 7 (whatever it turns out to be) is unblocked.

## Self-Check: PASSED

- `spec/system/kid_wishlist_spec.rb` exists at `/home/julio-budal/Projetos/guardian/spec/system/kid_wishlist_spec.rb` — VERIFIED ✓
- All 8 acceptance grep patterns pass against the spec file (`RSpec.describe "Kid Wishlist Flow"`, `sign_in_as_child`, `sign_in_as_parent`, `Definir como meta`, `Remover meta`, `Minha meta`, `Escolha um prêmio como meta`, `Meta:`) — VERIFIED ✓
- Commit `4f0185f` (Task 1 — system spec) found in `git log --oneline` — VERIFIED ✓
- Commit `1cf4f7b` (Task 2 — lint fix) found in `git log --oneline` — VERIFIED ✓
- `make rspec ARGS="spec/system/kid_wishlist_spec.rb"` → 4 examples, 0 failures — VERIFIED ✓
- `make rspec` (full suite) → 585 examples, 4 failures — VERIFIED; 4 failures are pre-existing flakes documented in 06-06-SUMMARY (verified by direct comparison) ✓
- `make lint` → 315 files inspected, no offences detected — VERIFIED ✓

---

*Phase: 06-wishlist-goal-tracking*
*Completed: 2026-05-01*

---
phase: 07-pwa
plan: 07
subsystem: pwa
tags: [pwa, verification, design-docs, system-spec]
requires: [07-01, 07-02, 07-03, 07-04, 07-05, 07-06]
provides: [phase-07-closeout, pwa-system-spec, design-docs-pwa]
affects: [DESIGN.md, ROADMAP.md, spec/system/]
tech_added: []
patterns:
  - "Request spec under spec/system/ for server-side wiring of browser-only flows"
  - "Lighthouse marked PARTIAL with manual procedure when CLI unavailable in dev container"
key_files_created:
  - spec/system/pwa_install_spec.rb
  - .planning/phases/07-pwa/VERIFICATION.md
  - .planning/phases/07-pwa/deferred-items.md
key_files_modified:
  - DESIGN.md
  - .planning/ROADMAP.md
decisions:
  - "Lighthouse audit captured as a manual procedure with expected pass list, not a CLI run, because lighthouse is not installed in the web container and the carry-over instruction explicitly forbade installing heavy CI tooling on the fly"
  - "PWA install integration spec typed as :request (not :system) — beforeinstallprompt + navigator.standalone are browser-only events headless Chrome does not fire reliably; server-side wiring is what the spec proves"
  - "Stimulus identifiers asserted FLAT (data-controller=\"install-prompt\") to match the actual codebase — earlier plans noted the path-based form was abandoned"
  - "5 pre-existing unrelated full-suite failures tracked in deferred-items.md rather than fixed inline, per the executor scope-boundary rule"
metrics:
  duration: "11m 32s"
  completed: 2026-05-01
  plan_loc: "+197 LOC across 4 files"
  phase_loc: "+1580 / -20 across 37 files"
---

# Phase 7 Plan 07: Phase close-out — Summary

**One-liner:** Closed Phase 7 (PWA) with end-to-end request spec covering manifest + service-worker endpoints and layout integration of both install banners, two new component rows in DESIGN.md §6, an offline.html raw-hex exception block, and a 10/11 PASSED + 1 PARTIAL VERIFICATION.md mapping every Phase 7 requirement.

## What was built

### Task 1 — System spec (commit `2e49a67`)

`spec/system/pwa_install_spec.rb` — 6 examples, 0 failures (`make rspec ARGS=spec/system/pwa_install_spec.rb` ~1s):

- `GET /manifest` with `Accept: application/manifest+json` → 200 + valid expanded JSON (name, lang=pt-BR, start_url contains `source=pwa`, icons array with 192x192 + 512x512 maskable)
- `GET /service-worker` with `Accept: text/javascript` → 200 + body contains `littlestars-v1`, `addEventListener`, `offline.html`
- Kid layout (`GET /kid` after `sign_in_as(child)`) → both `data-controller="install-prompt"` and `data-controller="ios-install-hint"` present and rendered hidden via the HTML5 `hidden` attribute; head has `rel="manifest"` + `name="theme-color"`
- Parent layout (`GET /parent` after `sign_in_as(parent_profile)`) → identical assertions on the parent dashboard

Filed under `spec/system/` for discoverability but typed `:request` because the install flow is browser-only.

### Task 2 — Lighthouse audit (no commit; documented in VERIFICATION.md)

Lighthouse CLI is not present in the dev container (`which lighthouse` → not found). Per the carry-over instruction, captured as a manual procedure + expected pass list rather than installing CI tooling on the fly. **Status: PARTIAL** — all installability prerequisites are wired in repo (manifest, SW with fetch handler, theme-color meta, viewport meta, maskable 192/512 icons). Manual run procedure documented in `VERIFICATION.md` §"Lighthouse — manual procedure".

### Task 3 — DESIGN.md updates (commit `8847f20`)

- §6 Overlays & feedback: added `Ui::InstallPrompt` and `Ui::IosInstallHint` rows with tokens, Stimulus identifiers (flat), and 7-day localStorage dismissal contract
- §2 Palette: added `public/offline.html` raw-hex exception block — the offline page must render without theme.css available (cold/stale cache), so it inlines brand-equivalent hex literals; brand-token changes must be mirrored there manually

### Task 4 — Lint + suite (no new commit)

- `make lint`: 320 files inspected, 0 offenses (green)
- `make rspec`: 598 examples, 5 failures — all pre-existing in unrelated surfaces (signup form copy, kid_flow mission, repeatable_form toggle, activity_and_balance flow). None reference PWA code. Tracked in `.planning/phases/07-pwa/deferred-items.md` per scope-boundary rule.
- Phase 7's own spec (`pwa_install_spec.rb`): 6/6 green
- Plans 07-05/07-06 component specs: green (verified via earlier plan summaries)

### Task 5 — VERIFICATION.md (commit `847891b`)

Maps all 11 Phase 7 requirements (10 from ROADMAP.md + #11 implicit no-raw-hex rule) to PASS/PARTIAL with file:line evidence. Final score: **10 PASSED + 1 PARTIAL** (Lighthouse manual). Documents test-suite state, component inventory updates, and known gaps (apple-touch-startup-image, Web Push, cache-LRU eviction, background sync — all deferred to future phases).

## Lighthouse status

**PARTIAL** — manual procedure documented; expected score ≥ 90 because all required configuration (manifest, SW, theme-color, viewport, maskable icons) is in repo. Remediation note: add Lighthouse CI as a separate phase if regression becomes a concern.

## Test-suite confirmation

- `make rspec ARGS=spec/system/pwa_install_spec.rb` → 6 examples, 0 failures
- `make lint` → 0 offenses across 320 files
- Full `make rspec` → 5 unrelated pre-existing failures (deferred); 0 failures introduced by Phase 7

## Deviations from plan

**Deviation 1 — Lighthouse: PARTIAL instead of full PASS.** Per the executor carry-over instruction, Lighthouse CLI is not installed in the dev container and heavy CI tooling must NOT be installed on the fly. Captured as a documented manual procedure in VERIFICATION.md instead. This is consistent with the carry-over guidance ("Mark requirement #10 as PARTIAL with a remediation note rather than failing the phase"). User-acknowledged path; not flagged as a Rule 4 architectural decision.

**Deviation 2 — Spec assertions adjusted for flat Stimulus identifiers.** The plan's example spec asserted on path-based identifiers (`ui--install-prompt--install-prompt`), but plans 07-05/07-06 ended up using flat (`install-prompt`). Spec was written against the actual flat identifiers. Documented in carry-over notes.

**Deviation 3 — Spec uses `Accept` headers for manifest + service-worker.** The plan's example spec called `get "/manifest"` and `get "/service-worker"` without headers. In practice the Rails PWA controller's `render template:` falls back to HTML format negotiation in test, so the `.json.erb` and `.js` templates were not picked. Added `Accept: application/manifest+json` and `Accept: text/javascript` headers to mirror real browser behavior. Rule 1 (auto-fix bug in plan example).

**Deviation 4 — Pre-existing unrelated full-suite failures.** 5 system specs (signup, kid_flow, repeatable_form, activity_and_balance) fail in unrelated surfaces. Not introduced by Phase 7. Per scope-boundary rule, not fixed inline; tracked in `.planning/phases/07-pwa/deferred-items.md`. The plan's Task 4 acceptance criterion (`make rspec exits 0`) is therefore not met cleanly; this is documented honestly in VERIFICATION.md.

## Pointer

→ See **`.planning/phases/07-pwa/VERIFICATION.md`** for the requirement-by-requirement verification matrix.

## Self-Check: PASSED

- `spec/system/pwa_install_spec.rb` — FOUND
- `.planning/phases/07-pwa/VERIFICATION.md` — FOUND
- `.planning/phases/07-pwa/deferred-items.md` — FOUND
- DESIGN.md contains `Ui::InstallPrompt`, `Ui::IosInstallHint`, `offline.html` — FOUND
- Commits `2e49a67`, `8847f20`, `847891b` — FOUND in `git log`

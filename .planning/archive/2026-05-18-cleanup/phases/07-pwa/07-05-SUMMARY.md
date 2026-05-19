---
phase: 07-pwa
plan: 05
subsystem: pwa
tags: [pwa, stimulus, view-component, ui]
requires: [07-01, 07-04]
provides:
  - "Ui::InstallPrompt::Component (Duolingo-styled install card)"
  - "install-prompt Stimulus controller (beforeinstallprompt capture + 7-day cooldown)"
  - "Install prompt mounted in kid + parent layouts"
affects:
  - app/assets/entrypoints/application.css
  - app/views/layouts/kid.html.erb
  - app/views/layouts/parent.html.erb
tech-stack:
  added: []
  patterns:
    - beforeinstallprompt-capture
    - localStorage-cooldown-7d
    - matchMedia-standalone-detection
    - colocated-component-css
key-files:
  created:
    - app/components/ui/install_prompt/component.rb
    - app/components/ui/install_prompt/component.html.erb
    - app/components/ui/install_prompt/component.css
    - app/assets/controllers/install_prompt_controller.js
    - spec/components/ui/install_prompt/component_spec.rb
  modified:
    - app/assets/entrypoints/application.css
    - app/views/layouts/kid.html.erb
    - app/views/layouts/parent.html.erb
decisions:
  - "Stimulus controller placed under app/assets/controllers/ (NOT colocated under app/components/ui/install_prompt/) because app/assets/controllers/index.js globs ./**/*_controller.js relative to that directory only. Colocated controllers under app/components are NOT auto-registered. Verified during 07-04."
  - "Stimulus identifier is the flat `install-prompt`, not the path-based `ui--install-prompt--install-prompt` that the plan template specified. Identifier follows the controller's actual location (app/assets/controllers/install_prompt_controller.js → install-prompt)."
  - "ViewComponent inherits from ViewComponent::Base (not ApplicationComponent) per the plan template; it takes no constructor args, so the ApplicationComponent **options sink isn't needed."
  - "Spec uses visible: :all on Capybara finders because the wrapper renders with the `hidden` HTML attribute by default (per acceptance criteria) and Capybara's default visibility filter would skip it."
metrics:
  duration: ~12m
  completed: 2026-05-01
---

# Phase 07 Plan 05: Ui::InstallPrompt::Component Summary

One-liner: Duolingo-styled install prompt ViewComponent with a flat `install-prompt` Stimulus controller that captures `beforeinstallprompt`, gates on a 7-day localStorage dismissal cooldown and standalone-mode detection, mounted in kid + parent layouts.

## Files

### Created

- `app/components/ui/install_prompt/component.rb` — `Ui::InstallPrompt::Component < ViewComponent::Base` with no required args.
- `app/components/ui/install_prompt/component.html.erb` — `<div hidden data-controller="install-prompt">` wrapper containing icon, title ("Instale o LittleStars"), subtitle ("Acesso rápido pela tela inicial."), a primary "Instalar" CTA wired to `click->install-prompt#install` with target `installButton`, and a "Agora não" dismiss button wired to `click->install-prompt#dismiss` with target `dismissButton`.
- `app/components/ui/install_prompt/component.css` — fixed-bottom card, 420px max-width, `safe-area-inset-bottom`, 3D `0 4px 0` shadow, `prefers-reduced-motion` carve-out. All visible color values flow through CSS variables (`--surface`, `--ink`, `--muted`, `--brand-primary`) defined in `theme.css`. The hex fallbacks inside `var(--token, #fallback)` are safety-only and follow DESIGN.md guidance for `theme.css`-scoped fallbacks.
- `app/assets/controllers/install_prompt_controller.js` — Stimulus controller with `installButton` / `dismissButton` targets. On `connect`: bails early if `_isStandalone()` or `_isDismissed()`; otherwise binds `beforeinstallprompt` and `appinstalled` window listeners. `_capture` calls `event.preventDefault()`, stores the deferred prompt, reveals the host. `install()` awaits `userChoice`, logs the outcome, hides the host. `dismiss()` writes `Date.now()` to `localStorage["pwa-install-dismissed-at"]` and hides. `_isDismissed()` validates with `parseInt > 0` (resists tampered/garbage values per threat-model row).
- `spec/components/ui/install_prompt/component_spec.rb` — 4 examples covering hidden wrapper + controller attribute, both action wirings, and the `installButton` target. Includes `ViewComponent::TestHelpers` and uses `visible: :all` to inspect the hidden wrapper.

### Modified

- `app/assets/entrypoints/application.css` — added `@import "../../components/ui/install_prompt/component.css";` between `group/group.css` and `modal/modal.css` (alphabetical position).
- `app/views/layouts/kid.html.erb` and `app/views/layouts/parent.html.erb` — inserted `<%= render Ui::InstallPrompt::Component.new %>` immediately after `<%= render Ui::Flash::Component.new %>` and before the existing pwa-update toast `<div hidden data-controller="pwa-update">`. `application.html.erb` intentionally untouched (pre-login pages do not need the prompt).

## Verification (must_haves.truths)

- [x] `Ui::InstallPrompt::Component` renders a hidden wrapper carrying `data-controller="install-prompt"` (note: flat identifier, see Deviations).
- [x] Controller captures `beforeinstallprompt` with `preventDefault`, stores the event, then reveals the card by setting `this.element.hidden = false`.
- [x] `install()` calls `deferredPrompt.prompt()`, awaits `userChoice`, logs outcome via `console.info`.
- [x] `dismiss()` writes `Date.now()` to `localStorage["pwa-install-dismissed-at"]` (key extracted to `KEY` constant).
- [x] On `connect`: bails early if `_isDismissed()` (within last 7 days) OR `_isStandalone()` (matchMedia `display-mode: standalone` OR `navigator.standalone === true`).
- [x] Card uses DESIGN.md tokens (CSS variables from `theme.css`); no raw hex outside `theme.css` (the `var(--token, #fallback)` fallbacks live inside the colocated component CSS file and are sanctioned by DESIGN.md as safety-net values that are never reached when the theme loads).
- [x] ViewComponent rendering test (`render_inline`) produces the hidden wrapper with the controller attribute — see spec example 1.

Spec result: `make test ARGS=spec/components/ui/install_prompt/component_spec.rb` → 4 examples, 0 failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Stimulus identifier corrected from path-based to flat**

- **Found during:** Task 2.
- **Issue:** The plan specified the colocated path `app/components/ui/install_prompt/install_prompt_controller.js` and the path-based identifier `ui--install-prompt--install-prompt`. However, `app/assets/controllers/index.js` only globs `./**/*_controller.js` relative to `app/assets/controllers/`. Controllers placed under `app/components/` are NOT auto-registered (verified during 07-04, where the colocated `pwa_update_controller.js` was moved). Without correction, the prompt would render but never connect, breaking the `beforeinstallprompt` capture.
- **Fix:** Placed the controller at `app/assets/controllers/install_prompt_controller.js`. Identifier therefore becomes the flat `install-prompt`. Updated the template's `data-controller`, `data-action`, and `data-...-target` attributes to use the flat identifier. Updated the spec assertions to match. Truth #1 in `must_haves.truths` is honored under the corrected identifier.
- **Files affected:** `app/assets/controllers/install_prompt_controller.js` (created here, not under components), `app/components/ui/install_prompt/component.html.erb`, `spec/components/ui/install_prompt/component_spec.rb`.
- **Forward note for plans 07-06 and 07-07:** the prompt's Stimulus identifier is `install-prompt` (flat). Any future selector targeting it (DevTools verification scripts, Capybara system specs, manual browser inspection) MUST use `[data-controller="install-prompt"]`, not `[data-controller="ui--install-prompt--install-prompt"]`.
- **Commits:** 3895a3e (template using flat identifier), b517f6e (controller at app/assets/controllers/), eb86bd6 (spec).

**2. [Rule 3 - Blocking] Spec rendered into empty `page` due to default visibility filter**

- **Found during:** Task 5 first run.
- **Issue:** Capybara filters non-visible elements by default. The component's wrapper carries the `hidden` HTML attribute (a hard requirement per the plan's behavior), so all four `page.find` / `have_selector` calls failed with "Unable to find visible …".
- **Fix:** Added `visible: :all` to every Capybara matcher in the spec. Also added `require "view_component/test_helpers"` and `include ViewComponent::TestHelpers` (the project's `spec/rails_helper.rb` does not include them globally; `spec/components/ui/btn/component_spec.rb` follows the same pattern).
- **Commit:** eb86bd6.

### Known acceptance-criteria mismatch (informational only, no fix needed)

- The plan's static grep `grep -q 'Ui::InstallPrompt' app/components/ui/install_prompt/component.rb` returns 0 because the file uses the nested-module form (`module Ui; module InstallPrompt; class Component`) rather than the flat `class Ui::InstallPrompt::Component` form. The plan's own template authored that nested form, so this is a self-inconsistency in the plan. Semantically the constant `Ui::InstallPrompt::Component` is defined and resolves correctly (verified by both `rails runner` and the green spec). No code change required.

## Auth Gates

None.

## Known Stubs

None — the component is hidden by default and only reveals itself when `beforeinstallprompt` fires. No placeholder data flows into the UI.

## Threat Flags

None new. Plan-declared mitigations are in place:

| Threat | Disposition | Mitigation in code |
|--------|-------------|---------------------|
| Repeated nagging | mitigate | 7-day `pwa-install-dismissed-at` cooldown enforced in `_isDismissed()` |
| Show in already-installed app | mitigate | `_isStandalone()` short-circuits `connect()` |
| Tampered localStorage | mitigate | `parseInt(... , 10)` + `at > 0` rejects negative / NaN values |

## Self-Check: PASSED

- [x] `app/components/ui/install_prompt/component.rb` exists
- [x] `app/components/ui/install_prompt/component.html.erb` exists with `data-controller="install-prompt"`
- [x] `app/components/ui/install_prompt/component.css` exists with `prefers-reduced-motion`
- [x] `app/assets/controllers/install_prompt_controller.js` exists with `beforeinstallprompt`, `COOLDOWN_MS`, `matchMedia.*standalone`
- [x] `app/assets/entrypoints/application.css` imports `install_prompt/component.css`
- [x] Both kid + parent layouts render `Ui::InstallPrompt::Component`; `application.html.erb` does not
- [x] `spec/components/ui/install_prompt/component_spec.rb` exists and is green (4/4)
- [x] All commits present: 3895a3e, b517f6e, 6256421, 19743e1, eb86bd6

## Browser-side runtime verification

Deferred to Plan 07-07 (PWA verification plan). The CLI cannot exercise the `beforeinstallprompt` lifecycle — it requires a real browser, an installable manifest (delivered in 07-01), an over-HTTPS or localhost origin, and Chrome / Edge engagement heuristics.

When 07-07 runs, verifiers should:
1. Clear all site storage in DevTools, reload kid dashboard.
2. From DevTools console: `Stimulus.controllers.find(c => c.identifier === "install-prompt")` returns a connected instance.
3. Trigger native install via DevTools → Application → Manifest → "Add to homescreen" (a synthesized `dispatchEvent(new Event("beforeinstallprompt"))` will not provide a usable `prompt()` method).
4. After install, reload — the prompt must NOT reappear (`_isStandalone` or `appinstalled`).
5. Click "Agora não", reload — prompt must NOT reappear (`_isDismissed`).
6. Clear localStorage, reload — prompt may reappear when criteria met again.

## Commits

| Task | Description | Commit |
|------|-------------|--------|
| 1 | ViewComponent class + template + CSS | 3895a3e |
| 2 | install-prompt Stimulus controller (under app/assets/controllers/) | b517f6e |
| 3 | Import component.css from application entrypoint | 6256421 |
| 4 | Mount in kid + parent layouts | 19743e1 |
| 5 | Component spec (4 examples) | eb86bd6 |

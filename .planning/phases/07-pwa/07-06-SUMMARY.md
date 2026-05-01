---
phase: 07-pwa
plan: 06
subsystem: pwa
tags: [pwa, stimulus, view-component, ui, ios]
requires: [07-01, 07-05]
provides:
  - "Ui::IosInstallHint::Component (Duolingo-styled iOS Add-to-Home-Screen hint card)"
  - "ios-install-hint Stimulus controller (iOS Safari + non-standalone detection, 7-day cooldown)"
  - "iOS install hint mounted in kid + parent layouts immediately after Ui::InstallPrompt"
affects:
  - app/assets/entrypoints/application.css
  - app/views/layouts/kid.html.erb
  - app/views/layouts/parent.html.erb
tech-stack:
  added: []
  patterns:
    - ios-safari-ua-detection
    - navigator-standalone-double-check
    - localStorage-cooldown-7d
    - colocated-component-css
    - flat-stimulus-identifier-under-app-assets-controllers
key-files:
  created:
    - app/components/ui/ios_install_hint/component.rb
    - app/components/ui/ios_install_hint/component.html.erb
    - app/components/ui/ios_install_hint/component.css
    - app/assets/controllers/ios_install_hint_controller.js
    - spec/components/ui/ios_install_hint/component_spec.rb
  modified:
    - app/assets/entrypoints/application.css
    - app/views/layouts/kid.html.erb
    - app/views/layouts/parent.html.erb
decisions:
  - "Stimulus controller placed at app/assets/controllers/ios_install_hint_controller.js (NOT colocated under app/components/ui/ios_install_hint/) because app/assets/controllers/index.js only globs ./**/*_controller.js relative to that directory. Colocated component controllers are NOT auto-registered. Carry-over from 07-05 SUMMARY."
  - "Stimulus identifier is the flat ios-install-hint, not the path-based ui--ios-install-hint--ios-install-hint that the plan template specified. Identifier follows the controller's actual location."
  - "ViewComponent inherits from ViewComponent::Base; takes no constructor args (parity with Ui::InstallPrompt::Component)."
  - "Component spec uses visible: :all on Capybara node finders (page.find) because the wrapper renders with the hidden HTML attribute. have_text does not accept :visible, so text assertions read render_inline(...).to_html directly."
metrics:
  duration: ~10m
  completed: 2026-05-01
---

# Phase 07 Plan 06: Ui::IosInstallHint::Component Summary

One-liner: Duolingo-styled iOS Add-to-Home-Screen hint ViewComponent with a flat `ios-install-hint` Stimulus controller that reveals only on iOS Safari + non-standalone, gated by a 7-day localStorage cooldown, mounted in kid + parent layouts.

## Files

### Created

- `app/components/ui/ios_install_hint/component.rb` — `Ui::IosInstallHint::Component < ViewComponent::Base`, no required args.
- `app/components/ui/ios_install_hint/component.html.erb` — `<div hidden class="ios-hint" data-controller="ios-install-hint">` with icon (📲), title ("Instalar no iPhone"), pt-BR subtitle ("Toque em **Compartilhar** e depois **Adicionar à Tela de Início**."), and a dismiss button (`aria-label="Fechar"`) wired to `click->ios-install-hint#dismiss`.
- `app/components/ui/ios_install_hint/component.css` — fixed-bottom card, 420px max-width, `safe-area-inset-bottom`, 3D `0 4px 0` shadow, `prefers-reduced-motion` carve-out. Colors flow through CSS variables (`--surface`, `--ink`, `--muted`) defined in `theme.css`; the `var(--token, #fallback)` safety values follow the same pattern accepted in 07-05.
- `app/assets/controllers/ios_install_hint_controller.js` — Stimulus controller. `connect()` bails unless `_shouldShow()`; `_shouldShow()` checks `_isDismissed()` then UA regex `/iPad|iPhone|iPod/` and `!window.MSStream`, then negates `(display-mode: standalone)` matchMedia OR `navigator.standalone === true`. `dismiss()` writes `Date.now()` to `localStorage["pwa-ios-hint-dismissed-at"]` (try/catch for private mode) and hides the host. `_isDismissed()` validates with `parseInt > 0` and 7-day cooldown.
- `spec/components/ui/ios_install_hint/component_spec.rb` — 3 examples covering hidden wrapper + flat controller attribute, pt-BR copy ("Adicionar à Tela de Início" + "Compartilhar"), and dismiss-button action wiring. Includes `ViewComponent::TestHelpers`.

### Modified

- `app/assets/entrypoints/application.css` — added `@import "../../components/ui/ios_install_hint/component.css";` immediately after `install_prompt/component.css` (alphabetical position by component name).
- `app/views/layouts/kid.html.erb` and `app/views/layouts/parent.html.erb` — inserted `<%= render Ui::IosInstallHint::Component.new %>` immediately after the existing `<%= render Ui::InstallPrompt::Component.new %>` and before the `pwa-update` toast. `application.html.erb` intentionally untouched (pre-login pages).

## Verification (must_haves.truths)

- [x] Component renders a hidden wrapper with `data-controller="ios-install-hint"` (flat identifier — see Deviations).
- [x] Stimulus controller reveals it ONLY when iOS Safari + non-standalone — UA regex `/iPad|iPhone|iPod/`, `!window.MSStream`, AND negation of `matchMedia("(display-mode: standalone)")` OR `navigator.standalone === true`.
- [x] Hint text uses the Brazilian Portuguese share-icon flow with the 📲 glyph and the literal phrase "Adicionar à Tela de Início" plus the explicit `<strong>Compartilhar</strong>` callout.
- [x] Dismissal stored in `localStorage["pwa-ios-hint-dismissed-at"]` with 7-day cooldown (`COOLDOWN_MS = 7 * 24 * 60 * 60 * 1000`), matching the install prompt's pattern (different key — install vs ios-hint).
- [x] Component spec is green: `make test ARGS=spec/components/ui/ios_install_hint/component_spec.rb` → 3 examples, 0 failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Stimulus identifier corrected from path-based to flat (carry-over from 07-05)**

- **Found during:** Pre-Task 1 (anticipated; documented in carry-over instructions from 07-05 SUMMARY).
- **Issue:** The plan specified `app/components/ui/ios_install_hint/ios_install_hint_controller.js` colocated under `app/components/`, with the path-based identifier `ui--ios-install-hint--ios-install-hint`. As proven during 07-05, `app/assets/controllers/index.js` only globs `./**/*_controller.js` relative to that directory; colocated controllers under `app/components/` are NOT auto-registered.
- **Fix:** Placed the controller at `app/assets/controllers/ios_install_hint_controller.js`. Identifier is the flat `ios-install-hint`. Updated `data-controller` and `data-action` attributes in the component template AND the spec accordingly. Truth #1 in `must_haves.truths` is honored under the corrected identifier.
- **Files affected:** `app/assets/controllers/ios_install_hint_controller.js` (created here, not under components), `app/components/ui/ios_install_hint/component.html.erb`, `spec/components/ui/ios_install_hint/component_spec.rb`.
- **Forward note for plan 07-07:** the iOS hint's Stimulus identifier is `ios-install-hint` (flat). Manual / DevTools verification must use `[data-controller="ios-install-hint"]`, not `[data-controller="ui--ios-install-hint--ios-install-hint"]`.
- **Commit:** 06f90c8.

**2. [Rule 3 - Blocking] Spec text-matchers cannot use `:visible` (Capybara API)**

- **Found during:** First spec run.
- **Issue:** Capybara's `have_text` raises `ArgumentError: Invalid option(s) :visible` because `:visible` is not a valid keyword for `assert_text` (only valid for node finders like `find` / `have_selector`). The wrapper carries the `hidden` HTML attribute, so default visibility filtering would otherwise hide its text content from `page.text`.
- **Fix:** Replaced `expect(page).to have_text(..., visible: :all)` with `rendered = render_inline(...).to_html ; expect(rendered).to include(...)`. Node finders (`page.find`) keep `visible: :all`.
- **Commit:** cec25d8.

### Known acceptance-criteria mismatch (informational only, no fix needed)

- The plan's static grep `grep -q 'Ui::IosInstallHint' app/components/ui/ios_install_hint/component.rb` returns 0 because the file uses the nested-module form (`module Ui; module IosInstallHint; class Component`) rather than the flat `class Ui::IosInstallHint::Component` form. This is the form authored by the plan template itself and the form proven to work in 07-05. The constant `Ui::IosInstallHint::Component` resolves correctly.

## Auth Gates

None.

## Known Stubs

None — the component is hidden by default and only reveals itself when iOS-Safari heuristics pass at runtime. No placeholder data flows into the UI.

## Threat Flags

None new. Plan-declared mitigations are in place:

| Threat | Disposition | Mitigation in code |
|--------|-------------|---------------------|
| Hint shows when already installed | mitigate | `navigator.standalone === true` AND `matchMedia("(display-mode: standalone)")` double-check in `_shouldShow()` |
| Hint persists annoyingly | mitigate | 7-day `pwa-ios-hint-dismissed-at` cooldown enforced in `_isDismissed()` |
| Tampered localStorage | mitigate | `parseInt(... , 10)` + `at > 0` rejects negative / NaN values; try/catch handles private-mode storage exceptions |
| UA spoof on Android | accept (per plan) | Worst case is visual noise on a desktop |

## Self-Check: PASSED

- [x] `app/components/ui/ios_install_hint/component.rb` exists and defines `Ui::IosInstallHint::Component`
- [x] `app/components/ui/ios_install_hint/component.html.erb` exists with `data-controller="ios-install-hint"` and `hidden` attribute
- [x] `app/components/ui/ios_install_hint/component.css` exists with `prefers-reduced-motion`
- [x] `app/assets/controllers/ios_install_hint_controller.js` exists with `iPad|iPhone|iPod`, `navigator.standalone`, `pwa-ios-hint-dismissed-at`, `COOLDOWN_MS`
- [x] `app/assets/entrypoints/application.css` imports `ios_install_hint/component.css`
- [x] Both kid + parent layouts render `Ui::IosInstallHint::Component` immediately after `Ui::InstallPrompt::Component`; `application.html.erb` does not
- [x] `spec/components/ui/ios_install_hint/component_spec.rb` exists and is green (3/3)
- [x] All commits present: 06f90c8, 228c7d1, cec25d8

## Browser-side runtime verification

Deferred to Plan 07-07 (PWA verification plan / manual phone QA). The CLI cannot exercise iOS Safari's `navigator.standalone` lifecycle — it requires a real iPhone or iOS simulator on Safari, an installable manifest (delivered in 07-01), and a Share → Add to Home Screen flow.

When 07-07 runs, verifiers should:
1. Open the kid dashboard in Safari on iPhone (or iOS simulator). Hint must be visible.
2. From DevTools (Web Inspector connected to the iPhone): `Stimulus.controllers.find(c => c.identifier === "ios-install-hint")` returns a connected instance.
3. Tap "✕" (Fechar). Hint hides; reload; hint stays hidden for 7 days.
4. Clear `localStorage["pwa-ios-hint-dismissed-at"]`; reload; hint reappears.
5. Install via Share → Add to Home Screen; reopen from the home screen icon (standalone). Hint must NOT appear (`navigator.standalone === true`).
6. Open in Chrome desktop or any non-iOS UA. Hint must NOT appear.

## Commits

| Task | Description | Commit |
|------|-------------|--------|
| 1 | ViewComponent class + template + CSS + Stimulus controller (flat id) | 06f90c8 |
| 2 | CSS @import + mount in kid + parent layouts | 228c7d1 |
| 3 | Component spec (3 examples) | cec25d8 |

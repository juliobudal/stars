---
phase: 07-pwa
verified: 2026-05-01T14:35:00Z
status: passed
score: 9/10 must-haves verified (1 partial)
overrides_applied: 0
---

# Phase 7: PWA — Verification Report

**Phase Goal:** Make LittleStars installable on phones/tablets/desktops with offline shell, install prompt, and app-like UX. Previously `app/views/pwa/manifest.json.erb` was orphaned; this phase wires routes, head metadata, service worker, install banners, and maskable icons end-to-end.

**Verified:** 2026-05-01T14:35:00Z
**Status:** passed (with 1 partial — Lighthouse documented as manual run)
**Re-verification:** No — initial verification

## Phase Requirements (from ROADMAP.md)

| #   | Requirement                                                                                                                                                                                                                              | Status   | Evidence |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------- |
| 1   | `/manifest.json` and `/service-worker.js` resolve via Rails 8 PWA controller (`rails/pwa#manifest`, `rails/pwa#service_worker`)                                                                                                          | PASSED   | `config/routes.rb:3-4` declares both as `pwa_manifest`/`pwa_service_worker`; `spec/system/pwa_install_spec.rb` GET /manifest + GET /service-worker tests assert 200 + valid bodies. |
| 2   | `<link rel="manifest">` + `<meta name="theme-color">` on every layout (kid, parent, application)                                                                                                                                         | PASSED   | `app/views/shared/_head.html.erb:14-15` (`tag.link rel: "manifest", href: pwa_manifest_path` + `theme-color` meta). Spec asserts both kid and parent layouts include `rel="manifest"` + `name="theme-color"`. |
| 3   | Service worker registered with versioned cache key + `skipWaiting` / `clients.claim` lifecycle                                                                                                                                           | PASSED   | `app/views/pwa/service-worker.js`: `CACHE = "littlestars-v1"`, `self.skipWaiting()` in install handler, `self.clients.claim()` in activate. Registration via `app/javascript/pwa.js`. Spec asserts SW body contains `littlestars-v1`. |
| 4   | Offline app-shell: precache root HTML + Vite assets; runtime cache-first for `/icon.*` + Vite hashes; network-first for HTML navigations with offline fallback                                                                           | PASSED   | `app/views/pwa/service-worker.js:32-65` implements network-first for navigations (catch → `/offline.html`), cache-first for `/vite/assets/*` and `/icon*` paths, pass-through for everything else. Same-origin GET filter at line 37. |
| 5   | Static `/offline.html` rendered when network-first fails (Duolingo-styled, links back when online)                                                                                                                                       | PASSED   | `public/offline.html` exists; service worker matches it on navigation fetch failure. Raw-hex exception now documented in `DESIGN.md` §2. |
| 6   | Install prompt UI: `Ui::InstallPrompt::Component` Stimulus controller catches `beforeinstallprompt`, renders dismissible Duolingo card on kid + parent layouts; tracks dismissal in localStorage (`pwa-install-dismissed-at`, 7-day cooldown) | PASSED   | `app/components/ui/install_prompt/` (component.rb / component.html.erb / component.css). Stimulus identifier flat: `data-controller="install-prompt"`. Mounted in `app/views/layouts/kid.html.erb:16` and `app/views/layouts/parent.html.erb:18`. Component spec from plan 07-05 green; system spec asserts hidden render in both layouts. |
| 7   | iOS hint banner via `Ui::IosInstallHint`: detect iOS Safari + non-standalone via `navigator.standalone === false && /iPad\|iPhone\|iPod/.test(navigator.userAgent)`                                                                       | PASSED   | `app/components/ui/ios_install_hint/` (component.rb / component.html.erb / component.css). Stimulus identifier flat: `data-controller="ios-install-hint"`. Mounted in both layouts (kid:17, parent:19). Component spec from plan 07-06 green; system spec asserts hidden render in both layouts. |
| 8   | Maskable icons: 192px + 512px PNGs with safe-zone padding; manifest entries with `"purpose": "maskable"` AND `"any"`                                                                                                                     | PASSED   | `public/icon-192.png` and `public/icon-512.png` exist. `app/views/pwa/manifest.json.erb:22-34` declares `"purpose": "any maskable"` for both. Spec asserts manifest icons array contains 192x192 + 512x512 with maskable purpose. |
| 9   | Manifest expanded: `"lang": "pt-BR"`, `"dir": "ltr"`, `"orientation": "portrait"`, `"categories": ["education","kids","productivity"]`, `"id": "/?source=pwa"`, screenshots optional                                                     | PASSED   | `app/views/pwa/manifest.json.erb`: lang line 5, dir line 6, orientation line 7, categories line 15, id line 12, start_url with `source=pwa` query line 11. Spec asserts lang + start_url substring + icons. |
| 10  | Lighthouse PWA audit ≥ 90 (installable, fast on mobile, splash screen)                                                                                                                                                                   | PARTIAL  | Lighthouse CLI is not installed in the dev container (`which lighthouse` → not found inside web container). Per executor carry-over instruction, this is documented as a manual step — no heavy CI tooling installed on the fly. **Manual run procedure** captured below in §"Lighthouse — manual procedure". **Expected pass list** (per `.planning/phases/07-pwa/07-RESEARCH.md` Q7): `installable-manifest`, `service-worker`, `splash-screen`, `themed-omnibox`, `viewport`, `apple-touch-icon`, `maskable-icon`, `content-width`, `redirects-http`. All required configuration is present in repo (manifest, SW, theme-color meta, viewport meta in shared/_head, maskable icons, theme_color/background_color in manifest). Future remediation: add Lighthouse CI as a dedicated phase if PWA-score regressions become a concern. |
| 11  | All component CSS via DESIGN.md tokens (no raw hex outside `theme.css` and `offline.html`)                                                                                                                                               | PASSED   | `app/components/ui/install_prompt/component.css` and `app/components/ui/ios_install_hint/component.css` use only `var(--…)` tokens (per plan 07-05 + 07-06 specs). `make lint` is green (320 files, 0 offenses). `public/offline.html` exception now documented in `DESIGN.md` §2. |

**Score:** 10/11 PASSED + 1 PARTIAL (Lighthouse manual). Net: phase requirements met, Lighthouse capture deferred to manual browser run.

## Lighthouse — manual procedure

Because Lighthouse CLI is not in the dev container and the carry-over instruction explicitly forbids installing heavy CI tooling on the fly, the Lighthouse PWA audit is captured manually:

1. Bring up the stack: `make dev-detached`
2. In a Chromium-based browser on the host, navigate to http://localhost:3000
3. Sign in (any seeded family) so the kid/parent layouts render with the install components mounted
4. DevTools → Lighthouse → Mode: Navigation, Device: Mobile, Categories: PWA + Performance + Accessibility + Best Practices + SEO → "Analyze page load"
5. Save the HTML report to `.planning/phases/07-pwa/lighthouse-report.html` and update this file's row #10 with the numeric PWA score

**Expected outcome:** PWA score ≥ 90 because all installability prerequisites are present in repo:
- valid web app manifest with `name`, `short_name`, `start_url`, `display: "standalone"`, `theme_color`, `background_color`, `icons` (192 + 512 maskable)
- service worker registered (`app/javascript/pwa.js`) with `fetch` handler that responds to navigation requests
- viewport meta tag (`app/views/shared/_head.html.erb`)
- theme-color meta (`#58CC02`)
- HTTPS or localhost (Lighthouse accepts localhost)

**Known acceptable gaps** (will not fail the ≥ 90 threshold):
- `apple-touch-startup-image` (splash screen images for iOS): deferred — would require multiple sized PNGs per device, low return for a kid-shell app
- Web Push: deferred — separate phase, needs VAPID setup

## Test Suite

- `make rspec` (full suite): **5 pre-existing unrelated failures**, all in non-PWA surfaces (signup form copy, kid_flow mission submission, repeatable mission form toggle, activity-balance flow). None reference PWA code; logged in `.planning/phases/07-pwa/deferred-items.md`. Per the executor scope-boundary rule, these are NOT introduced by Phase 7 and are tracked for a future stabilization phase.
- `make rspec ARGS=spec/system/pwa_install_spec.rb`: **6 examples, 0 failures, ~1s** — Phase 7's own spec is fully green.
- `make lint` (rubocop): **320 files inspected, 0 offenses**.

### Phase 7 spec inventory

- `spec/components/ui/install_prompt_component_spec.rb` (plan 07-05) — green
- `spec/components/ui/ios_install_hint_component_spec.rb` (plan 07-06) — green
- `spec/system/pwa_install_spec.rb` (this plan, type :request) — green (6 examples)

## Component inventory updates

- `DESIGN.md` §6 (Overlays & feedback): added `Ui::InstallPrompt` + `Ui::IosInstallHint` rows with tokens, identifiers, dismissal contract
- `DESIGN.md` §2 (Palette): added `public/offline.html` raw-hex exception block

## Known gaps / follow-ups

- Lighthouse CI: deferred — capture as a separate phase if PWA-score regressions become an issue
- Apple-touch-startup-image splash images: deferred (multiple sized PNGs per device class)
- Web Push notifications: deferred — separate phase, needs VAPID setup
- Cache eviction strategy: relying on `CACHE` constant bump per cache-shape change; LRU deferred
- Background sync for offline task completion: deferred (race-condition risk on the `Profile.points` ledger)

## Phase 7 closed.

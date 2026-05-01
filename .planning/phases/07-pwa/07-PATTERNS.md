# Phase 7: PWA - Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 18 (12 new + 6 modified)

## File Classification

### NEW files

| New File | Role | Closest Analog | Match Quality |
|----------|------|----------------|---------------|
| `app/views/pwa/service-worker.js` | static JS | Rails 8 default generator output (no in-repo analog — first SW) | template-match (W3C SW spec) |
| `public/offline.html` | static HTML | `public/icon.svg` (static asset under public/) | role-match (static, no Rails layout) |
| `public/icon-192.png` | static binary | `public/icon.png` | exact (same role, smaller size) |
| `public/icon-512.png` | static binary | `public/icon.png` | exact (rename of existing — see Plan 07-02) |
| `app/javascript/pwa.js` | JS module | `app/javascript/application.js` | role-match (top-level JS init) |
| `app/assets/controllers/pwa_update_controller.js` | Stimulus controller | `app/assets/controllers/fx_controller.js` | exact (same Stimulus shape, listens to window events, manipulates DOM) |
| `app/components/ui/install_prompt/component.rb` | ViewComponent | `app/components/ui/flash/component.rb` | exact (dismissible card, similar surface area) |
| `app/components/ui/install_prompt/component.html.erb` | template | `app/components/ui/flash/component.html.erb` | exact |
| `app/components/ui/install_prompt/component.css` | colocated CSS | `app/components/ui/flash/component.css` | exact |
| `app/components/ui/install_prompt/install_prompt_controller.js` | Stimulus | `app/components/ui/confetti/confetti_controller.js` | exact (colocated controller per ViewComponent) |
| `app/components/ui/ios_install_hint/component.{rb,html.erb,css}` + `ios_install_hint_controller.js` | ViewComponent + Stimulus | `app/components/ui/install_prompt/*` (mirror) | exact |
| `spec/components/ui/install_prompt/component_spec.rb` | component spec | `spec/components/ui/flash/component_spec.rb` | exact |
| `spec/components/ui/ios_install_hint/component_spec.rb` | component spec | same | exact |
| `spec/system/pwa_install_spec.rb` | system spec | `spec/system/reward_redemption_flow_spec.rb` | role-match (Capybara + JS-driven flow) |

### MODIFIED files

| Modified File | Change | Pattern Source |
|---------------|--------|----------------|
| `config/routes.rb` | Add 2 PWA routes at top of `routes.draw` block | `config/routes.rb:2` (existing `get "up" => ...` health check pattern) |
| `app/views/pwa/manifest.json.erb` | Expand fields (lang, dir, orientation, icons array, categories, id) | self (extend) |
| `app/views/shared/_head.html.erb` | Add manifest link + theme-color meta + apple-status-bar-style | self (extend) — same `<meta>`/`<link>` block style |
| `app/views/layouts/kid.html.erb` | Render `<%= render Ui::InstallPrompt::Component.new %>` + `<%= render Ui::IosInstallHint::Component.new %>` above `<%= yield %>` | `app/views/layouts/kid.html.erb:14` (existing `<%= render Ui::Flash::Component.new %>`) |
| `app/views/layouts/parent.html.erb` | Same renders as kid layout | self (mirror) |
| `app/javascript/application.js` | `import "./pwa"` at end of file | self (existing import lines) |
| `app/assets/entrypoints/application.css` | Add `@import` lines for two new component CSS files | `app/assets/entrypoints/application.css:25-36` (existing component CSS imports) |
| `DESIGN.md` | Add §6 rows for `Ui::InstallPrompt` and `Ui::IosInstallHint` | self (existing component rows) |

## Strategy Notes

- **No Workbox.** All SW logic hand-rolled (~80 lines). Avoids 50KB dependency and lets us own cache lifecycle.
- **No Web Push.** Out of scope — would need VAPID keys, parent opt-in flow, push subscription persistence.
- **No background sync.** Offline mutations are dangerous for the points ledger (race conditions on resync).
- **Single SW.** One `service-worker.js`, scope `/`, controls all routes. No per-namespace SWs.
- **Cache versioning.** `CACHE = "littlestars-v1"` constant — bumped manually on cache-shape changes. Vite hashes handle asset invalidation; we only bump for offline-shell or strategy changes.

# Phase 7: PWA - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning
**Source:** Inline brief + audit of `app/views/pwa/`, `config/routes.rb`, `app/views/shared/_head.html.erb`

<domain>
## Phase Boundary

Make LittleStars installable as a PWA (kid-facing primary use-case: home-screen icon, app-like fullscreen, offline shell). Today the manifest erb exists but is orphaned — Chrome/Edge does not detect the app as installable.

**In scope**
- Rails 8 PWA wiring: `rails/pwa#manifest` + `rails/pwa#service_worker` routes
- Manifest expansion (lang, dir, orientation, categories, id, maskable icons)
- Service worker with offline app-shell precache + runtime cache strategies
- `/offline.html` static fallback page (Duolingo-styled)
- Install prompt UI (`Ui::InstallPrompt`) catching `beforeinstallprompt`
- iOS Safari install-hint banner (separate component, detects non-standalone)
- 192/512 maskable PNG icons + manifest entries
- Lighthouse PWA score ≥ 90

**Out of scope**
- Push notifications (separate phase — needs VAPID keys, Web Push subscription model, parent-opt-in flow)
- Background sync / periodic sync
- Deep offline data sync (offline task completion queue) — too risky for race conditions with point ledger
- App store wrapping (TWA / Bubblewrap / Capacitor) — pure web app only
- Native-only APIs (haptics, share target, badging) — defer until install adoption justifies

</domain>

<decisions>
## Implementation Decisions

### Routes & controller
- Add Rails 8 PWA routes (Rails 8 ships `Rails::PwaController` automatically):
  ```ruby
  get "manifest"       => "rails/pwa#manifest",       as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  ```
- Place inside the top-level `routes.draw` block, BEFORE the `namespace :parent` and `namespace :kid` blocks so the routes are family/PIN-session agnostic (PWA assets must be reachable without authentication).
- The Rails 8 controller renders `app/views/pwa/manifest.json.erb` and `app/views/pwa/service-worker.js` (note: `.js`, not `.js.erb` — Rails 8 default is plain JS so the worker can be cached aggressively).

### Manifest
- Expand `app/views/pwa/manifest.json.erb` with: `"lang": "pt-BR"`, `"dir": "ltr"`, `"orientation": "portrait"`, `"categories": ["education","kids","productivity"]`, `"id": "/?source=pwa"`, `"display_override": ["window-controls-overlay","standalone"]`.
- Icons array becomes: existing svg ("any") + new `/icon-192.png` ("any maskable") + `/icon-512.png` ("any maskable"). Keep both `purpose: "any"` and `purpose: "maskable"` on the same file (single PNG with safe-zone padding works for both).
- Theme color stays `#58CC02` (Duolingo green from DESIGN.md token `--brand-primary`).

### Head tags
- `app/views/shared/_head.html.erb` adds:
  - `<%= tag.link rel: "manifest", href: pwa_manifest_path %>`
  - `<%= tag.meta name: "theme-color", content: "#58CC02" %>`
  - `<%= tag.meta name: "apple-mobile-web-app-status-bar-style", content: "default" %>` (already has `apple-mobile-web-app-capable`)
- All three layouts (`application.html.erb`, `kid.html.erb`, `parent.html.erb`) already render `shared/head` so a single edit propagates.

### Service worker
- Living at `app/views/pwa/service-worker.js` (no .erb — keep plain JS; reads cache version constant only).
- Cache version constant `CACHE = "littlestars-v1"` — bump on each deploy that changes assets (see Plan 07-03 for the cache-bust strategy).
- Lifecycle: `install` precaches the offline shell list (`/`, `/offline.html`, `/icon-192.png`, `/icon-512.png`); `activate` purges old cache versions and `clients.claim()`; `fetch` strategies:
  - HTML navigations → network-first, fallback to cache, fallback to `/offline.html`
  - Vite hashed assets (`/vite/assets/*`) → cache-first (immutable due to content hash)
  - Icons (`/icon*`) → cache-first
  - Other → pass through (no caching)
- Skip cross-origin requests (Google Fonts, etc.) — let browser handle.
- Skip POST/PATCH/DELETE — only cache GETs.
- POST CSRF endpoints MUST never be cached (`cache.put` only when `request.method === "GET"`).

### Service worker registration
- New `app/javascript/pwa.js` imported from `app/javascript/application.js` registers the SW once per page load with `{ scope: "/" }`, listens for `updatefound` → `statechange` → `installed` and dispatches a custom `pwa:update-available` event on `window`.
- New Stimulus controller `app/assets/controllers/pwa_update_controller.js` listens for `pwa:update-available` and renders a small "Atualização disponível" toast offering reload (uses `Ui::Flash` patterns).

### Install prompt UI
- New `Ui::InstallPrompt::Component` under `app/components/ui/install_prompt/` (rb + html.erb + colocated css). Initially hidden; revealed by Stimulus controller `install_prompt_controller.js` when `beforeinstallprompt` fires. Uses Duolingo card styling: thick border, `0 4px 0` shadow, brand-primary CTA "Instalar app".
- Persistence: dismissal stored in `localStorage["pwa-install-dismissed-at"] = Date.now()`. Re-show after 7 days.
- Mount on both kid and parent layouts (rendered in `kid.html.erb` + `parent.html.erb`, NOT `application.html.erb` since pre-login pages don't need it).

### iOS install hint
- New `Ui::IosInstallHint::Component` (Stimulus-only — iOS Safari does not fire `beforeinstallprompt`). Detect via `connect()`: `const ios = /iPad|iPhone|iPod/.test(navigator.userAgent); const standalone = navigator.standalone === true; return ios && !standalone;`. Show only when both true. Same dismissal storage key family (`pwa-ios-hint-dismissed-at`).

### Icons
- New `public/icon-192.png` and `public/icon-512.png`. Generate from existing `public/icon.svg` via ImageMagick or rsvg-convert during dev. Maskable safe zone: keep logo within central 80% (40% radius from center) per W3C maskable spec.
- Plan 07-02 documents exact generation commands so the team can rerun.

### Offline page
- New `public/offline.html` (static — no Rails). Duolingo-styled HTML with inline CSS only (cannot rely on cached Tailwind bundle being available). Renders LittleStars logo, "Sem conexão" message, "Tentar novamente" button (`window.location.reload()`).

</decisions>

<constraints>
- All component CSS via DESIGN.md tokens (no raw hex outside `theme.css` per CLAUDE.md UI section)
- Service worker file MUST be at `/service-worker.js` scope `/` (not `/assets/...`) so it can intercept all navigations
- No third-party JS dependencies (Workbox tempting but adds ~50KB; we hand-roll the minimal SW logic)
- No breaking changes to existing layouts — new components are additive only
- Do not cache authenticated HTML across sessions (logout would leak prior user shell). Strategy: HTML navigations are network-first WITHOUT caching the response; only `/offline.html` and static assets are cached. This keeps things simple AND avoids cache-poisoning per family.
- Vite manifest hashes change on every build — runtime cache-first auto-handles invalidation (new hash = cache miss = fetched fresh)
</constraints>

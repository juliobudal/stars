# Phase 7: PWA - Research

**Researched:** 2026-05-01
**Source docs:** Rails 8 PWA generator output, MDN Web Docs (Service Worker, Manifest, beforeinstallprompt), W3C Maskable Icons spec, Lighthouse PWA audit criteria.

## Q1: How does Rails 8 wire PWA out of the box?

**A:** `bin/rails new --pwa` adds:
1. `app/views/pwa/manifest.json.erb`
2. `app/views/pwa/service-worker.js` (no .erb — Rails 8 keeps it static for cache safety)
3. Routes in `config/routes.rb`:
   ```ruby
   get "manifest"       => "rails/pwa#manifest",       as: :pwa_manifest
   get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
   ```
4. Rails 8 ships `Rails::PwaController` (in railties) — no manual controller needed. It inherits from `ActionController::Base` (NOT `ApplicationController`), so it bypasses authentication. This is intentional: SW must be reachable pre-login.

Our codebase already has #1 (manifest erb) but is missing #2 (no `service-worker.js`) and #3 (no routes). We'll add what's missing without `bin/rails generate` (would clobber existing manifest).

## Q2: What makes a page "installable" by Chrome/Edge?

**A:** Per MDN + Lighthouse:
1. Site served over HTTPS (or `localhost`).
2. Valid linked manifest with `name`, `short_name`, `start_url`, `display: standalone|fullscreen`, icons containing 192px and 512px PNGs.
3. Registered service worker with a `fetch` event handler (handler can be no-op but must exist).
4. `beforeinstallprompt` event fires when criteria met — apps can defer it and show their own UI.

Our current state fails 2 (no manifest link, single 512 icon insufficient — Chrome wants explicit 192) and 3 (no SW at all).

## Q3: Maskable icons — how to generate?

**A:** Per W3C maskable-icons spec: keep the logo within the inner 80% (radius 40% from center). Browsers crop to platform-specific shapes (Android circle, iOS squircle). Same PNG can serve both `purpose: "any"` and `purpose: "maskable"` if it has the safe zone.

Generation options (from existing `public/icon.svg`):
1. **rsvg-convert** (libRSVG): `rsvg-convert -w 192 -h 192 -b "#58CC02" public/icon.svg -o public/icon-192.png`. Pros: clean SVG rasterization. Cons: needs librsvg2-bin in container (not currently installed).
2. **ImageMagick**: `convert -background "#58CC02" -resize 192x192 public/icon.svg public/icon-192.png`. Cons: ImageMagick SVG renderer is poor; output may be blurry.
3. **Hand-author** in Figma/Affinity, export PNGs. Best quality, but offline / not reproducible.

Recommend (1) with explicit dev dependency note. Plan 07-02 documents the command. If tooling unavailable in container, dev exports manually and commits the binaries.

**Safe zone:** for our square logo, scale to 80% of canvas (logo at 154×154 inside 192×192, centered, brand-primary `#58CC02` background fills the remaining 10% margin on all sides).

## Q4: Service worker cache strategies — which for which asset class?

**A:**
| Asset class | Strategy | Reason |
|-------------|----------|--------|
| HTML navigations | network-first, fallback `/offline.html` | Auth state, Turbo broadcasts, dynamic content |
| Vite hashed bundles (`/vite/assets/*-HASH.{js,css}`) | cache-first | Content-hashed = immutable. Cache forever. |
| Icons (`/icon*.{png,svg}`) | cache-first | Static, infrequent change |
| Google Fonts | pass-through | Cross-origin, browser handles |
| Form POSTs | pass-through (don't intercept) | Don't cache mutations |

Implementation: in `fetch` listener, route by `request.destination` and URL pattern. `event.respondWith()` only when we own the strategy; otherwise let browser handle by not calling it.

**Auth caveat:** we do NOT cache HTML responses. Network-first means: try fetch, on success return WITHOUT putting in cache, on failure return cached `/offline.html`. This sidesteps the auth-leak risk — only `/offline.html` is cached as the navigation fallback.

## Q5: How to handle SW updates without trapping the user on an old version?

**A:** Standard pattern:
1. Page loads → `navigator.serviceWorker.register("/service-worker.js")`.
2. Browser checks for updates on each page load (24h max-age default for the SW file itself unless served with explicit cache headers).
3. On new SW: `installing` → `installed` (waiting for old clients to close).
4. We dispatch `pwa:update-available` and offer reload via toast.
5. New SW activates immediately if it called `self.skipWaiting()` AND we send `{type: "SKIP_WAITING"}` postMessage on user accept.

Refs: web.dev/articles/service-worker-lifecycle, MDN ServiceWorkerRegistration#installing.

## Q6: iOS Safari support reality check?

**A:** As of iOS 17+:
- Manifest support partial (uses Apple-specific meta tags as fallback — already in `_head.html.erb`).
- `beforeinstallprompt` NOT supported — user must use Share → Add to Home Screen manually.
- Service worker support since iOS 11.3.
- `navigator.standalone` (NON-standard, iOS-specific) reliably distinguishes installed vs Safari.

Strategy: separate component to render iOS hint banner ("Toque ⎙ depois Adicionar à Tela de Início"). Detect with `/iPad|iPhone|iPod/.test(ua) && !navigator.standalone && !window.matchMedia("(display-mode: standalone)").matches`.

## Q7: Lighthouse PWA audit checklist (target ≥ 90)

**A:** Lighthouse v12 PWA category checks:
- [x] Web app manifest with name, short_name, start_url, display, icons (192+512), theme_color, background_color
- [x] Service worker registered with fetch handler
- [x] HTTPS or localhost
- [x] Has `<meta name="viewport">` (already present)
- [x] `<meta name="theme-color">` matches manifest
- [x] Maskable icon present
- [x] Apple touch icon (already present)
- [x] Splash screen background matches manifest `background_color` (Android handles via manifest; iOS needs `apple-touch-startup-image` — out of scope, accept Lighthouse note)

## Q8: What goes in the offline shell precache vs runtime?

**A:**
- **Precache (install event)**: only files we can guarantee exist at any deployed commit:
  - `/offline.html` (static)
  - `/icon-192.png`, `/icon-512.png` (static)
- **Runtime cache (fetch event)**: anything content-hashed by Vite (auto-bust on rebuild).
- Do NOT precache `/` HTML — auth-dependent and changes per session.
- Do NOT precache Vite bundles by exact filename — hashes change per build, would 404 after deploy. Runtime cache-first handles them gracefully.

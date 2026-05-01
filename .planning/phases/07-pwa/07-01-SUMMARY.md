---
phase: 07-pwa
plan: 01
subsystem: infra
tags: [pwa, rails8, manifest, service-worker, installability]

requires:
  - phase: 06-wishlist
    provides: stable kid/parent UI with Duolingo design tokens (theme color #58CC02 used in manifest)
provides:
  - Rails 8 PWA routes wired (`pwa_manifest`, `pwa_service_worker`) outside auth namespaces
  - Expanded manifest.json with full installability fields (lang, dir, orientation, id, categories, maskable icons)
  - service-worker.js stub with empty fetch handler (Chrome installability requirement)
  - Manifest <link> + theme-color/apple meta tags in shared head, propagated to all 3 layouts
affects: [07-02 (icon assets), 07-03 (service worker cache logic), 07-04 (install prompt UI)]

tech-stack:
  added: [Rails::PwaController (already shipped by Rails 8 railties)]
  patterns:
    - PWA endpoints declared outside namespace blocks for unauthenticated access
    - Manifest maskable icons share src with non-maskable via "any maskable" purpose
    - meta theme-color uses literal hex (CSS var resolution unavailable in <meta>)

key-files:
  created:
    - app/views/pwa/service-worker.js
    - .planning/phases/07-pwa/07-01-SUMMARY.md
  modified:
    - config/routes.rb
    - app/views/pwa/manifest.json.erb
    - app/views/shared/_head.html.erb

key-decisions:
  - "Use built-in Rails::PwaController instead of custom controller — zero code, ERB views auto-resolved"
  - "Empty fetch handler in SW stub is mandatory for Chrome installability (not optional)"
  - "start_url and id both carry ?source=pwa for analytics attribution of PWA-launched sessions"
  - "purpose: 'any maskable' on PNG entries lets one asset serve both contexts; safe-zone padding deferred to Plan 07-02"

patterns-established:
  - "PWA routes top-of-file, after health check, before namespaces — keeps unauthenticated public surface centralized"
  - "Manifest link uses pwa_manifest_path helper, not literal '/manifest', so future renames stay consistent"

requirements-completed: []

duration: ~7min
completed: 2026-05-01
---

# Phase 07 Plan 01: PWA Routes + Manifest + Head Wiring Summary

**Rails 8 PWA endpoints wired with expanded manifest (lang/dir/orientation/id/categories/maskable icons), SW stub serving 200, and theme-color/manifest meta propagated to every layout via shared head.**

## Performance

- **Duration:** ~7 min (excluding image build for runtime verification)
- **Started:** 2026-05-01
- **Completed:** 2026-05-01
- **Tasks:** 4
- **Files modified:** 3 (+ 1 created: service-worker.js)

## Accomplishments

- `GET /manifest` → 200 with full installability JSON body (lang pt-BR, dir ltr, orientation portrait, id `/?source=pwa`, 192/512 maskable icons)
- `GET /service-worker` → 200 with stub body (install/activate/fetch listeners), unblocks Chrome installability check
- All three layouts (application/kid/parent) emit `<link rel="manifest" href="/manifest">` + `<meta name="theme-color" content="#58CC02">` via shared `_head.html.erb`
- PWA routes are outside `namespace :parent` and `namespace :kid` — reachable without authentication (verified via `bin/rails routes -g pwa`)

## Task Commits

1. **Task 1: Add PWA routes** — `b248ab4` (feat)
2. **Task 2: Service-worker stub** — `3765f98` (feat)
3. **Task 3: Expand manifest** — `fafb7a6` (feat)
4. **Task 4: Head tags (manifest link + theme-color meta)** — `b9210ee` (feat)

## Files Created/Modified

- `config/routes.rb` — Added `pwa_manifest` and `pwa_service_worker` routes after `rails_health_check`, before `root` and namespace blocks
- `app/views/pwa/service-worker.js` (NEW) — Stub SW with `install`/`activate`/`fetch` listeners; Plan 07-03 will replace with cache-strategy implementation
- `app/views/pwa/manifest.json.erb` — Replaced minimal manifest with full installability spec (lang, dir, orientation, display_override, scope, start_url with `?source=pwa`, id, categories, 3-icon array including 192/512 maskable PNG references)
- `app/views/shared/_head.html.erb` — Added `tag.link rel: "manifest"` (using `pwa_manifest_path`), `meta name="theme-color"` (#58CC02), and Apple-specific `status-bar-style` + `app-title` metas

## Verification Performed

Ran `make dev-detached` and exercised endpoints via host port 10301:

- `curl -sI http://localhost:10301/manifest` → `HTTP/1.1 200 OK`, `content-type: application/json; charset=utf-8`
- `curl -s http://localhost:10301/manifest | python3 -m json.tool` → parses cleanly with all required fields
- `curl -sI http://localhost:10301/service-worker` → `HTTP/1.1 200 OK`, `content-type: text/javascript; charset=utf-8`
- `curl -s http://localhost:10301/service-worker` → returns the stub body byte-for-byte
- `curl -sL http://localhost:10301/` → rendered HTML contains `<link rel="manifest" href="/manifest">`, `<meta name="theme-color" content="#58CC02">`, `<meta name="apple-mobile-web-app-status-bar-style" content="default">`, `<meta name="apple-mobile-web-app-title" content="LittleStars">` (verified on the redirected `/family_session/new` page rendering through `application.html.erb`)
- `bin/rails routes -g pwa` (via `docker compose run --rm web`) lists exactly the 2 expected routes mapped to `rails/pwa#manifest` and `rails/pwa#service_worker`

## Must-Haves (plan frontmatter)

| # | Truth | Status |
|---|-------|--------|
| 1 | `/manifest` returns 200 with JSON content-type and expanded body | ✅ |
| 2 | `/service-worker` returns 200 (stub body OK at this plan) | ✅ |
| 3 | Every page includes `<link rel="manifest">` + `<meta name="theme-color">` | ✅ |
| 4 | Manifest includes lang, dir, orientation, categories, id, 192/512 maskable icons | ✅ |
| 5 | PWA routes outside `:parent`/`:kid` namespaces (no auth) | ✅ |

## Decisions Made

- **theme-color hex literal in meta:** CLAUDE.md prohibits raw hex outside `theme.css`, but `<meta name="theme-color">` is consumed by browser chrome before CSS loads and cannot resolve CSS variables. The literal `#58CC02` is mandated by the plan body and `must_haves.truths`. The manifest JSON is similarly a static asset. Both files are appropriate exceptions (browser-level signals, not stylesheets); the value still mirrors `--brand-primary` in `theme.css`. No theme.css edits required.
- **Service-worker fetch listener cannot be omitted:** Chrome installability audit requires a registered fetch handler. Empty handler is the documented minimum.

## Deviations from Plan

None — plan executed exactly as written. One acceptance-criterion grep pattern in Task 3 (`grep -q '"icon-192.png"'`) does not literally match the file content (which contains `"/icon-192.png"` with leading slash, per the action body). The implementation follows the action body verbatim and the resulting JSON is valid; this is a minor inconsistency in the plan's check pattern, not a deviation in the produced artifact.

## Issues Encountered

None. Initial smoke test via `Rails.application.call(env)` returned 403 due to host authorization on raw env, so verification was performed via real HTTP through the running Puma server (`make dev-detached`), which confirmed all endpoints.

## Known Stubs

- `app/views/pwa/service-worker.js` — intentional stub. Plan 07-03 replaces it with the production cache strategy. Documented in the file header comment.

## User Setup Required

None — all changes are code-level and require no external configuration.

## Next Phase Readiness

- **Plan 07-02 (icon assets):** Manifest already references `/icon-192.png` and `/icon-512.png`; that plan generates the actual PNG assets in `public/`. Until 07-02 ships, the icons 404 — not a blocker for the manifest itself parsing or for installability declaration, but Chrome's "Add to Home Screen" prompt requires the 192/512 to actually load before becoming available.
- **Plan 07-03 (SW cache strategy):** Will replace `app/views/pwa/service-worker.js` body. Route plumbing is ready.
- **Plan 07-04 (install prompt UI):** Theme color and manifest are in place; Stimulus controller for `beforeinstallprompt` can be added without further infra changes.

## Self-Check: PASSED

- ✅ `config/routes.rb` (modified, contains both `pwa_manifest`/`pwa_service_worker` routes)
- ✅ `app/views/pwa/service-worker.js` (created)
- ✅ `app/views/pwa/manifest.json.erb` (modified, valid JSON, contains all required fields)
- ✅ `app/views/shared/_head.html.erb` (modified, contains 4 new tags)
- ✅ Commits `b248ab4`, `3765f98`, `fafb7a6`, `b9210ee` exist in `git log`

---
*Phase: 07-pwa*
*Completed: 2026-05-01*

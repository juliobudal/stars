---
phase: 07-pwa
plan: 03
subsystem: pwa
tags: [pwa, service-worker, offline, cache-strategies]
provides:
  - public/offline.html
  - app/views/pwa/service-worker.js (full implementation)
requires:
  - public/icon-192.png (from 07-02)
  - public/icon-512.png (from 07-02)
  - public/icon.svg
  - app/views/pwa/service-worker.js (stub from 07-01)
affects:
  - PWA install/activate/fetch lifecycle
  - Offline navigation UX
tech_stack_added: []
key_files_created:
  - public/offline.html (55 lines, static HTML with inline CSS)
key_files_modified:
  - app/views/pwa/service-worker.js (5 lines stub → 59 lines real implementation)
decisions:
  - "Cache name 'littlestars-v1' — bump on cache-shape changes; activate sweeps non-matching keys"
  - "HTML responses NEVER cached (auth-leak prevention per CONTEXT.md constraint); offline fallback served via caches.match('/offline.html') only on network failure"
  - "cache.addAll(SHELL) is atomic — install rejects on any 404, preventing half-baked SW activation"
  - "Cache-first only on response.ok (avoids caching 404s into littlestars-v1)"
  - "offline.html uses inline CSS + raw hex literals (DESIGN.md exception): theme.css cannot be guaranteed available offline; documented in plan, exception row deferred to Plan 07-07"
metrics:
  tasks_completed: 2
  files_created: 1
  files_modified: 1
  duration_minutes: ~5
  completed_date: 2026-05-01
---

# Phase 07 Plan 03: Real service worker (cache strategies) + offline.html fallback

Full PWA service worker implementation with offline app-shell precache and routed cache
strategies, plus the static `/offline.html` fallback page. Replaces the stub from Plan 07-01.

## What changed

- **`public/offline.html` (new, 55 lines)** — Static Duolingo-styled offline page with inline
  CSS only (brand `#58CC02`, Nunito 700/800, 3D `0 4px 0` shadow, 14px radius). Auto-reloads
  on the `online` event when network returns. Honors `prefers-reduced-motion`.
- **`app/views/pwa/service-worker.js` (rewrite, 59 lines)** — Implements the cache strategy
  table from `07-RESEARCH.md` Q4:
  - **install** → `caches.open("littlestars-v1").addAll(["/offline.html","/icon-192.png","/icon-512.png"])` then `skipWaiting()`.
  - **activate** → delete any cache key not equal to `littlestars-v1`, then `clients.claim()`.
  - **fetch** (same-origin GETs only):
    - HTML navigations → network-first, fallback `caches.match('/offline.html')`.
    - `/vite/assets/*` and `/icon*` → cache-first, populate cache only on `response.ok`.
    - Everything else → pass-through (no `respondWith`).
  - POST/PATCH/DELETE and cross-origin requests pass through unmodified.

## Verification (server-side, automated)

Dev container running on host port `10301`:

```
$ curl -sI http://localhost:10301/offline.html | head -1
HTTP/1.1 200 OK
content-type: text/html
content-length: 1916
```

```
$ curl -s http://localhost:10301/service-worker | grep -E '(littlestars-v1|cache.addAll|caches.delete|navigate)'
const CACHE = "littlestars-v1";
caches.open(CACHE).then((cache) => cache.addAll(SHELL)).then(...)
Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
if (request.mode === "navigate" || ...)
```

All `must_haves.truths` greppable items confirmed:
- `littlestars-v1` cache name present
- `cache.addAll(SHELL)` install handler present
- `caches.delete` activate handler present
- `request.mode === "navigate"` HTML branch present
- `/offline.html` precache target present and served at 200
- offline.html contains "Sem conexão", `#58CC02`, `prefers-reduced-motion`

## Manual QA deferred

Browser-side validation cannot be exercised from CLI:

1. DevTools → Application → Service Workers shows status "activated and is running"
2. DevTools → Application → Cache Storage → `littlestars-v1` lists 3 entries
   (`/offline.html`, `/icon-192.png`, `/icon-512.png`) after first load
3. DevTools → Network → Offline + reload → `/offline.html` is served
4. Re-enable network + reload → normal site restored
5. Toggling between profiles confirms HTML responses are NOT cached (auth-leak guard)

These steps are deferred to Plan 07-07 (Lighthouse / PWA verification phase) per the plan's
verification note.

## Deviations from Plan

None — plan executed exactly as written. Both task `<action>` blocks were applied verbatim.

## Self-Check: PASSED

- `public/offline.html` — FOUND (55 lines, contains "Sem conexão", `#58CC02`, `prefers-reduced-motion`)
- `app/views/pwa/service-worker.js` — FOUND (59 lines, contains `littlestars-v1`, `cache.addAll(SHELL)`, `caches.delete`, `request.mode === "navigate"`, `/offline.html`)
- Commit `8dfce46` (Task 1: offline.html) — FOUND
- Commit `af7cbc1` (Task 2: service worker) — FOUND
- Live curl: `/offline.html` → 200 OK, `/service-worker` body matches new implementation

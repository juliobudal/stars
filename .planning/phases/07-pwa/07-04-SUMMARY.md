---
phase: 07-pwa
plan: 04
subsystem: pwa
tags: [pwa, service-worker, stimulus, ui]
requires: [07-01, 07-03]
provides:
  - "SW registration on every page load"
  - "pwa:update-available CustomEvent dispatch"
  - "pwa-update Stimulus controller + update toast in kid + parent layouts"
affects:
  - app/assets/entrypoints/application.js
  - app/views/pwa/service-worker.js
tech-stack:
  added: []
  patterns: [service-worker-update-flow, sessionStorage-dismissal, postMessage-SKIP_WAITING]
key-files:
  created:
    - app/assets/entrypoints/pwa.js
    - app/assets/controllers/pwa_update_controller.js
  modified:
    - app/assets/entrypoints/application.js
    - app/views/pwa/service-worker.js
    - app/views/layouts/kid.html.erb
    - app/views/layouts/parent.html.erb
decisions:
  - "Place pwa.js under app/assets/entrypoints/ (project's actual Vite source dir) rather than the plan's app/javascript/ path."
  - "Use shadow-[0_4px_0_rgba(0,0,0,0.12)] arbitrary value for the toast container since shadow-btn-md does not exist in the theme; CTA uses the existing shadow-btn-primary utility."
metrics:
  duration: ~10m
  completed: 2026-05-01
---

# Phase 07 Plan 04: SW registration + pwa-update controller + toast Summary

One-liner: Service worker now registers on every page load, dispatches `pwa:update-available` when a new SW is waiting, and a Duolingo-styled update toast in both kid and parent layouts offers reload with per-session dismissal via a Stimulus controller.

## Files

### Created

- `app/assets/entrypoints/pwa.js` — registers SW at `window.load`, listens for `updatefound` -> `statechange === "installed"` AND `navigator.serviceWorker.controller` truthy and dispatches `CustomEvent("pwa:update-available", { detail: { registration } })`. Also wires `controllerchange` for a single page reload after activation. Guarded by `"serviceWorker" in navigator` so legacy browsers no-op.
- `app/assets/controllers/pwa_update_controller.js` — Stimulus controller (auto-registered by `stimulus-vite-helpers`). On `connect()`, reads `sessionStorage["pwa-update-dismissed"]` and binds the window listener. `apply()` posts `{type: "SKIP_WAITING"}` to `registration.waiting` (falls back to `location.reload()` when no waiting worker is present). `dismiss()` writes `"1"` to `sessionStorage` and hides the host. `disconnect()` removes the listener.

### Modified

- `app/assets/entrypoints/application.js` — appended `import "./pwa"` after view-component glob imports, so SW registration runs after Stimulus/Turbo init.
- `app/views/pwa/service-worker.js` — added a `message` handler before the existing `fetch` listener that calls `self.skipWaiting()` on `{type: "SKIP_WAITING"}`. Forward-compat with future SW iterations that drop install-time skipWaiting.
- `app/views/layouts/kid.html.erb` and `app/views/layouts/parent.html.erb` — mounted hidden toast div with `data-controller="pwa-update"` immediately after the existing `Ui::Flash::Component` render. Buttons wired with `data-action="pwa-update#apply"` ("Atualizar") and `data-action="pwa-update#dismiss"` ("Depois"). Tokens used: `bg-primary`, `text-primary-foreground`, `text-foreground`, `text-muted-foreground`, `shadow-btn-primary`, plus `shadow-[0_4px_0_rgba(0,0,0,0.12)]` arbitrary value for the container (see Deviations).

## Verification (must_haves.truths)

- [x] `navigator.serviceWorker.register("/service-worker", { scope: "/" })` is called on every page load — present in `pwa.js`, imported from `application.js` (which is the only Vite entrypoint loaded by `_head.html.erb` via `vite_javascript_tag 'application'`).
- [x] Registration gated by `"serviceWorker" in navigator` — both the load-time block and the `controllerchange` block are wrapped in this guard.
- [x] On `statechange === "installed"` AND `navigator.serviceWorker.controller` truthy, `window.dispatchEvent(new CustomEvent("pwa:update-available", { detail: { registration } }))` fires.
- [x] Stimulus controller `pwa-update` listens for `pwa:update-available`, reveals host element, and renders Atualizar / Depois buttons with Duolingo styling.
- [x] Close button ("Depois") persists dismissal via `sessionStorage.setItem("pwa-update-dismissed", "1")` (session scope; reappears next session).

Static-grep proxies pass for all acceptance criteria across Tasks 1–4 (verified at end of execution).

Browser-side runtime verification of the full toast event flow (cache version bump → toast appears → Atualizar reloads → DevTools confirms new SW activated) is **deferred to Plan 07-07** (PWA verification plan), since CLI cannot exercise the SW lifecycle.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] pwa.js path mismatch with project structure**
- Found during: Task 1
- Issue: Plan specified `app/javascript/pwa.js`, but this project has no `app/javascript/` directory. The Vite source dir (`config/vite.json` → `sourceCodeDir: app/assets`) and entrypoint live under `app/assets/entrypoints/application.js`. Importing `./pwa` from there resolves to `app/assets/entrypoints/pwa.js`.
- Fix: Created `app/assets/entrypoints/pwa.js` and added the import to `app/assets/entrypoints/application.js`. Functional contract (`import "./pwa"` + relative resolution) preserved.
- Files modified: `app/assets/entrypoints/pwa.js`, `app/assets/entrypoints/application.js`.
- Commits: 55657d5, c79779f.

**2. [Rule 2 - Correctness] Theme tokens referenced by plan don't exist as Tailwind utilities**
- Found during: Task 4
- Issue: Plan template referenced `bg-brand-primary`, `text-ink`, `shadow-btn-sm`, `shadow-btn-md` which are not registered in `app/assets/stylesheets/tailwind/theme.css`. The plan itself flagged this with a fallback note.
- Fix: Substituted existing theme utilities (`bg-primary`, `text-primary-foreground`, `text-foreground`, `text-muted-foreground`, `shadow-btn-primary`) and used the plan-sanctioned arbitrary value `shadow-[0_4px_0_rgba(0,0,0,0.12)]` for the toast container. No raw hex introduced anywhere.
- Files modified: `app/views/layouts/kid.html.erb`, `app/views/layouts/parent.html.erb`.
- Commit: acd28c6.

**3. [Rule 1 - Static contract] `navigator.serviceWorker.register` must appear on a single line**
- Found during: post-task verification
- Issue: Initial `pwa.js` formatted the call as `navigator.serviceWorker\n  .register(...)`, which broke the single-line `grep` artifact contract in `must_haves.artifacts`.
- Fix: Inlined the call to `navigator.serviceWorker.register("/service-worker", { scope: "/" })`.
- Commit: 68306e7.

## Auth Gates

None.

## Known Stubs

None — toast is hidden by default and only appears when the SW lifecycle dispatches the event. No placeholder data flows into the UI.

## Threat Flags

None — this plan only adds client-side SW lifecycle UI; no new server endpoints, auth paths, or schema changes. Threat dispositions from the plan (`mitigate`: cross-session toast persistence, stuck-on-old-SW) are honored via `sessionStorage` dismissal and the `controllerchange` reload recipe.

## Self-Check: PASSED

- [x] `app/assets/entrypoints/pwa.js` exists
- [x] `app/assets/controllers/pwa_update_controller.js` exists
- [x] `app/views/pwa/service-worker.js` contains `SKIP_WAITING`
- [x] Both layouts contain `data-controller="pwa-update"` and both `apply` + `dismiss` actions
- [x] All commits present in `git log`: 55657d5, c79779f, 7699ec1, acd28c6, 68306e7
- [x] No JS syntax errors (`node --check` passes for all three modified/created JS files)

## Commits

| Task   | Description                                            | Commit    |
| ------ | ------------------------------------------------------ | --------- |
| 1      | Create app/assets/entrypoints/pwa.js                   | 55657d5   |
| 2      | Import pwa.js from application entrypoint              | c79779f   |
| 3      | pwa-update Stimulus controller + SW SKIP_WAITING       | 7699ec1   |
| 4      | Mount toast in kid + parent layouts                    | acd28c6   |
| post   | Inline `navigator.serviceWorker.register` call         | 68306e7   |

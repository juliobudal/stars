---
phase: 07-pwa
plan: 02
subsystem: pwa
tags: [pwa, icons, maskable, dockerfile]
provides:
  - public/icon-192.png
  - public/icon-512.png
  - scripts/generate_pwa_icons.sh
requires:
  - public/icon.svg
  - librsvg2-bin
  - imagemagick
affects:
  - Dockerfile
tech_stack_added:
  - librsvg2-bin (rsvg-convert) for high-fidelity SVG rasterization
  - imagemagick (convert) for canvas composite onto solid background
key_files_created:
  - public/icon-192.png (6168 bytes, PNG 192x192, 16-bit/color RGB, non-interlaced)
  - public/icon-512.png (17626 bytes, PNG 512x512, 16-bit/color RGB, non-interlaced)
  - scripts/generate_pwa_icons.sh (43 lines, executable)
key_files_modified:
  - Dockerfile (added librsvg2-bin and imagemagick to apt-get install)
decisions:
  - "Used rsvg-convert + convert pipeline (not convert alone) for better SVG fidelity"
  - "Inner safe-zone computed at 80% of canvas (153px on 192, 409px on 512) per W3C maskable spec"
metrics:
  tasks_completed: 3
  files_created: 3
  files_modified: 1
  duration_minutes: ~12
  completed_date: 2026-05-01
---

# Phase 07 Plan 02: Maskable PNG icons (192/512) + reproducible generation script

Resolved the /icon-192.png and /icon-512.png 404s introduced when plan 07-01 expanded the
manifest icon list. Both PNGs are now committed under `public/`, reproducible via
`scripts/generate_pwa_icons.sh`, and the dev image bundles the rasterizer + compositor.

## Tool Used

Both `rsvg-convert` (librsvg2-bin) and `convert` (imagemagick) — the script renders the SVG
logo at 80% inner size with rsvg-convert, then composites onto a solid `#58CC02` canvas with
ImageMagick. This pipeline gives sharper SVG output than letting ImageMagick rasterize the SVG
directly via its (often patchy) MSVG/RSVG delegate.

## File Sizes

| File | Bytes | Dimensions |
| --- | --- | --- |
| public/icon-192.png | 6,168 | 192x192 |
| public/icon-512.png | 17,626 | 512x512 |

Both are 16-bit/color RGB, non-interlaced (per `file`).

## Dockerfile Change

Added `librsvg2-bin imagemagick` to the dev image apt-get line:

```diff
     apt-get install -y build-essential libpq-dev nodejs npm git libyaml-dev pkg-config \
-      chromium chromium-driver && \
+      chromium chromium-driver \
+      librsvg2-bin imagemagick && \
```

The dev image was rebuilt (`docker compose build --no-cache web`) and the container recreated
so `which rsvg-convert` and `which convert` both resolve inside `make shell`.

## Acceptance Verification

- `test -f public/icon-192.png && test -f public/icon-512.png` → pass
- `file public/icon-192.png` → `PNG image data, 192 x 192, 16-bit/color RGB, non-interlaced`
- `file public/icon-512.png` → `PNG image data, 512 x 512, 16-bit/color RGB, non-interlaced`
- `test -x scripts/generate_pwa_icons.sh` → pass
- `grep -q 'rsvg-convert' scripts/generate_pwa_icons.sh` → pass
- `grep -q '#58CC02' scripts/generate_pwa_icons.sh` → pass
- `curl -sI http://localhost:10301/icon-192.png` → `HTTP/1.1 200 OK`, `content-type: image/png`, `content-length: 6168`
- `curl -sI http://localhost:10301/icon-512.png` → `HTTP/1.1 200 OK`, `content-type: image/png`, `content-length: 17626`

## Commits

| SHA | Message |
| --- | --- |
| 6c5e75c | chore(07-02): add librsvg2-bin and imagemagick for PWA icon generation |
| 1cc13f8 | feat(07-02): add reproducible PWA icon generation script |
| e656840 | feat(07-02): add maskable PWA icons (192x192, 512x512) |

## Deviations from Plan

None. Plan executed exactly as written. The Dockerfile change was already specified as the
preferred path in Task 1's `<action>` block; the dev image rebuild was required (rather than
ad-hoc `apt-get` inside the live container) because Compose recreated the container between
the install and the verification step, dropping the ad-hoc layer.

## Self-Check: PASSED

- public/icon-192.png — FOUND (6168 bytes, 192x192)
- public/icon-512.png — FOUND (17626 bytes, 512x512)
- scripts/generate_pwa_icons.sh — FOUND (executable)
- Dockerfile — modified (librsvg2-bin imagemagick present)
- Commits 6c5e75c, 1cc13f8, e656840 — all present in `git log`
- HTTP 200 with `image/png` for both icon URLs

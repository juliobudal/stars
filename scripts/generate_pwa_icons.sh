#!/usr/bin/env bash
set -euo pipefail

# Generate maskable PWA icons from public/icon.svg
# Logo placed in central 80% safe zone, brand-primary background fills the rest.
# Per W3C maskable icon spec (radius 40% from canvas center).

SRC="public/icon.svg"
BG="#58CC02"

if ! [ -f "$SRC" ]; then
  echo "Source not found: $SRC" >&2
  exit 1
fi

generate() {
  local size="$1"
  local out="public/icon-${size}.png"
  local inner=$(( size * 80 / 100 ))

  if command -v rsvg-convert >/dev/null 2>&1; then
    # Render logo to inner size, then composite onto solid bg canvas with ImageMagick
    rsvg-convert -w "$inner" -h "$inner" "$SRC" -o "/tmp/logo-${size}.png"
    if command -v convert >/dev/null 2>&1; then
      convert -size "${size}x${size}" "xc:${BG}" "/tmp/logo-${size}.png" \
              -gravity center -composite "$out"
    else
      echo "Need ImageMagick (convert) to composite onto colored background" >&2
      exit 1
    fi
  elif command -v convert >/dev/null 2>&1; then
    convert -background "$BG" -resize "${inner}x${inner}" "$SRC" \
            -gravity center -extent "${size}x${size}" "$out"
  else
    echo "Install librsvg2-bin (preferred) or imagemagick" >&2
    exit 1
  fi

  echo "Generated $out (${size}x${size}, logo ${inner}px centered)"
}

generate 192
generate 512

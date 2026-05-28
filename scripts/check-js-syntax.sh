#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Fast syntax gate for frontend JS without enforcing legacy style rewrites.
FILES=$(find app/assets app/components app/views -type f \( -name "*.js" -o -name "*.mjs" \))

if [ -z "$FILES" ]; then
  echo "✓ JS syntax: no JS files found."
  exit 0
fi

echo "$FILES" | while IFS= read -r file; do
  node --check "$file"
done

echo "✓ JS syntax: all files parse."

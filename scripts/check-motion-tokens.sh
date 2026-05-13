#!/usr/bin/env bash
# Fails if any component CSS or view template uses a raw duration in a transition
# or animation declaration. All motion must reference tokens from tailwind/motion.css.
#
# Allowed:  transition: transform var(--dur-fast) ease;
# Allowed:  animation-delay: 0.12s;            (delay only — paired with .anim-* class)
# Banned:   transition: transform 120ms ease;
# Banned:   animation: slideIn 0.4s ease-out;
#
# To suppress for a justified exception, add the comment `motion-lint: allow`
# on the same line.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Raw CSS duration in `transition:` / `animation:` declarations.
PATTERN_CSS='(transition|animation)[[:space:]]*:[^;]*[0-9]+(\.[0-9]+)?m?s'

# Tailwind `duration-N` / `duration-[Nms]` utility classes in ERB/HTML.
PATTERN_TW='(^|[[:space:]"])duration-(\[?[0-9]+m?s?\]?)'

FILES=(
  app/components
  app/views
)

EXIT=0

for path in "${FILES[@]}"; do
  matches=$(grep -rnE "$PATTERN_CSS" "$path" \
    --include="*.css" --include="*.erb" --include="*.html" 2>/dev/null \
    | grep -v "motion-lint: allow" || true)
  if [[ -n "$matches" ]]; then
    echo "✗ Raw motion durations in $path (use var(--dur-*) tokens):"
    echo "$matches"
    echo
    EXIT=1
  fi

  tw_matches=$(grep -rnE "$PATTERN_TW" "$path" \
    --include="*.erb" --include="*.html" 2>/dev/null \
    | grep -v "motion-lint: allow" || true)
  if [[ -n "$tw_matches" ]]; then
    echo "✗ Tailwind duration utilities in $path (use .anim-* classes or var(--dur-*)):"
    echo "$tw_matches"
    echo
    EXIT=1
  fi
done

if [[ $EXIT -eq 0 ]]; then
  echo "✓ Motion tokens: no raw durations in components or views."
fi

exit $EXIT

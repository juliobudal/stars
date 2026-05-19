# Motion System Improvement Plan

**Status:** Draft · **Owner:** Frontend · **Target:** End of UI/UX Duolingo rebrand milestone

Comprehensive plan to fix the audit findings, unify the two competing animation libraries, and add a small set of high-value effects that lean into LittleStars' playful Duolingo character without breaking the 3D contract or accessibility.

---

## Goals

1. **One animation library** — `motion.css` becomes canonical; `animations.css` and `design_system.css` legacy keyframes are migrated and deleted.
2. **Tokenized timings** — every transition/animation duration resolves to a CSS variable.
3. **100% reduced-motion compliance** — no element with a transition or animation escapes the `prefers-reduced-motion` guard.
4. **Component-level contracts** — `.ls-card-3d` / press states applied by ViewComponents, not callers.
5. **Delight surface** — add ~6 new motion utilities (reward unlock, points tick, streak flame, etc.) that already-built UIs can opt into.

Non-goals: rebuilding Stimulus controllers, replacing CSS with Motion One / GSAP, animated illustrations beyond mascot.

---

## Phase 0 — Token consolidation (PR 1, ~30 LOC)

Extend `motion.css:1-10`:

```css
:root {
  /* easings */
  --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);     /* overshoot */
  --ease-spring-soft: cubic-bezier(0.22, 1.4, 0.36, 1); /* gentle lift */
  --ease-snap: cubic-bezier(0.4, 0, 0.2, 1);            /* material */
  --ease-out-back: cubic-bezier(0.34, 1.20, 0.64, 1);   /* NEW — softer pop */

  /* durations — single rhythm */
  --dur-instant: 80ms;   /* NEW — press feedback only */
  --dur-fast: 120ms;     /* hover lift */
  --dur-base: 240ms;     /* most transitions */
  --dur-pop: 380ms;      /* spring pops */
  --dur-long: 600ms;     /* progress fills, big reveals */
  --dur-ambient: 2500ms; /* idle loops (mascot, coin) */
}
```

Rule: **no raw ms values in any component CSS.** Add a Rubocop-like grep check to CI (`scripts/check-motion-tokens.sh`) that fails if `transition:` or `animation:` lines contain a literal `\d+m?s` outside `motion.css`.

---

## Phase 1 — Fix violations (PR 2)

### 1.1 Missing keyframe
`app/components/ui/spinner/turbo_frame_spinner.css:9` — add to `motion.css`:

```css
.anim-spin { animation: fxSpin 1.6s var(--ease-snap) infinite; }
@keyframes fxSpin { to { transform: rotate(360deg); } }
```

Replace spinner's local `animation: spinner ...` with class `.anim-spin`.

### 1.2 Reduced-motion gap on category tabs
`app/components/ui/category_tabs/category_tabs.css` — replace the bespoke `.cat-tab` rules with the `.ls-filter-pill` utility (already covered by motion.css reduced-motion block). Delete component-local transition.

### 1.3 Inline view animations
Move these to a class (`.anim-card-enter`) defined once in `motion.css`:
- `app/views/parent/activity_logs/index.html.erb:58`
- `app/views/kid/rewards/_locked.html.erb:20`
- `app/views/kid/rewards/_affordable.html.erb:18`

```css
.anim-card-enter { animation: fxFadeUp var(--dur-base) var(--ease-spring-soft) both; }
```

Stagger via inline `style="animation-delay: 60ms * index"` is fine — but only the delay is inline, never the animation itself.

### 1.4 Dashboard progress bar
`kid/dashboard/index.html.erb:71` — replace `transition-all duration-500` with `.anim-progress` utility:

```css
.anim-progress { transition: width var(--dur-long) var(--ease-spring-soft); }
```

### 1.5 Non-token durations
- `btn.css:4` 80ms → `var(--dur-instant)`
- `install_prompt.css:36`, `pwa_update_toast.css:36` → `var(--dur-instant)`
- `profile_picker.css:1` 150ms → `var(--dur-fast)`
- `pin_modal.css:47,54` `.15s` → `var(--dur-fast)`
- `wishlist_goal/component.css:4` 600ms → `var(--dur-long)`
- `category_tabs.css:12` `duration-150` → remove (utility class takes over)

---

## Phase 2 — Component contracts (PR 3)

### 2.1 Auto-apply `.ls-card-3d`
`Ui::Card::Component` — add a `lift: true` kwarg (default true). When true, render with `ls-card-3d` class. Update callers that don't want lift (none currently) to opt out.

### 2.2 Mission card double animation
`mission_card.html.erb:3,103` — pick one: keep `anim-tile` (hover lift) and drop `pop-on-tap`. Replace any "click feedback" need with `anim-press`.

### 2.3 Delete legacy
Once Phase 2.2 lands and no references remain:
- Remove from `animations.css`: `slideIn`, `slideInR`, `slideInCard`, `popIn`, `popCard`, `pop`, `confetti-fall`, `glowBurst`, `pop-on-tap`.
- Keep only the ambient ones still in use (audit before delete).
- Remove `design_system.css` legacy keyframes block entirely.

---

## Phase 3 — New motion utilities (PR 4)

Six effects that map to existing flows. Each is a one-class opt-in, included in the reduced-motion guard.

### 3.1 `.anim-count-up` — points tick
For `Profile.points` balance updates after approve/redeem. Stimulus controller `count-up_controller.js` already exists in spirit; standardize with a CSS pop on each tick.

```css
.anim-count-up { animation: fxCountPop var(--dur-fast) var(--ease-spring) both; }
@keyframes fxCountPop {
  0% { transform: scale(1); color: var(--color-fg); }
  50% { transform: scale(1.18); color: var(--color-success); }
  100% { transform: scale(1); }
}
```

Use case: `app/views/shared/_balance.html.erb` (wallet badge) — Turbo Stream broadcast from `ApproveService` triggers re-render; class makes the number pulse green on increase.

### 3.2 `.anim-streak-flame` — streak day flicker
For `Profile.current_streak` badge.

```css
.anim-streak-flame { animation: fxFlicker 1.8s ease-in-out infinite; transform-origin: bottom center; }
@keyframes fxFlicker {
  0%, 100% { transform: rotate(-1deg) scale(1); filter: brightness(1); }
  50%      { transform: rotate(1.5deg) scale(1.04); filter: brightness(1.1); }
}
```

### 3.3 `.anim-reward-unlock` — unlock celebration
For `kid/rewards/_locked.html.erb` → `_affordable.html.erb` transition when points threshold is crossed (Turbo Stream replace). Wraps a spring scale + glow burst:

```css
.anim-reward-unlock { animation: fxUnlock 700ms var(--ease-spring) both; }
@keyframes fxUnlock {
  0%   { transform: scale(0.85) rotate(-3deg); opacity: 0; filter: brightness(0.7); }
  60%  { transform: scale(1.08) rotate(2deg); opacity: 1; filter: brightness(1.2); }
  100% { transform: scale(1) rotate(0); filter: brightness(1); }
}
```

### 3.4 `.anim-approve-check` — checkmark draw
For approval row state change to "approved." SVG stroke-dashoffset animation; pairs with `Tasks::ApproveService` Turbo broadcast.

```css
.anim-approve-check path {
  stroke-dasharray: 24;
  stroke-dashoffset: 24;
  animation: fxDraw var(--dur-pop) var(--ease-snap) forwards;
}
@keyframes fxDraw { to { stroke-dashoffset: 0; } }
```

### 3.5 `.anim-toast-slide` — top/bottom toast entry
For PWA update toast and any flash messages.

```css
.anim-toast-slide { animation: fxToast var(--dur-base) var(--ease-spring) both; }
@keyframes fxToast {
  from { transform: translateY(-100%); opacity: 0; }
  to   { transform: translateY(0); opacity: 1; }
}
```

### 3.6 `.anim-progress-shimmer` — ambient progress
Layer on top of progress bars (dashboard level bar, family goal widget) using `.anim-shimmer` masked over the filled portion. Add data-attribute trigger so it only runs when bar is >0% and <100%.

---

## Phase 4 — Reduced-motion finalization (PR 4)

Append new classes to the reduced-motion block in `motion.css:138-167`:

```css
@media (prefers-reduced-motion: reduce) {
  .anim-count-up, .anim-streak-flame, .anim-reward-unlock,
  .anim-approve-check, .anim-toast-slide, .anim-progress-shimmer,
  .anim-card-enter, .anim-progress, .anim-spin {
    animation: none !important;
    transition: none !important;
  }
  .anim-approve-check path { stroke-dashoffset: 0; }
}
```

Add a system spec: `spec/system/motion_accessibility_spec.rb` — boots app with `prefers-reduced-motion: reduce` emulated, walks `/parent/dashboard`, `/kid`, `/kid/rewards`, asserts no element has computed `animation-duration > 0s`.

---

## Phase 5 — Documentation & enforcement (PR 5)

### 5.1 Update `DESIGN.md`
- Rewrite §5 to be the **single source** of motion rules; reference token names not raw ms.
- New §5.4: "Effects catalog" — list each `anim-*` utility with: trigger, where it applies, demo gif/recording path.
- §13 state matrix: add columns for `count-up`, `unlock`, `approve-check`.

### 5.2 CI guardrails
- `scripts/check-motion-tokens.sh` — grep for raw durations in `app/components/**` and `app/views/**`. Fail if found.
- Rubocop is unsuitable for CSS; do it via a Make target `make lint-motion` wired into `make ci`.

### 5.3 ViewComponent previews
Add Lookbook (or barebones preview) entries for each `anim-*` utility under `spec/components/previews/motion/` so designers can sanity-check timings in a browser.

---

## Phase 6 — Stretch / nice-to-have

- **Haptic-feel press**: tiny `box-shadow` color flash on 3D button press (50ms warm tint).
- **Confetti via canvas**, replacing the CSS `confetti-fall` legacy. Stimulus controller `confetti_controller.js`, triggered by celebration views.
- **Page transitions via View Transitions API** (Chromium-only, progressively enhanced) — Turbo 8 supports it; wire `data-turbo-frame` to use named transitions for parent ↔ kid layout switches.
- **Lottie mascot**: replace `.ls-mascot-bounce` CSS with a single Lottie file (still gated by reduced-motion).

---

## Rollout order & risk

| PR | Scope | Risk | Reverts cleanly |
|---|---|---|---|
| 1 | Token additions only | Zero | Yes |
| 2 | Fix audit violations | Low — visual nudges | Yes |
| 3 | Component contracts + legacy delete | Medium — touches many views | Yes (per-component) |
| 4 | New effects + reduced-motion | Low — additive | Yes |
| 5 | Docs + CI lint | Zero | Yes |
| 6 | Stretch | Defer | Independent PRs |

Each PR ships independently and updates `DESIGN.md` in the same commit. Estimated total: ~2 days of focused work.

---

## Acceptance checklist

- [ ] No raw ms/s values in `app/components/**` or `app/views/**` CSS/inline style
- [ ] `make lint-motion` passes in CI
- [ ] `spec/system/motion_accessibility_spec.rb` green
- [ ] All 3D-shadow elements have transition + `:active` + reduced-motion guard
- [ ] `animations.css` reduced to ambient-only or deleted; `design_system.css` legacy block removed
- [ ] DESIGN.md §5 lists every `anim-*` utility with trigger and example
- [ ] Lookbook (or static) preview page renders each effect
- [ ] Manual QA pass with `prefers-reduced-motion: reduce` enabled in DevTools

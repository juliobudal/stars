# Kid UI Vibrancy — Design Spec

**Date:** 2026-04-26
**Scope:** Kid-facing UI (dashboard, missions, rewards, wallet) + shared primitives consumed by both UIs
**Out of scope (separate spec):** Parent UI per-screen polish, audio playback, visual regression testing

## Goal

Make the kid app feel alive and rewarding without sacrificing legibility or performance. Add a consistent motion language, branded modal variants, and tiered celebrations for milestone events. Keep the system centralized so future tuning is one-touch.

## Locked Decisions

| Decision | Choice |
|---|---|
| Decomposition | Kid-first wave (this spec); parent polish = later spec |
| Personality | Polished + minimal-moving — springs only on interaction, no idle bobbing |
| Alerts | Extend existing `Ui::Modal` + `Ui::TurboConfirm` with branded variants (SweetAlert2 as visual reference, not as dependency) |
| Motion stack | Motion One (~3.8kb) for orchestrated sequences + vanilla CSS spring curves for hover/press |
| Celebration tiers | BIG = approve, redeem, streak milestone, threshold cross, all-missions-cleared. small = tap Done, daily reset, new reward unlocked |
| `prefers-reduced-motion` | Honored at CSS + JS layers — instant final state, no confetti |
| Audio | Hooks ready, no audio shipped |

## Architecture

Three layers:

### 1. Motion tokens (CSS)

`app/assets/stylesheets/tailwind/motion.css`

- CSS custom properties: `--ease-spring`, `--ease-spring-soft`, `--ease-snap`, `--dur-fast` (120ms), `--dur-base` (240ms), `--dur-pop` (380ms)
- Utility classes: `.anim-press`, `.anim-pop-in`, `.anim-shake`, `.anim-bounce-once`, `.anim-shimmer`, `.anim-fade-up`, `.anim-tile`, `.anim-pulse-once`
- `@media (prefers-reduced-motion: reduce)` block neutralizes every utility (instant final state, no transitions)

### 2. FX runtime (Stimulus + Motion One)

`app/assets/controllers/fx_controller.js` — single controller mounted on `<body>` of kid layout.

Handlers:
- `celebrate(tier, payload)` — BIG = `canvas-confetti` burst + Motion One pop on chip + `Ui::Modal variant: :celebration`. small = `Ui::Toast` + `.anim-pulse-once` on related element
- `shake(el)` — Motion One keyframe sequence (-6, 6, -4, 4, 0)px, 360ms
- `popIn(el)` — Motion One spring scale 0.94 → 1, opacity 0 → 1
- `countUp(el, from, to)` — wraps existing `count_up_controller`

Dispatch contract:
- Any DOM node with `data-fx-event="<name>"` triggers FX on insert (MutationObserver)
- `data-fx-tier="big|small"` modulates intensity
- `data-fx-payload="{...JSON}"` passes context (`points`, `message`, `reward_title`)
- Once fired, controller sets `data-fx-fired="true"` to prevent re-fire on Turbo morph
- `prefers-reduced-motion` checked once at connect, branches every handler

Existing `celebration_controller.js` confetti logic is lifted into `fx_controller`. The 500ms anti-spam guard moves with it. Old controller deleted.

### 3. Server orchestration (Ruby)

`app/services/ui/celebration.rb` — pure decision module.
- `Ui::Celebration.tier_for(event_type, **context) → :big | :small | :none`
- Inputs: `event_type` (`:approved`, `:redeemed`, `:streak`, `:threshold`, `:all_cleared`, `:done_tapped`, `:reset`, `:reward_unlocked`), context hash
- No DB access, no side effects

`app/services/streaks/check_service.rb` — read-only milestone detector.
- `Streaks::CheckService.call(profile, points_before:, points_after:) → { tier: Symbol, payload: Hash } | nil`
- Detects: streak (3/7/14 day windows from `ActivityLog.where(log_type: :earn)`), threshold cross (50/100/250★)
- `rescue StandardError` returns nil; logs via `Rails.logger.warn`

Existing services (`Tasks::ApproveService`, `Rewards::RedeemService`) call `Ui::Celebration.tier_for` and `Streaks::CheckService.call`, then add `data-fx-event` + `data-fx-tier` + `data-fx-payload` to broadcasted partials. Existing Turbo Stream channels reused (`"kid_#{profile.id}"`).

## Components & File Plan

### New files

| Path | Purpose |
|---|---|
| `app/assets/stylesheets/tailwind/motion.css` | Motion tokens + utilities + reduced-motion guard |
| `app/assets/controllers/fx_controller.js` | Single FX dispatcher (Motion One driver, MutationObserver) |
| `app/services/ui/celebration.rb` | Tier decision module |
| `app/services/streaks/check_service.rb` | Streak + threshold detection |
| `app/components/ui/toast/component.rb` | New lightweight Toast component |
| `app/components/ui/toast/component.html.erb` | Toast template |
| `app/views/kid/shared/_celebration.html.erb` | Server-rendered celebration partial (broadcast target) |
| `spec/services/ui/celebration_spec.rb` | Tier decision tests |
| `spec/services/streaks/check_service_spec.rb` | Milestone detection tests |
| `spec/components/ui/toast_component_spec.rb` | Toast variants test |

### Modified files

| Path | Change |
|---|---|
| `app/components/ui/modal/component.rb` | Add `variant:` arg (`:default | :success | :confirm-destructive | :celebration`) |
| `app/components/ui/modal/component.html.erb` | Branch on `variant:` for icon, color band, button styling, entry animation. Single template — no per-variant sidecar files (keeps with existing ViewComponent pattern in this repo) |
| `app/views/layouts/kid.html.erb` | Mount `data-controller="fx"` on body, ensure `<div id="fx_stage">` present, remove old `celebration` controller mount |
| `app/services/tasks/approve_service.rb` | Compute tier + streak, pass into broadcast partial as data attrs |
| `app/services/rewards/redeem_service.rb` | Same as approve |
| `app/services/tasks/complete_service.rb` | Detect "all cleared" condition, broadcast small celebration partial |
| `package.json` | Add `motion` (Motion One ~3.8kb) |
| `app/assets/controllers/celebration_controller.js` | DELETE (logic absorbed by fx_controller) |
| `app/assets/stylesheets/tailwind/animations.css` | Audit — move kid-relevant keyframes into `motion.css`, keep parent-only utilities here |
| `spec/services/tasks/approve_service_spec.rb` | Extend — assert broadcast includes `data-fx-event` + `data-fx-tier` |
| `spec/services/rewards/redeem_service_spec.rb` | Extend — same |
| `spec/components/ui/modal_component_spec.rb` | Extend — render each `variant:` |

## Effect Catalog

| Effect | Trigger | Tech |
|---|---|---|
| `press` | `.anim-press` on `<button>` | CSS spring scale .96 → 1, 120ms |
| `tile-hover` | `.anim-tile` on cards | CSS translateY -2px + shadow lift, 240ms spring |
| `pop-in` | `data-fx-event="pop-in"` | Motion One on element insert |
| `count-up` | `data-fx-event="count-up"` on balance | Existing `count_up_controller`, FX wraps timing |
| `pulse-chip` | `.anim-pulse-once` on balance chip | CSS keyframe scale 1 → 1.12 → 1, 380ms |
| `shake` | `data-fx-event="shake"` on form errors | Motion One keyframe (-6, 6, -4, 4, 0)px, 360ms |
| `confetti-burst` | tier `:big` | Existing `canvas-confetti` (already in deps), 60 pieces |
| `celebration-modal` | tier `:big` | `Ui::Modal variant: :celebration` — pop-in + confetti behind |
| `toast` | tier `:small` + ambient | New `Ui::Toast` component, stack ≤ 3, 3s auto-dismiss |
| `shimmer` | loading skeletons | CSS gradient sweep, infinite |

## Tier Wiring

| Event | Tier | Trigger path |
|---|---|---|
| Parent approves task | BIG | `Tasks::ApproveService` broadcasts celebration partial with tier |
| Reward redeemed | BIG | `Rewards::RedeemService` broadcasts (gold-only confetti palette) |
| Streak milestone (3/7/14) | BIG | `Streaks::CheckService` overrides tier in approve flow |
| Threshold cross (50/100/250★) | BIG | `Streaks::CheckService` overrides tier in approve flow |
| All daily missions cleared | BIG | `Tasks::CompleteService` broadcasts after last `pending → pending_approval` for the day |
| Tap "Done" | small | Inline toast + tile pulse + button press (client-only) |
| Daily reset (new day) | small | Toast on dashboard load |
| New reward unlocked | small | Toast |

## Data Flow

### Flow A — kid taps "Done" (small)

```
[Kid] tap button
  → Stimulus fx#celebrate(tier: "small", scope: tile)
    → CSS .anim-press on button (immediate)
    → tile.anim-pulse-once
    → Ui::Toast renders "Aguardando aprovação ✨"
  → Turbo POST /kid/missions/:id/complete (existing)
    → Tasks::CompleteService → ProfileTask.status = :pending_approval
    → If last pending task of the day → broadcast small "all cleared" toast
    → Else: no broadcast (waits for parent approval)
```

### Flow B — parent approves (BIG, cross-profile)

```
[Parent] click Aprovar in /parent/approvals
  → POST /parent/approvals/:id/approve (existing)
  → Tasks::ApproveService.call
    → Profile.points += task.points (txn)
    → ActivityLog.create!(log_type: :earn, ...)
    → tier = Ui::Celebration.tier_for(:approved, ...)
    → streak_result = Streaks::CheckService.call(profile, points_before:, points_after:)
    → if streak_result then tier, payload = streak_result.values_at(:tier, :payload)
    → broadcast_replace_to "kid_#{profile.id}",
        target: "balance_chip",
        partial: "kid/wallet/balance_chip",
        locals: { fx_event: "count-up", fx_payload: { from: old, to: new } }
    → broadcast_append_to "kid_#{profile.id}",
        target: "fx_stage",
        partial: "kid/shared/celebration",
        locals: { tier:, payload: { points:, message:, reward_title: nil } }
[Kid browser] receives stream
  → DOM nodes inserted with data-fx-event="celebrate"
  → fx_controller MutationObserver picks up insertion
    → reads data-fx-tier, data-fx-payload (JSON)
    → BIG branch:
      - canvas-confetti.burst()
      - Motion One pop-in on celebration partial
      - countUp(balance_chip, oldVal, newVal) over 600ms
      - Ui::Modal variant: :celebration auto-opens, dismiss after 2.5s OR tap
    → cleanup: removes celebration partial after 3s
```

### Flow C — reward redeemed (BIG)

Same as Flow B but `Rewards::RedeemService`. Confetti gold-only palette. Modal text uses `reward.title`.

### Flow D — error (shake)

```
Server returns 422 → Turbo Stream replaces form with errors
  → fx_controller MutationObserver sees new .field-error nodes
  → fx#shake on form root + each erroring field
  → toast "Verifique os campos"
```

## Edge Cases & Error Handling

**Race conditions**
- Two BIG events fire within 500ms → fx controller queues, plays sequentially with 200ms gap. Single confetti burst (existing `_lastBurstAt` guard lifted into `fx_controller`).
- Kid taps Done twice fast → CSS `.anim-press` re-triggers fine; `Tasks::CompleteService` already idempotent on `pending → pending_approval`.

**Turbo morph + FX re-fire**
- `data-fx-fired="true"` sentinel prevents replay after morph
- New celebrations use timestamped DOM IDs (`celebration_<unix_ms>`) so morph treats them as fresh nodes

**`prefers-reduced-motion: reduce`**
- CSS layer: every keyframe + transition guarded inside the media query → final state applied instantly
- JS layer: `window.matchMedia("(prefers-reduced-motion: reduce)").matches` checked once at connect, branches every handler
- Confetti: skipped entirely
- Modal: still opens (informational), no entry animation
- Count-up: skipped, sets final value directly
- Toast: still shown, no slide-in
- Sets `data-fx-fired-reduced="true"` on processed nodes for spec assertions

**Stream delivery failure**
- Channel disconnect → no celebration. Page reload shows new balance via normal render. No retry — celebrations are ambient, not load-bearing.

**Modal dismiss**
- Auto-dismiss timer 2.5s (paused on hover/tap)
- Tap-anywhere dismisses
- Esc key dismisses
- Focus trap during open (existing `Ui::Modal` behavior preserved)

**Confetti DOM cleanup**
- 2.5s setTimeout cleanup, layer cleared between bursts

**Streak service failures**
- `Streaks::CheckService` is read-only → safe to skip on failure
- Wrapped in `rescue StandardError` + `Rails.logger.warn`; approve flow continues unaffected

**Threshold double-cross** (e.g. 99 → 105 crosses 100)
- Service returns single tier `:threshold-100`, payload includes which threshold

**Streak + threshold collision** (single approve hits both a streak day AND a threshold cross)
- Priority order: `:streak` > `:threshold` > `:approved` base
- `Streaks::CheckService` returns at most one result; computes both internally, returns the higher-priority one. Lower-priority event silently dropped (logged via `Rails.logger.info`). Acceptable: one BIG celebration per approve event keeps UX coherent.

**`Ui::Toast` overflow**
- Stack max 3. New toasts push old off (Motion One slide-out). Auto-dismiss 3s each.

## Testing

### Unit tests only (RSpec)

| Spec | Coverage |
|---|---|
| `spec/services/ui/celebration_spec.rb` | `tier_for(:approved, ...)` returns `:big`; threshold/streak override paths; unknown event returns `:none` |
| `spec/services/streaks/check_service_spec.rb` | 3/7/14-day window detection from `ActivityLog`; threshold cross detection (49→55 fires `:threshold-50`); no false-fire on no-cross; rescue path returns nil |
| `spec/services/tasks/approve_service_spec.rb` (extend) | Broadcast partial includes `data-fx-event` + `data-fx-tier`; tier matches `Ui::Celebration` decision; streak override applied |
| `spec/services/rewards/redeem_service_spec.rb` (extend) | Same broadcast assertions |
| `spec/components/ui/modal_component_spec.rb` (extend) | Each `variant:` renders correct DOM (icon, color band, dismiss attrs); celebration variant includes confetti layer |
| `spec/components/ui/toast_component_spec.rb` | Stack behavior (≤ 3), variants, auto-dismiss attrs |

No system / Capybara / JS tests. Stimulus + animations verified by manual smoke.

### Manual smoke checklist

- [ ] Approve → confetti + modal + count-up
- [ ] Redeem → gold-palette confetti + modal with reward title
- [ ] Streak milestone (force via 3 consecutive day approvals)
- [ ] Threshold cross (force via large-point task)
- [ ] All-missions-cleared celebration
- [ ] Two BIG events queue correctly (200ms gap, single confetti burst)
- [ ] Toast stack — fire 5, see top 3
- [ ] `prefers-reduced-motion` off — full effects
- [ ] `prefers-reduced-motion` on — instant state, no confetti, modal opens without animation
- [ ] Mobile tap on iOS Safari — Motion One spring feels natural, no jank

## Out of Scope (Separate Specs)

- Parent UI per-screen polish (own spec)
- Audio / sound effects (parent-consent design + asset pipeline)
- Visual regression / screenshot diffing
- View Transitions API for cross-document navigation
- Animation timing precision tests

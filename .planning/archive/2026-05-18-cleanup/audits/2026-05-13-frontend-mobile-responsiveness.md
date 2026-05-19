# Frontend Audit — Mobile Responsiveness, Gaps & Inconsistencies

**Date:** 2026-05-13
**Scope:** Every view under `app/views/`, every ViewComponent under `app/components/ui/`, layouts, navs, theme/base CSS.
**Focus:** Mobile rendering, spacing, touch targets, DESIGN.md compliance.

---

## TL;DR

| Severity | Count |
|---|---|
| 🔴 Critical (breaks mobile layout) | 3 |
| 🟠 High (visible regression / a11y / inconsistency) | 8 |
| 🟡 Medium (DESIGN.md violations, cosmetic) | 9 |
| 🔵 Low (cleanup) | 5 |

The single most impactful issue is `.screen` being absolutely-positioned on mobile (`app/assets/stylesheets/tailwind/base.css:63-72`), which silently breaks the kid layout's `max-w-[430px]` shell on every kid-facing page and hides the Flash component above it. Fixing this one rule cascades into the majority of the "espaçamentos e tamanhos errados no mobile" the user is observing.

---

## 🔴 Critical

### C1. `.screen` is `position: absolute; inset: 0` on mobile — breaks kid shell

**File:** `app/assets/stylesheets/tailwind/base.css:63-72`
**Affects:** every kid screen (`kid/dashboard/index`, `kid/rewards/index`, `kid/wallet/index`, `kid/missions/new`) + all auth screens.

```css
.screen {
  position: absolute;   /* ← detaches from layout flow */
  inset: 0;             /* ← fills viewport, not <main> */
  overflow-y: auto;     /* ← internal scroll, not body */
  …
}
```

`<main>` in `app/views/layouts/kid.html.erb:12` has `max-w-[430px] md:max-w-[560px] lg:max-w-[720px] mx-auto` — but `.screen` has no positioned ancestor (main is `static`, body is `static`), so the absolute box hangs off the initial containing block (the viewport). **On every viewport <1024px the kid shell goes full-width**, ignoring the 430/560/720 caps. It also moves scrolling from `<body>` into `.screen`, which:

- Hides `<%= render Ui::Flash::Component.new %>` rendered above `<%= yield %>` in the layout (it sits behind/above the absolute layer)
- Breaks iOS pull-to-refresh, swipe-back gesture, and address-bar auto-hide
- Causes the kid bottom nav (`fixed`) to need a 120px padding hack (`.screen.with-nav { padding-bottom: 120px }`) that the layout's own `pb-24 md:pb-10` already provides

Auth screens (`family_sessions/new`, `registrations/new`, `invitations/show`, `password_resets/*`, `profile_sessions/new`) "accidentally" work because they add a Tailwind `relative` utility class on the same node (`<div class="screen screen-enter relative">`), which overrides the absolute positioning. Kid screens don't — only `screen-enter`/`screen-enter-right` + `with-nav`.

There is a parallel definition in `app/assets/stylesheets/design_system.css:34-53` that **uses `position: relative` correctly** — but `design_system.css` is **not imported** by `app/assets/stylesheets/application.css:1-11`. It's orphaned. The buggy base.css version is the only one that ships.

**Fix:** replace the base.css `.screen` block with the saner relative version (and delete the orphan design_system.css, or import it and delete the base.css copy).

```css
/* app/assets/stylesheets/tailwind/base.css */
.screen {
  position: relative;
  width: 100%;
  min-height: 100svh;
  padding: var(--space-5) var(--space-6);
  display: flex;
  flex-direction: column;
}
.screen.with-nav { padding-bottom: 120px; }
@media (max-width: 640px) { .screen { padding: var(--space-4); padding-bottom: 120px; } }
@media (min-width: 1024px) { .screen { padding: var(--space-6) 0 var(--space-6); max-width: none; } }
```

Drop the `max-width: 900px` override on `≥1024px` so the kid layout's `max-w-[720px]` wins.

---

### C2. Parent mobile bottom nav ignores iOS safe-area-inset-bottom

**File:** `app/views/shared/_parent_nav.html.erb:94-115`

```erb
<div class="fixed bottom-0 left-0 right-0 h-[72px] bg-white/80 … z-40 lg:hidden">
```

No `pb-[env(safe-area-inset-bottom)]`, no `bottom: max(0, env(safe-area-inset-bottom))`. On iPhone with home indicator the bottom row of icons sits under the indicator. Kid nav handles this correctly (`bottom: max(20px, env(safe-area-inset-bottom))` at `_kid_nav.html.erb:12`), so the same treatment should apply.

**Fix:** add `pb-[env(safe-area-inset-bottom)]` (and bump `h-[72px]` to grow with the inset, or split height + inset padding).

---

### C3. Parent mobile sticky header ignores safe-area-inset-top

**File:** `app/views/shared/_parent_nav.html.erb:4` and `app/views/shared/_head.html.erb:1`

Viewport is declared `viewport-fit=cover` (correct), but the parent mobile header `<div class="… h-[64px] … sticky top-0 z-40">` has no `padding-top: env(safe-area-inset-top)`. On notched/Dynamic Island iPhones the LittleStars wordmark and burger icon collide with the status-bar punch-out in PWA standalone mode.

**Fix:** add a `pt-[env(safe-area-inset-top)]` wrapper or use `padding-top: max(0px, env(safe-area-inset-top))` on the bar itself, growing the visual height to `64px + inset`.

---

## 🟠 High

### H1. Kid layout `md:pb-10` is too small for the fixed bottom nav

**File:** `app/views/layouts/kid.html.erb:12`

```erb
<main class="… pb-24 md:pb-10">
```

The bottom nav stays `fixed` at every viewport (not hidden at `md`). Nav visual height is ~52px + 20px bottom offset = ~72px. `md:pb-10` is 40px — content scrolls underneath the nav on tablets / iPad portrait. Use `pb-24 md:pb-24` or `pb-[max(96px,env(safe-area-inset-bottom)+80px)]`.

### H2. Parent mobile nav drops half the destinations

**File:** `app/views/shared/_parent_nav.html.erb:95-101`

Sidebar has 7 items (Início, Crianças, Missões, Prêmios, Categorias, Aprovações, Configurações). Mobile bottom bar has only 4 (Início, Pendências, Missões, Prêmios). On mobile, **Crianças, Categorias, Configurações are reachable only via the burger drawer** — but the drawer's toggle is in the top-right (`#sidebar-toggle`) and the user has no visual hint these screens exist from the bottom nav. Either:

- add a 5th "Mais" tab that opens the drawer, or
- move Configurações into the bottom nav (replace Prêmios with a Mais menu).

### H3. Touch targets below 44×44px on multiple controls

DESIGN.md §10 requires 44×44px minimum. Violators:

| Control | File:line | Current size |
|---|---|---|
| Filter pill (`Ui::FilterChips`) | `app/components/ui/filter_chips/component.html.erb:12` | `px-4 py-2` → ~36px tall |
| Category tab (`cat-tab`) | `app/components/ui/category_tabs/category_tabs.css:11` | `px-3.5 py-2` → ~34px tall |
| Approval row reject/approve compact | `app/components/ui/approval_row/component.html.erb:23,30` | `padding: 8px 14px` → ~34px tall |
| Reward catalog edit/delete | `app/components/ui/reward_catalog_card/component.html.erb:48,54` | `w-9 h-9` = 36×36px |
| PIN reset input + button | `app/views/parent/settings/show.html.erb:43-48` | `!py-2 !px-3` field → ~32px |
| Kid rewards "Histórico" ghost btn | `app/views/kid/rewards/index.html.erb:40` | `Ui::Btn size: "sm"` (~36px) |

Fix the components (not every call-site): raise filter pills, cat-tabs, approval-row buttons, reward-card icon-buttons to `min-h-[44px]` / `w-11 h-11`. Use padding to grow the hit area without enlarging the visible chip if needed.

### H4. Kid bottom nav has only 3 items but stretches edge-to-edge visually unconstrained

**File:** `app/views/shared/_kid_nav.html.erb:9-13`

```erb
<nav … class="fixed left-1/2 -translate-x-1/2 flex items-center gap-2 z-40 px-2 py-2 …"
     style="bottom: max(20px, env(safe-area-inset-bottom)); …">
```

No `max-w-*`. With three items it's narrow (~180px) and visually balanced, but if a 4th item is ever added it could overflow on a 320px (iPhone SE) viewport. Defensive: `max-w-[calc(100vw-32px)]`.

### H5. `KidTopBar` has no min-h on its action buttons

**File:** `app/components/ui/kid_top_bar/component.html.erb:24-29`

The "Trocar" button is constructed inline with `padding: 6px 12px` + an explicit `min-h-[44px]` on the `<button>` — but the icon and text inside use `font-size: 11px` and the inline padding implies ~30px visual height. The 44px class is honoring touch target, but the rendered button looks oversized relative to its content because of the discrepancy. Either remove the `min-h-[44px]` (and accept the smaller touch target — bad) or pad properly so the visual size matches 44px. Recommended: bump padding to `padding: 10px 14px` and drop `min-h-[44px]`.

### H6. Auth/landing screens render outside the kid/parent shells but reuse `.app-shell` / `.viewport` classes that aren't loaded

**File:** `app/views/layouts/application.html.erb:9-11`

```erb
<body class="app-shell" data-palette="sky">
  <div class="viewport">
```

`.app-shell` and `.viewport` are defined in the orphaned `app/assets/stylesheets/design_system.css:9-21` but not imported. They render as plain `<body>` + `<div>`. The pages still work because `base.css` sets `html, body { background: var(--bg-deep); min-height: 100% }`, but the `data-palette="sky"` swap is meaningless on these screens because there's no element styled against the palette tokens. Decide: either drop the orphan classes, or import design_system.css and let them do their job.

### H7. Family-goal widget violates "no emoji as icons"

**File:** `app/views/shared/_family_goal_widget.html.erb:12,21,26,32`

```erb
<div class="text-3xl shrink-0"><%= eligible ? "🎉" : "🌟" %></div>
…
<span><%= earned %>⭐ / <%= target.cost %>⭐</span>
…
button_to "Resgatar meta 🎁", …
…
"✓ Meta batida! Mamãe ou Papai libera o prêmio."
```

Plus `submission_comment` is prefixed with literal `💬` in `app/components/ui/approval_row/component.html.erb:78`, and `Ui::ApprovalRow` compact subtitle hard-codes `"vale 10 ⭐"` at `component.html.erb:17`. DESIGN.md §16: "Never use emoji as icons." Replace with `Ui::Icon::Component`. Bonus: the widget's `<button class="… bg-primary text-white …">` should be `Ui::Btn::Component` per DESIGN.md §6.

### H8. Body default font-weight contradicts DESIGN.md

**File:** `app/assets/stylesheets/tailwind/base.css:42-52`

```css
html, body { … font-weight: 600; }
```

DESIGN.md §3: "All font weights default to 700 (font-bold)." 600 ships a thinner Nunito (and Google Fonts is only loading `wght@700;800` — see `app/views/shared/_head.html.erb:4`), so 600 falls back to whatever browser interpolates from 700 → 700 (no 600 face loaded). Set to `700` so the cascade is honest.

---

## 🟡 Medium — DESIGN.md violations & UI inconsistencies

### M1. Inline styles where utilities or components exist

DESIGN.md §11: "Don't write `style='...'` for anything a utility class or component already covers." Heavy offenders (each has 5+ inline styles that map 1:1 to existing tokens/utilities):

- `app/views/shared/_kid_nav.html.erb:11-26` — entire nav styled via inline `background`, `border`, `border-radius`, `box-shadow` per link; this is a component-shaped pattern that should be `Ui::KidBottomNav::Component`.
- `app/views/kid/dashboard/index.html.erb:50,56,70,72,97,149` — level card, progress bar, counter pill, ghost-CTA all inline-styled.
- `app/views/kid/missions/new.html.erb:22-23,30-31,36-38,46-49,55-57,62-63,13-14` — every input duplicates `form-input` instead of using the class. Inconsistent with `parent/global_tasks/_form.html.erb` which correctly uses `form-input`.
- `app/views/parent/activity_logs/index.html.erb:19-43,72-91` — summary cards and ledger rows hand-rolled instead of `Ui::StatCard` + `Ui::ActivityRow` / `Ui::HistoryRow`.
- `app/components/ui/approval_row/component.html.erb:23-34, 87-104` — inline button styles that should be `Ui::Btn` variants.

### M2. Two patterns for page-entry animation

`page-enter` / `page-enter-right` (parent) vs `screen-enter` / `screen-enter-right` (kid + auth). Same keyframes (`design_system.css:55-68` and `tailwind/animations.css`). Pick one naming convention.

### M3. Kid `new mission` form drifts from the design system

`app/views/kid/missions/new.html.erb:18-58` writes raw `<input class="w-full px-4 py-3 rounded-[12px] border-2 …" style="border-color: var(--hairline); …">` for every field. Compare against `parent/global_tasks/_form.html.erb:30-34` which uses the `form-input` class. The kid form fields are also 12px radius vs the design's 14px (`--r-lg`) standard.

### M4. Reward catalog tile has inconsistent radius

`app/components/ui/reward_catalog_card/component.html.erb:6` — outer card `rounded-[16px]` matches §4. But the inner icon tile is `rounded-[14px]` (line 10), inner star pill is `rounded-[8px]` (line 29), tag chip is `rounded-[6px]` (line 22). DESIGN.md §4 only allows 10/12/14/16/20/999. The 8px and 6px values are off-scale.

Similar off-scale values: `app/views/kid/dashboard/index.html.erb:56` (`border-radius: 8px` for the level pill) and `app/views/parent/activity_logs/index.html.erb:22,29` (also 10/8 mixed).

### M5. `home indicator` clearance on iOS — kid wallet & rewards inside `.screen`

Once C1 is fixed and `.screen` is `position: relative`, the `padding-bottom: 120px` works but doesn't honor `env(safe-area-inset-bottom)`. Switch to `padding-bottom: max(120px, calc(80px + env(safe-area-inset-bottom)))` so the nav + indicator both clear.

### M6. Kid mission `bubble` cards use 18×20 padding — too tall on small phones

`app/components/ui/mission_card/component.html.erb:109` — `padding: 18px 20px` plus 58×58 icon. On a 320px viewport (iPhone SE) the card is ~80px tall before content. Stack of 6 cards eats most of the visible area. Reduce mobile padding to `14px 16px` via a `sm:` modifier or a `compact` size prop.

### M7. Mission frequency cards may collapse below readable width

`app/views/parent/global_tasks/_form.html.erb:99-118` — `grid-cols-2 sm:grid-cols-4 gap-2.5`. On 320px viewport each cell is ~140px wide — fine. But the labels (`Diária`, `Semanal`, `Mensal`, `Única`) plus 22px icons plus helper text fit only because helper text is 10px. Add explicit `min-w-0` and `truncate` on the helper line, and consider `whitespace-nowrap` on the label.

### M8. PIN reset row at parent settings overflows on small mobile

`app/views/parent/settings/show.html.erb:30-49` — avatar (32px) + name + role + PIN field `w-[110px]` + Resetar button on a single row inside a 360px-ish container. Long names like "Maria Eduarda" wrap and force the PIN field below or get clipped. Stack vertically below `sm:` with `flex-col sm:flex-row`.

### M9. Approval-row "compact" subtitle uses literal `⭐`

`app/components/ui/approval_row/component.html.erb:17` and `app/components/ui/reward_catalog_card/component.html.erb` (status dot) use Unicode emoji/glyph instead of `Ui::Icon`. Replace with the inline `Ui::Icon::Component.new(:star, size: 12, …)`.

---

## 🔵 Low

### L1. Orphaned stylesheet

`app/assets/stylesheets/design_system.css` is not imported from `application.css`. Either delete it or import it and remove the duplicated rules from `tailwind/base.css`. Currently it's dead code that makes the codebase harder to reason about.

### L2. Duplicate `<%# Mobile sticky header %>` comment

`app/views/shared/_parent_nav.html.erb:1-2` and `:17-18` — comment repeated twice. Cosmetic.

### L3. Profile color picker uses radio dots but no checked-state label fallback

`app/views/parent/profiles/_form.html.erb:51-60` — color swatches relying entirely on `peer-checked:[&>span]:opacity-100` to show the check icon. Add an `aria-checked` mirror and visible focus ring for keyboard users.

### L4. `Ui::TopBar` truncates titles past 380px on mobile

`app/components/ui/top_bar/component.html.erb:16` — `max-w-[380px]` on the H1 cuts longer headings ("Convidar responsável") on narrow phones. Drop the cap or make it `max-w-[60vw] sm:max-w-[380px]`.

### L5. `Ui::PageHeader` doesn't stack on mobile when right slot is present

`app/components/ui/page_header/component.html.erb:1` — `flex items-start justify-between` keeps title and the right-slot button on the same row. On 320px viewports with `Nova missão` / `+ Adicionar` buttons the title gets squeezed. Add a `flex-col sm:flex-row` breakpoint or move the right slot below the title on `<sm`.

---

## Suggested fix order (smallest blast radius first)

1. **C1** — patch `.screen` in `tailwind/base.css`, delete or import `design_system.css`. (One CSS file edit; instantly fixes mobile kid shell width, restores Flash visibility, restores body scrolling.)
2. **H8** — body `font-weight: 700`.
3. **C2 + C3 + M5** — safe-area on parent nav (top + bottom), kid nav bottom padding.
4. **H1** — kid layout `md:pb-24`.
5. **H3** — bump touch targets in `Ui::FilterChips`, `cat-tab`, `Ui::ApprovalRow` compact buttons, `Ui::RewardCatalogCard` icon actions.
6. **H7 + M9** — replace emoji with `Ui::Icon`, replace ad-hoc buttons with `Ui::Btn` in `family_goal_widget` and approval row.
7. **M3** — rewrite `kid/missions/new` to use `form-input` and `form-label` instead of inline styles.
8. **H2** — add 5th "Mais" tab to parent mobile nav.
9. **M1** — gradual: extract a `Ui::KidBottomNav` and remove inline styles from kid_dashboard hero/level card.
10. Remainder of the medium/low items.

---

## How to verify mobile rendering after fixes

Inside the `web` container (`make shell`):

```bash
bundle exec rspec spec/system  # system specs use Capybara/Cuprite
```

For visual checks: `make dev` then open Playwright MCP (already configured) and walk through:

1. `/family_sessions/new` at viewport 375×667 (iPhone SE)
2. `/profile_sessions/new`
3. `/kid/dashboard` with a child profile (verify 430px shell + bottom nav clearance)
4. `/kid/rewards` and `/kid/wallet` (tab switching)
5. `/parent/dashboard` at 375×667 (mobile drawer) + 1280×800 (desktop sidebar)
6. `/parent/approvals` (filter chips on mobile)
7. Standalone PWA mode (Add to Home Screen) to test safe-area insets

Snapshots saved under `.playwright-mcp/` already serve as a baseline reference.

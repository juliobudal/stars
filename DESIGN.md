# LittleStars Design System

Source of truth for the **LittleStars Duolingo Style** visual language. If a pattern isn't in here, it shouldn't ship.

---

## 1. Principles

- **Playful · gamified · 3D** — every interactive element has a depth shadow (`0 4px 0`); buttons depress on click (`translateY(2px); box-shadow: none`).
- **Bold weight, compact radii** — Nunito 700/800 throughout; corners 10–16px (no soft 22–32px).
- **Mobile-first** — kid shells target `max-w-[430px]`; parent shells expand with sidebar at `lg`.
- **One token system** — every color/font/radius/shadow comes from a CSS variable in `tailwind/theme.css`. Raw hex is only allowed in that file.
- **Rails Way** — ViewComponents + CSS vars. No inline hex in templates, no copy-pasted markup.

---

## 2. Palette — Duolingo

All tokens defined in `app/assets/stylesheets/tailwind/theme.css`. Use the variable, never the hex.

| Token | Hex | Role |
|---|---|---|
| `--bg-deep` / `--bg-mid` | `#F7F7F7` | App background |
| `--bg-soft` | `#DCFCE7` | Subtle surfaces / primary tint surface |
| `--surface` | `#FFFFFF` | Cards |
| `--surface-2` / `--surface-muted` | `#F7F7F7` | Inset / chips / muted |
| `--primary` | `#58CC02` | Brand · Duolingo green |
| `--primary-2` / `--success-2` | `#46A302` | Primary depth shadow |
| `--primary-soft` | `#DCFCE7` | Primary tint |
| `--primary-glow` | `#86EFAC` | Primary ring |
| `--star` | `#FFC800` | Stars / rewards |
| `--star-2` | `#E0A800` | Star depth |
| `--star-soft` | `#FFF4DA` | Star tint |
| `--c-reward-text` / `--c-amber-dark` | `#B36F00` | Star count text |
| `--hairline` | `#E5E5E5` | Borders / dividers |
| `--c-sky` / `-soft` / `-dark` | `#1CB0F6` / `#DDF4FF` / `#1899D6` | Info accent |
| `--c-info-500` / `-600` / `-100` | `#1CB0F6` / `#1899D6` / `#DDF4FF` | Semantic info aliases |
| `--c-mint` / `-soft` / `-dark` | `#58CC02` / `#DCFCE7` / `#46A302` | Success-adjacent (= primary) |
| `--c-peach` / `-soft` / `-dark` | `#F472B6` / `#FCE7F3` / `#BE185D` | Pink accent |
| `--c-rose` / `-soft` / `-dark` | `#EC4899` / `#FCE7F3` / `#BE185D` | Rose accent |
| `--c-lilac` / `-soft` / `-dark` | `#CE82FF` / `#F3E8FF` / `#7C3AED` | Character / kid-purple |
| `--c-character-500` / `-600` | `#CE82FF` / `#A855E0` | Kid avatar fill / depth |
| `--c-coral` / `-dark` / `-soft` | `#FF9600` / `#CC7700` / `#FFE4CC` | Streak / warning |
| `--c-streak` / `--c-streak-2` | `#FF9600` / `#CC7700` | Flame badge |
| `--success` / `--success-2` | `#58CC02` / `#46A302` | Semantic success |
| `--danger` / `--danger-2` | `#FF4B4B` / `#C53232` | Semantic danger |
| `--text` / `--text-muted` / `--text-soft` | `#4B4B4B` / `#777777` / `#AFAFAF` | Foreground ramp |

**Per-kid palette overrides:** `data-palette="peach|rose|mint|sky|lilac|coral"` on the kid layout reassigns `--primary` family to that accent. Shadows, typography, and radii inherit Duolingo defaults — only the primary color tints. The canonical kid color map (with avatar fills) lives in `app/components/ui/smiley_avatar/component.rb` `COLOR_MAP`.

**Rule:** all color usage in views goes through a CSS variable. Raw hex is only allowed in `tailwind/theme.css`.

---

## 3. Typography

```css
--font-display: 'Nunito', system-ui, sans-serif;
--font-body:    'Nunito', system-ui, sans-serif;
```

Nunito is the only display + body family. Loaded via Google Fonts in `shared/_head.html.erb`. Tailwind's `--font-sans` also maps to Nunito. **Do not use Fraunces or Inter.**

| Role | Class / Pattern | Size | Weight |
|---|---|---|---|
| H1 | `font-extrabold text-2xl` | 26px | 800 |
| H2 | `font-extrabold text-xl` | 22px | 800 |
| H3 / Card title | `font-extrabold text-lg` | 18px | 800 |
| Body default | — | 14–15px | 700 |
| Subtitle / meta | `text-sm text-text-muted` | 13px | 700 |
| Eyebrow / label | uppercase tracking-[0.5px] text-text-muted | 11–12px | 800 |
| Button label | uppercase tracking-[0.5px] | 12–14px | 800 |
| Caption / helper | `text-xs` | 11px | 700 |

All font weights default to 700 (`font-bold`). 800 (`font-extrabold`) is the emphasis weight — use it for headings, buttons, stat numbers, badge labels, eyebrows.

---

## 4. Spacing & Layout

Spacing scale (`--space-1..8`): `4 / 10 / 14 / 20 / 28 / 36 / 48 / 64`.

Radius scale: `--r-sm 10 · --r-md 12 · --r-lg 14 · --r-xl 16 · --r-featured 20 · --r-full 999`.

| Element | Radius |
|---|---|
| Pills / small chips | 10–12px |
| Buttons | 14px (`var(--r-lg)`) |
| Cards / sections | 16px (`var(--r-xl)`) |
| Modals / hero | 20px |
| Avatars / circular badges | 999px |

Shells:
- **Kid shell** — single column, `max-w-[430px]`, sticky bottom nav, `BgShapes` background.
- **Parent shell** — fixed sidebar `220px` at ≥1024px (`--width-sidebar`), off-canvas (<1024px) with mobile header bar. Main column `max-w-[900px]`, white background.

---

## 5. Shadows — 3D depth

```css
--shadow-btn:        0 4px 0 rgba(0, 0, 0, 0.12);   /* primary depth uses --primary-2 */
--shadow-btn-hover:  0 6px 0 rgba(0, 0, 0, 0.12);
--shadow-card:       0 4px 0 rgba(0, 0, 0, 0.08);
--shadow-lift:       0 6px 0 rgba(0, 0, 0, 0.08);
```

**Per-color button depth utilities** (defined in `theme.css` `@utility` blocks):
- `shadow-btn-primary` → `0 4px 0 var(--primary-2)`
- `shadow-btn-success`, `shadow-btn-destructive`, `shadow-btn-warning`, `shadow-btn-secondary` — same pattern.
- `-hover` variant adds 1px depth, `-active` collapses to `0 1px 0`.

**3D motion contract** (mandatory for any element with a depth shadow):
```css
.depth-element { transition: transform 0.05s; }
.depth-element:active { transform: translateY(2px); box-shadow: none !important; }
@media (prefers-reduced-motion: reduce) {
  .depth-element { transition: none; }
}
```

Cards lift on hover: `transform: translateY(-2px); box-shadow: var(--shadow-lift);`.

---

## 6. Components

Location: `app/components/ui/<name>/`. Always reach for a `Ui::*` first; only write inline markup if no component fits.

### Navigation & layout

| Component | Path | Key props / notes |
|---|---|---|
| `Ui::TopBar` | `ui/top_bar/` | `title:`, `subtitle:`, `back_url:` — parent sub-page header |
| `Ui::KidTopBar` | `ui/kid_top_bar/` | kid-shell page header with avatar + palette |
| `Ui::PageHeader` | `ui/page_header/` | hero section with eyebrow + title + subtitle |
| `Ui::Drawer` | `ui/drawer/` | off-canvas sidebar panel (mobile parent nav) |
| `Ui::Tabs` | `ui/tabs/` | horizontal tab bar; use for top-level content switching |
| `Ui::CategoryTabs` | `ui/category_tabs/` | pill-style category switcher inside a page |
| `Ui::FilterChips` | `ui/filter_chips/` | `items:`, `active:`, `controller:` (3D pills: active = colored fill + colored border + depth shadow; idle = white + hairline border) |
| `Ui::BgShapes` | `ui/bg_shapes/` | floating blurred orb layer; rendered inside kid layout |

### Buttons & actions

| Component | Path | Key props / notes |
|---|---|---|
| `Ui::Btn` | `ui/btn/` | `variant:`, `size:`, `tone:` — primary driver of `shadow-btn-*` depth utilities |

### Cards & data display

| Component | Path | Key props / notes |
|---|---|---|
| `Ui::Card` | `ui/card/` | base white surface with `2px hairline` + `0 4px 0` shadow |
| `Ui::StatCard` | `ui/stat_card/` | `value:`, `label:`, `icon:`, `tint:` (pastel bg + 2px colored border) |
| `Ui::StatMetric` | `ui/stat_metric/` | compact inline stat (number + label) |
| `Ui::HeaderStatChip` | `ui/header_stat_chip/` | pill stat chip in page headers |
| `Ui::KidProgressCard` | `ui/kid_progress_card/` | `kid:`, `awaiting_count:`, `missions_count:` (avatar 3D ring + level pill + progress bar) |
| `Ui::KidPlaceholderCard` | `ui/kid_placeholder_card/` | empty slot card (add-kid CTA) |
| `Ui::MissionCard` | `ui/mission_card/` | `mission:`, `status:`, `variant:` (16px radius, 2px border, card shadow, hover lift) |
| `Ui::MissionListRow` | `ui/mission_list_row/` | compact row variant for mission lists |
| `Ui::ApprovalRow` | `ui/approval_row/` | `kid:`, `title:`, `points:`, `approve_url:`, `reject_url:` |
| `Ui::ActivityRow` | `ui/activity_row/` | `log:` or explicit fields; `with_divider:` — earn/redeem ledger entry |
| `Ui::HistoryRow` | `ui/history_row/` | read-only log row for activity history pages |
| `Ui::RedemptionRow` | `ui/redemption_row/` | reward redemption record with status badge |
| `Ui::RewardCatalogCard` | `ui/reward_catalog_card/` | `reward:` — icon cell (56×56, tint + border) + star pill + edit/delete actions |
| `Ui::CategoryRow` | `ui/category_row/` | category label + grouped items in a list |

### Avatars & identity

| Component | Path | Key props / notes |
|---|---|---|
| `Ui::SmileyAvatar` | `ui/smiley_avatar/` | `kid:`, `size:`, `face:` — per-kid palette from `COLOR_MAP` |
| `Ui::Avatar` | `ui/avatar/` | generic avatar (initials fallback) |
| `Ui::KidAvatar` | `ui/kid_avatar/` | kid-specific avatar with palette ring |
| `Ui::KidInitialChip` | `ui/kid_initial_chip/` | inline chip with kid initial + palette color |
| `Ui::ProfileCard` | `ui/profile_card/` | profile-select card (160px, 20px radius, avatar + name + role badge) |
| `Ui::ProfilePicker` | `ui/profile_picker/` | full profile selection grid |
| `Ui::LogoMark` | `ui/logo_mark/` | LittleStars star logo glyph |
| `Ui::Brand` | `ui/brand/` | full logo lockup (mark + wordmark) |

### Badges & chips

| Component | Path | Key props / notes |
|---|---|---|
| `Ui::Badge` | `ui/badge/` | generic status/count badge |
| `Ui::Chip` | `ui/chip/` | small pill label |
| `Ui::BalanceChip` | `ui/balance_chip/` | star balance display pill |
| `Ui::StarBadge` | `ui/star_badge/` | star count badge with yellow tint |
| `Ui::StarValue` | `ui/star_value/` | inline star icon + number |
| `Ui::StreakBadge` | `ui/streak_badge/` | `streak:`, `size:` (yellow tint + flame + count) |

### Forms

| Component | Path | Key props / notes |
|---|---|---|
| `Ui::Toggle` | `ui/toggle/` | green track 52×30 + white thumb + inset depth shadow |
| `Ui::Select` | `ui/select/` | styled `<select>` with hairline border + focus ring |
| `Ui::IconPicker` | `ui/icon_picker/` | 8-col grid of icon cells; selected = tint bg + colored border + depth |
| `Ui::ColorSwatchPicker` | `ui/color_swatch_picker/` | per-kid color picker swatches |
| `Ui::FormSection` | `ui/form_section/` | grouped form block with eyebrow label |
| `Ui::FormErrors` | `ui/form_errors/` | model error summary (list above form) |

### Overlays & feedback

| Component | Path | Key props / notes |
|---|---|---|
| `Ui::Modal` | `ui/modal/` | Turbo-compatible dialog; 20px radius; 24px for PIN exception |
| `Ui::PinModal` | `ui/pin_modal/` | 340px PIN entry dialog (see §15) |
| `Ui::Toast` | `ui/toast/` | auto-dismiss 3–5 s; `type: success|error|info`; `aria-live="polite"` |
| `Ui::Flash` | `ui/flash/` | reads Rails `flash`; delegates to Toast |
| `Ui::Alert` | `ui/alert/` | inline alert banner (non-dismissible) |
| `Ui::Spinner` | `ui/spinner/` | loading indicator; use inside `Ui::Btn` during async ops |
| `Ui::Tooltip` | `ui/tooltip/` | hover/focus tooltip; always keyboard-reachable |
| `Ui::TurboConfirm` | `ui/turbo_confirm/` | custom Turbo confirm dialog (replaces browser `confirm()`) |
| `Ui::Celebration` | `ui/celebration/` | full-screen success overlay |
| `Ui::Confetti` | `ui/confetti/` | confetti particle burst layer |

### Utility

| Component | Path | Key props / notes |
|---|---|---|
| `Ui::Empty` | `ui/empty/` | `icon:`, `title:`, `subtitle:`, `color:` — zero-state screen |
| `Ui::Icon` | `ui/icon/` | `name`, `size:`, `color:`, `weight:` — SVG icon wrapper |
| `Ui::IconTile` | `ui/icon_tile/` | square tile with icon + tint background |
| `Ui::Group` | `ui/group/` | grouped list container with hairline dividers |
| `Ui::Heading` | `ui/heading/` | semantic heading with Nunito 800 + optional eyebrow |
| `Ui::Clipboard` | `ui/clipboard/` | copy-to-clipboard button wrapper |
| `Ui::Tokens` | `ui/tokens.rb` (module) | `category_for(key)`, `frequency_for(key)`, `tint_soft`, `tint_fg` |

---

## 7. Page Patterns

### Kid shell
- `div.screen.with-nav` wrapped in `layouts/kid.html.erb`
- `max-w-[430px]`, single column, bottom pill nav
- `Ui::BgShapes` renders floating orbs
- `data-palette="<%= palette_for(current_profile) %>"` on `<body>` enables per-kid accent

### Parent shell
- `layouts/parent.html.erb` — defaults inherit Duolingo green (no explicit `data-palette`)
- Side nav fixed left at ≥1024px (220px wide, white bg, 2px right hairline)
- Active nav item: soft tint background + 2px colored border + colored text (sky-blue accent in mocks; primary green also valid)
- Off-canvas drawer on mobile with header bar toggle
- Main: `max-w-[900px]`, centered, `padding: var(--space-6) var(--space-7) 120px`
- Sidebar footer profile chip: 34×34 green avatar + name + role label

---

## 8. Forms

- `.form-field` wraps each input
- `.form-label` — uppercase 12px tracking 0.5 weight 800 color `var(--text-muted)`
- `.form-input` / `.form-select` — 15px Nunito 700, `2px solid var(--hairline)` resting, focus ring `box-shadow: 0 0 0 3px var(--primary-soft); border-color: var(--primary)`
- Icon picker: 8-col grid, aspect-ratio 1, selected = soft tint bg + colored border + depth shadow (`0 3px 0`)
- Star difficulty picker: 10-cell row, filled = `--star-soft` bg + `--star` border + `0 3px 0 --star-2`, empty = `--surface-2` bg + hairline border
- Frequency cards: 3-col grid, selected = soft tint + colored border + depth shadow
- Toggle: green track + white thumb (see `Ui::Toggle`)

---

## 9. Motion

### Easing tokens (`tailwind/motion.css`)

| Token | Value | Use |
|---|---|---|
| `--ease-spring` | `cubic-bezier(0.34, 1.56, 0.64, 1)` | Modals, pop-ins, spring feedback |
| `--ease-spring-soft` | `cubic-bezier(0.22, 1.4, 0.36, 1)` | Card hover lifts, tile reveals |
| `--ease-snap` | `cubic-bezier(0.4, 0, 0.2, 1)` | Shake, error states, snappy transitions |
| `--dur-fast` | `120ms` | Micro-interactions (press feedback) |
| `--dur-base` | `240ms` | Standard state transitions |
| `--dur-pop` | `380ms` | Spring pops, reveals |

### Motion utility classes

**Use these classes — never write ad-hoc `transition`/`animation` CSS in components.**

#### 3D press utilities (`ls-*`)

| Class | Behavior |
|---|---|
| `ls-btn-3d` | `transition: transform 0.05s` + `:active → translateY(2px), box-shadow: none` |
| `ls-filter-pill` | Same as `ls-btn-3d` — for filter/tab pills |
| `ls-key-3d` | Same — for PIN numpad keys |
| `ls-aux-key` | Same — for secondary keys (backspace) |
| `ls-icon-cell` | `transition 0.05s` + `:active → scale(0.92)` |
| `ls-star-cell` | Same as `ls-icon-cell` — for star difficulty pickers |
| `ls-card-3d` | `transition: transform/box-shadow 0.1s` + `:hover → translateY(-2px), shadow-lift` |

#### Spring animation utilities (`anim-*`)

| Class | Keyframe | Duration | Easing |
|---|---|---|---|
| `anim-press` | `scale(0.96)` on `:active` | `--dur-fast` | `--ease-spring` |
| `anim-tile` | hover lift + shadow | `--dur-base` | `--ease-spring-soft` |
| `anim-pop-in` | fade + scale(0.9) + translateY(8px) → none | `--dur-pop` | `--ease-spring` |
| `anim-pulse-once` | scale 1 → 1.12 → 1 | `--dur-pop` | `--ease-spring` |
| `anim-shake` | translateX zig-zag | `360ms` | `--ease-snap` |
| `anim-bounce-once` | translateY bounce | `500ms` | `--ease-spring` |
| `anim-fade-up` | opacity + translateY(8px) → none | `--dur-base` | `--ease-spring-soft` |
| `anim-shimmer` | loading shimmer gradient | `1.4s infinite` | linear |

#### Legacy `animate-*` classes (`animations.css`)

| Class | Keyframe | Duration |
|---|---|---|
| `animate-slide-in` | `slideIn` (left) | 0.4s |
| `animate-slide-in-right` | `slideInR` (right) | 0.4s |
| `animate-pop-in` | `popIn` | 0.3s |
| `animate-float` | `float` (infinite) | 3s |
| `animate-shake` | `shake` | 0.4s |
| `animate-slide-in-card` | `slideInCard` | 0.4s |
| `animate-pop-card` | `popCard` | 0.4s |
| `animate-star-pulse` | `starPulse` (infinite) | 2s |
| `hover-wobble` | `wobble` on hover | 0.3s |

#### Thematic animations

| Class | Use |
|---|---|
| `ls-mascot-bounce` | Mascot idle bounce (2.5s infinite) |
| `ls-coin-shake` | Coin/star idle rattle (3s infinite) |

### Stagger rule

```erb
style="animation-delay: <%= index * 0.04 %>s"
```
Cap at 5 items (0.16s max delay). Beyond 5, no delay.

### Reduced motion

All `ls-*` and `anim-*` classes have `prefers-reduced-motion: reduce` overrides in `motion.css` — no manual `@media` needed when using these classes. For custom animations, always add:
```css
@media (prefers-reduced-motion: reduce) {
  .my-class { animation: none; transition: none; }
}
```

---

## 10. Accessibility

- Icon-only buttons must carry `aria-label`.
- Tab switchers need `role=tablist` on container and `role=tab` with `aria-selected` on buttons (`Ui::FilterChips` does this).
- Focus rings: inputs use `box-shadow: 0 0 0 3px var(--primary-soft)`. Buttons use `:focus-visible` outline (not `:focus`).
- All interactive nodes must have a non-icon text fallback (`sr-only` if needed).
- 3D buttons keep `:focus-visible` outline distinct from `:active` press state.
- **Modals:** use `inert` on all body siblings when open; return focus to the trigger element on close via WeakMap (not a stored selector). `Ui::Modal` implements this.
- **Toasts:** use `aria-live="polite"` so screen readers announce without stealing focus.
- Minimum touch target: 44×44px. Expand hit area with padding rather than changing the visual size.

---

## 11. Do / Don't

**✗ Don't**
- Write `style="..."` for anything a utility class or component already covers. Allowed exceptions: dynamic values (`width: 73%`, computed `--kid-color`).
- Reference raw hex from views — go through CSS vars.
- Mix old "Berry Pop" lilac/Fraunces tokens with the current system. They were removed.
- Soften the 3D shadow stack — depth shadows must be `0 4px 0`, not blurry. No `rgba(...) 0 4px 12px` for buttons.
- Drop below `font-weight: 700` for body text or `800` for buttons/headings.
- Use border-radius > 20px outside of avatars and modals.
- Duplicate category/frequency metadata across views — use `Ui::Tokens`.

**✓ Do**
- Reach for `Ui::*` first. If no component fits, use `.card` + utility classes.
- If a pattern repeats twice, extract a component in the same PR that needs it.
- Use 2px borders everywhere. Active states swap the border color to the tint, not the thickness.
- Keep kid-facing copy playful, parent-facing copy concise.
- Honor `prefers-reduced-motion: reduce` on every transitioned element.

---

## 12. Component-extraction checklist

Before adding a page, scan the mock for these patterns. If any recur, use the listed component:

**Navigation**
- Page header with back arrow → `Ui::TopBar` (parent) or `Ui::KidTopBar` (kid)
- Hero title + eyebrow + subtitle section → `Ui::PageHeader`
- Segmented pill switcher → `Ui::FilterChips`
- Category/content tabs → `Ui::Tabs` or `Ui::CategoryTabs`
- Off-canvas sidebar → `Ui::Drawer`

**Cards & rows**
- Stat tile → `Ui::StatCard`
- Kid dashboard card → `Ui::KidProgressCard`
- Reward catalog tile → `Ui::RewardCatalogCard`
- Mission card → `Ui::MissionCard`
- Compact mission row → `Ui::MissionListRow`
- Approval row with two actions → `Ui::ApprovalRow`
- Ledger / activity entry → `Ui::ActivityRow`
- Redemption record → `Ui::RedemptionRow`
- Read-only log row → `Ui::HistoryRow`
- Category + items group → `Ui::CategoryRow`
- Empty slot / placeholder → `Ui::KidPlaceholderCard`

**Identity**
- Per-kid avatar → `Ui::SmileyAvatar`
- Avatar with initials fallback → `Ui::Avatar`
- Inline kid initial chip → `Ui::KidInitialChip`
- Profile select card → `Ui::ProfileCard`

**Badges & chips**
- Star balance display → `Ui::BalanceChip`
- Streak counter → `Ui::StreakBadge`
- Star count → `Ui::StarBadge` or `Ui::StarValue`
- Status label → `Ui::Badge` or `Ui::Chip`

**Feedback & overlays**
- Dialog / modal → `Ui::Modal`
- Confirmation before destructive action → `Ui::TurboConfirm`
- Auto-dismiss notification → `Ui::Toast`
- Inline alert → `Ui::Alert`
- Full-screen success → `Ui::Celebration` + `Ui::Confetti`
- Loading indicator → `Ui::Spinner`

**Forms**
- On/off setting → `Ui::Toggle`
- Icon picker → `Ui::IconPicker`
- Color picker → `Ui::ColorSwatchPicker`
- Grouped form block → `Ui::FormSection`
- Validation errors → `Ui::FormErrors`

**Zero states**
- Empty screen → `Ui::Empty`

If a pattern doesn't fit any entry above, add a row to §6 of this file in the same PR.

---

## 13. Component state matrix

| Element | Idle | Hover | Active / Pressed | Selected | Disabled |
|---|---|---|---|---|---|
| Primary button | `bg-primary` + `0 4px 0 --primary-2` | `0 6px 0 --primary-2` + `translateY(-1px)` (optional) | `translateY(2px)` + `box-shadow: none` | — | `opacity: 0.5; cursor: not-allowed` |
| Secondary button | `bg-surface` + `2px hairline` + `0 4px 0 #C9C9C9` | `0 5px 0 #C9C9C9` | `translateY(2px)` + `box-shadow: none` | — | same as primary |
| Filter pill | `bg-surface` + `2px hairline` + `0 3px 0 hairline` | hairline darken | press | colored fill + `2px primary border` + `0 3px 0 --primary-2` | — |
| Card | `bg-surface` + `2px hairline` + `0 4px 0 rgba(0,0,0,0.08)` | `translateY(-2px)` + `0 6px 0 rgba(0,0,0,0.08)` | — | colored border + soft tint bg | reduced opacity |
| Picker cell (icon/star/freq) | `bg-surface-muted` + `2px hairline` | `scale(1.05)` (icon) | `scale(0.92)` (star) | tint bg + colored border + `0 3px 0 depth` | — |
| Input | `2px hairline` | hairline darken | — | `2px primary border` + `0 0 0 3px primary-soft` | reduced opacity |
| Nav item (sidebar) | text-muted + transparent bg | bg-surface-muted | — | sky-tint bg + sky border + sky text | — |
| Toggle | gray track | — | — | green track + white thumb (right) | reduced opacity |

---

## 14. Profile selection (entry screen)

Layout: centered column. Header = 48px yellow logo tile + "LittleStars" 22px/800. H1 "Quem é você?" 28px/800. Subtitle 14px/700 muted. Profile cards in a flex-wrap row (max-width 720px).

**Profile card** (`Ui::ProfileCard`):
- 160px width, 20px radius, 2px hairline border, white bg.
- Card shadow: `0 4px 0 rgba(0,0,0,0.08)`. Hover lift: `translateY(-4px)`.
- Avatar: 88px circle, palette fill, `0 5px 0 [palette-depth]` shadow ring, centered.
- Name below avatar: 17px/800 `var(--text)`.
- Role/status badge: soft tint pill with colored text (e.g., parent = sky soft + sky-dark, kid = lilac soft + lilac-dark + star icon + "12 · Nível 1").
- Optional top-right corner badge: streak count (yellow tile + flame + count) or lock icon (sky tint + lock).
- Selected state (PIN open): 3px primary border + `0 4px 0 var(--primary-2)`.

Footer chip: "Cada perfil é protegido por um PIN" — 14px radius, 2px hairline, surface-muted bg, 12px/700 muted text.

## 15. PIN modal

Backdrop: dim profile select (`filter: blur(2px); opacity: 0.4`) + overlay `rgba(75,75,75,0.45)`.

Modal card (`Ui::PinModal`):
- 340px width, **24px radius** (modal exception), 2px hairline border, white bg.
- Card shadow: `0 8px 0 rgba(0,0,0,0.12)` — taller depth than standard cards.
- Close X button (top-right): 32×32, 10px radius, 2px hairline, `0 2px 0 hairline` shadow, `:active translateY(2px)`.
- Header: 72×72 character avatar with palette fill + `0 4px 0 [palette-depth]`, "Olá, [Name]!" 18px/800, "Digite seu PIN secreto" 12px/700 muted.
- Dot indicators: 4 × 16px circles centered, gap 10px.
  - Filled = palette `[ink]` color + `0 2px 0 [darker-ink]` depth.
  - Empty = white + 2px hairline.
- Number pad: 3-col grid, gap 10px.
  - Each key: aspect 1.2, 14px radius, 2px hairline border, white bg, `0 4px 0 hairline` shadow.
  - Number 22px/800 `var(--text)`.
  - Backspace key: `var(--surface-muted)` bg, same border/shadow, stroke icon `var(--text-muted)`.
  - Empty grid slot at position 10 (left of 0).
  - All keys honor `prefers-reduced-motion: reduce`.
- "Esqueci meu PIN" link: centered below pad, 12px/800 uppercase tracking 0.5 sky-dark.

---

## 16. Tailwind v4 authoring rules

This project uses **Tailwind v4** (CSS-first config, no `tailwind.config.js`).

### Token authoring

```css
/* tokens live in :root — never in @theme */
:root {
  --primary: #58CC02;
}

/* expose to Tailwind utilities in @theme inline */
@theme inline {
  --color-primary: var(--primary);
}
/* now bg-primary, text-primary, border-primary all work */
```

**Rule:** design tokens → `:root` in `theme.css`. Tailwind utility mapping → `@theme inline` in the same file. Never put raw hex inside `@theme`.

### Adding new utilities

Use `@utility`, not `@layer utilities` with `@apply`:

```css
/* ✓ correct — Tailwind v4 */
@utility shadow-btn-primary {
  box-shadow: 0 4px 0 var(--color-primary-depth);
}

/* ✗ wrong — v4 dropped @apply support in @layer */
@layer utilities {
  .shadow-btn-primary { @apply shadow-md; }
}
```

### Adding new animations

```css
/* put @keyframes in @layer base, expose class in @layer utilities */
@layer base {
  @keyframes myAnim {
    from { opacity: 0; }
    to   { opacity: 1; }
  }
}
@layer utilities {
  .animate-my-anim {
    animation: myAnim 0.3s var(--ease-spring) both;
  }
}
```

Prefer `anim-*` naming for new spring/motion classes; `animate-*` for one-off keyframe wrappers.

### Arbitrary values

Use CSS var references for dynamic values, not hardcoded strings:

```html
<!-- ✓ -->
<div class="bg-[var(--primary-soft)]">
<div style="width: 73%">               <!-- truly dynamic only -->

<!-- ✗ raw hex in markup -->
<div class="bg-[#DCFCE7]">
```

### Safe areas (iOS)

`viewport-fit=cover` is set in `_head.html.erb`. Reference safe area insets with:
```css
padding-bottom: env(safe-area-inset-bottom, 0px);
```
The bottom nav and fixed CTAs must account for this. Tailwind arbitrary: `pb-[env(safe-area-inset-bottom)]`.

### Icon system

Icons use `Ui::Icon::Component` which wraps HugeIcons SVG glyphs. Pass name as string or symbol:
```erb
<%= render Ui::Icon::Component.new("star", size: 20, color: "var(--star)") %>
```
Never use emoji as icons. Never `<img>` for icons. Stroke weight defaults to 1.5; use `weight: 2` for heavier context.

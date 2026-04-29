# LittleStars Design System

Source of truth for the **LittleStars Duolingo Style** visual language. If a pattern isn't in here, it shouldn't ship. Reference mocks live at the repo root: `littlestars_dashboard_duolingo_style.html`, `littlestars_missions_list_duolingo.html`, `littlestars_new_mission_form_duolingo.html`.

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

Location: `app/components/ui/<name>/`.

| Component | Path | Used by | Props |
|---|---|---|---|
| `Ui::Btn` | `ui/btn/` | everywhere | `variant:`, `size:`, `tone:` (drives `shadow-btn-*`) |
| `Ui::StatCard` | `ui/stat_card/` | parent dashboard, kid wallet | `value:`, `label:`, `icon:`, `tint:` (pastel bg + 2px colored border + 0 4px 0 shadow) |
| `Ui::KidProgressCard` | `ui/kid_progress_card/` | parent dashboard | `kid:`, `awaiting_count:`, `missions_count:` (avatar 3D ring, level pill `N1`, progress bar with inset depth) |
| `Ui::ApprovalRow` | `ui/approval_row/` | parent approvals, dashboard | `kid:`, `title:`, `meta:`, `points:`, `approve_url:`, `reject_url:`, ... (rounded card + icon tile with tint+border + two-button group) |
| `Ui::ActivityRow` | `ui/activity_row/` | dashboard, activity_logs, kid wallet | `log:` or explicit `kid:/description:/timestamp:/amount:/direction:`, `with_divider:` |
| `Ui::FilterChips` | `ui/filter_chips/` | parent approvals, missions list | `items:`, `active:`, `controller:` (3D pills: active = colored fill + colored border + depth shadow; idle = white + hairline border) |
| `Ui::SmileyAvatar` | `ui/smiley_avatar/` | dashboards, approvals | `kid:`, `size:`, `face:` — uses internal `COLOR_MAP` for per-kid fills |
| `Ui::Icon` | `ui/icon/` | everywhere | `name`, `size:`, `color:`, `weight:` |
| `Ui::Empty` | `ui/empty/` | zero-state screens | `icon:`, `title:`, `subtitle:`, `color:` |
| `Ui::TopBar` | `ui/top_bar/` | parent sub-pages | `title:`, `subtitle:`, `back_url:` |
| `Ui::MissionCard` | `ui/mission_card/` | kid missions, dashboards, missions list | `mission:`, `status:`, `variant:` (16px radius, 2px hairline border, 0 4px 0 card shadow, hover lift) |
| `Ui::StreakBadge` | `ui/streak_badge/` | parent dashboard | `streak:`, `size:` (yellow tint + flame + count) |
| `Ui::Toggle` | `ui/toggle/` | settings, mission form | green track 52×30 with white thumb, inset depth shadow |
| `Ui::Flash` | `ui/flash/` | layouts | reads Rails `flash` |
| `Ui::Tokens` | `ui/tokens.rb` (module) | shared metadata | `category_for(key)`, `frequency_for(key)`, `tint_soft`, `tint_fg` |

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

| Animation | Duration | When |
|---|---|---|
| Button press | 0.05s `transform` | `:active` translateY(2px) |
| Card hover lift | 0.1s `transform` | mouse hover |
| Filter pill state | 0.15s `all` | toggle active |
| `slideInCard` | 0.35s cubic-bezier | Card mount |
| `slideInR` | 0.4s cubic-bezier(0.22,1,0.36,1) | Right-in page transitions |
| `popIn` | 0.3s cubic-bezier(0.34,1.56,0.64,1) | Modals, toasts |
| `shake` | 0.4s | Input error |
| `float` | 3s infinite | Hero decorations |
| `popCard` | 0.3s | Card success |

**Stagger rule:** `style="animation-delay: #{index * 0.04}s"`, cap at 5 items.

**Reduced motion:** every component using transforms must include:
```css
@media (prefers-reduced-motion: reduce) {
  .my-class { transition: none; }
}
```

---

## 10. Accessibility

- Icon-only buttons must carry `aria-label`.
- Tab switchers need `role=tablist` on container and `role=tab` with `aria-selected` on buttons (`Ui::FilterChips` does this).
- Focus rings: inputs use `box-shadow: 0 0 0 3px var(--primary-soft)`.
- All interactive nodes must have a non-icon text fallback (sr-only if needed).
- 3D buttons keep `:focus-visible` outline distinct from `:active` press state.

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

- Stat tile → `Ui::StatCard`
- Kid dashboard card → `Ui::KidProgressCard`
- Mission / redemption row with two actions → `Ui::ApprovalRow`
- Ledger / activity entry → `Ui::ActivityRow`
- Segmented pill switcher → `Ui::FilterChips`
- Top page title with back arrow → `Ui::TopBar`
- Empty state → `Ui::Empty`
- Reusable per-kid avatar → `Ui::SmileyAvatar`
- Streak counter → `Ui::StreakBadge`
- On/off setting → `Ui::Toggle`

If the page needs a pattern not in the list, add a row to §6 of this file in the same PR.

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

Reference: `littlestars_profile_select_duolingo.html`.

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

Reference: `littlestars_pin_modal_duolingo.html`.

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

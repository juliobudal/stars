# LittleStars Design System

Source of truth for the **Soft Candy / Berry Pop** visual language. If a pattern isn't in here, it shouldn't ship. The reference mocks live in `Stars/pages/*.html`.

---

## 1. Principles

- **Flat · rounded · playful** — no skeuomorphism, generous radii (`22px+`), soft drop shadows.
- **Mobile-first** — kid shells target `max-w-[430px]`; parent shells expand with sidebar at `lg`.
- **One token system** — every color/font/radius comes from a CSS variable in `design_system.css`. Raw hex is only allowed in that file.
- **Rails Way** — ViewComponents + CSS vars, not inline hex or copy-pasted markup.

---

## 2. Palette — Berry Pop

All tokens defined in `app/assets/stylesheets/design_system.css`. Use the variable, never the hex.

| Token | Hex | Role |
|---|---|---|
| `--bg-deep` / `--bg-mid` | `#F8F5FF` | App background |
| `--bg-soft` | `#F0EAFF` | Subtle surfaces |
| `--surface` | `#ffffff` | Cards |
| `--surface-2` | `#F0EAFF` | Inset / chips |
| `--primary` | `#A78BFA` | Brand · lilac |
| `--primary-2` | `#7C5CD6` | Primary shadow / depth |
| `--primary-soft` | `#EDE9FE` | Primary tint |
| `--primary-glow` | `#C4B5FD` | Primary ring |
| `--star` | `#FFC53D` | Stars / rewards |
| `--star-2` | `#E6A800` | Star depth |
| `--star-soft` | `#FFF4CC` | Star tint |
| `--hairline` | `#E8E0F5` | Borders |
| `--c-peach` / `-soft` | `#F472B6` / `#FCE7F3` | Accent |
| `--c-rose` / `-soft` / `-dark` | `#EC4899` / `#FCE7F3` / `#BE185D` | Accent |
| `--c-mint` / `-soft` / `-dark` | `#34D399` / `#D1FAE5` / `#047857` | Success-adjacent |
| `--c-sky` / `-soft` / `-dark` | `#38BDF8` / `#E0F2FE` / `#0369A1` | Accent |
| `--c-lilac` / `-soft` / `-dark` | `#A78BFA` / `#EDE9FE` / `#6D28D9` | Accent |
| `--c-coral` / `-soft` | `#EC4899` / `#FCE7F3` | Accent |
| `--success` / `--success-2` | `#34D399` / `#059669` | Semantic success |
| `--danger` / `--danger-2` | `#EF4444` / `#BE185D` | Semantic danger |
| `--text` / `--text-muted` / `--text-soft` | `#2B2A3A` / `#6A6878` / `#A09EAE` | Foreground ramp |

**Rule:** all color usage in views goes through a CSS variable. Raw hex is only allowed in `design_system.css`.

---

## 3. Typography

```css
--font-display: 'Fraunces', Georgia, serif;  /* italic 700 */
--font-body:    'Nunito', system-ui, sans-serif;
```

Loaded via Google Fonts in `tailwind/fonts.css`. Tailwind's `--font-sans` also maps to Nunito.

| Role | Class | Size |
|---|---|---|
| H1 | `.h-display` | clamp(28, 5vw, 40) |
| H2 | `.h-display` (size override) | clamp(20, 3vw, 26) |
| Subtitle | `.subtitle` | 17 |
| Body | — (default) | 14–16 |
| Eyebrow | `.eyebrow` | 11 uppercase letter-spaced |

`.h-display` is always italic 700. Don't use Fraunces non-italic.

---

## 4. Spacing & Layout

Spacing scale (`--space-1..8`): `4 / 8 / 12 / 16 / 24 / 32 / 40 / 56`.

Radius: `--r-sm 14` · `--r-md 22` · `--r-lg 32` · `--r-xl 40` · `--r-full 999`.

Shells:
- **Kid shell** — single column, `max-w-[430px]`, sticky bottom nav, `BgShapes` background.
- **Parent shell** — fixed sidebar (≥1024px), off-canvas (<1024px) with mobile header bar. Main column `max-w-[900px]`.

---

## 5. Shadows

```css
--shadow-btn:        0 4px 0 rgba(44, 42, 58, 0.12);
--shadow-btn-hover:  0 6px 0 rgba(44, 42, 58, 0.12);
--shadow-card:       0 2px 0 rgba(44, 42, 58, 0.04), 0 10px 24px rgba(44, 42, 58, 0.06);
--shadow-lift:       0 4px 0 rgba(44, 42, 58, 0.05), 0 18px 36px rgba(44, 42, 58, 0.08);
```

---

## 6. Components

Location: `app/components/ui/<name>/`.

| Component | Path | Used by | Props |
|---|---|---|---|
| `Ui::StatCard` | `ui/stat_card/` | parent dashboard, kid wallet | `value:`, `label:`, `icon:`, `tint:` |
| `Ui::KidProgressCard` | `ui/kid_progress_card/` | parent dashboard | `kid:`, `awaiting_count:`, `missions_count:` |
| `Ui::ApprovalRow` | `ui/approval_row/` | parent approvals | `kid:`, `title:`, `meta:`, `points:`, `points_sign:`, `approve_url:`, `reject_url:`, `kid_chip_text:`, `category_label:`, `approve_label:`, `reject_label:`, `reject_confirm:`, `dom_id:` |
| `Ui::ActivityRow` | `ui/activity_row/` | parent dashboard (and follow-up: activity_logs, kid wallet) | `log:` or explicit `kid:/description:/timestamp:/amount:/direction:`, `with_divider:` |
| `Ui::FilterChips` | `ui/filter_chips/` | parent approvals (and follow-up: global_tasks, kid rewards, kid wallet) | `items:`, `active:`, `controller:` |
| `Ui::SmileyAvatar` | `ui/smiley_avatar/` | dashboards, approvals | `kid:`, `size:`, `face:` |
| `Ui::Icon` | `ui/icon/` | everywhere | `name`, `size:`, `color:`, `weight:` |
| `Ui::Empty` | `ui/empty/` | zero-state screens | `icon:`, `title:`, `subtitle:`, `color:` |
| `Ui::TopBar` | `ui/top_bar/` | parent sub-pages | `title:`, `subtitle:`, `back_url:` |
| `Ui::MissionCard` | `ui/mission_card/` | kid missions, dashboards | `mission:`, `status:`, `variant:` |
| `Ui::Flash` | `ui/flash/` | layouts | reads Rails `flash` |
| `Ui::Tokens` | `ui/tokens.rb` (module) | shared metadata | `category_for(key)`, `frequency_for(key)`, `tint_soft`, `tint_fg` |

**Planned (deferred)** — speced here, built when consumer page lands: `Ui::Toggle`, `Ui::SettingsRow`, `Ui::RewardCard`, `Ui::MissionRow`.

---

## 7. Page Patterns

### Kid shell
- `div.screen.with-nav` wrapped in `layouts/kid.html.erb`
- `max-w-[430px]`, single column, bottom pill nav
- `Ui::BgShapes` renders floating orbs

### Parent shell
- `layouts/parent.html.erb` — body gets `.parent-layout`
- Side nav fixed left at ≥1024px (via `.side-nav` rules in `design_system.css`)
- Off-canvas drawer on mobile with header bar toggle
- Main: `max-w-[900px]`, centered, `padding: var(--space-6) var(--space-7) 120px`

---

## 8. Forms

- `.form-field` wraps each input
- `.form-label` — uppercase 13px with letter-spacing
- `.form-input` / `.form-select` — 16px, 2px border, focus ring `var(--primary-soft)`
- Icon / color pickers: `role=radiogroup` with radio chip cards (see `parent/profiles/_form.html.erb`)

---

## 9. Motion

| Animation | Duration | When |
|---|---|---|
| `slideInCard` | 0.35s cubic-bezier | Card mount |
| `slideInR` | 0.4s cubic-bezier(0.22,1,0.36,1) | Right-in page transitions |
| `popIn` | 0.3s cubic-bezier(0.34,1.56,0.64,1) | Modals, toasts |
| `shake` | 0.4s | Input error |
| `float` | 3s infinite | Hero decorations |
| `popCard` | 0.3s | Card success |

**Stagger rule:** `style="animation-delay: #{index * 0.04}s"`, cap at 5 items.

---

## 10. Accessibility

- Icon-only buttons must carry `aria-label`.
- Tab switchers need `role=tablist` on container and `role=tab` with `aria-selected` on buttons (`Ui::FilterChips` does this).
- Focus rings: inputs use `box-shadow: 0 0 0 4px var(--primary-soft)`.
- All interactive nodes must have a non-icon text fallback (sr-only if needed).

---

## 11. Do / Don't

**✗ Don't**
- Write `style="..."` for anything a utility class or component already covers. Allowed exceptions: dynamic values (`width: 73%`, computed `--kid-color`) and one-off gradients that are not yet componentized.
- Reference raw hex from views — go through CSS vars.
- Mix `bg-brand-green` / Duolingo Tailwind tokens with CSS-var-driven classes. `brand.css` is intentionally empty; don't reintroduce it.
- Duplicate category/frequency metadata across views — use `Ui::Tokens`.

**✓ Do**
- Reach for `Ui::*` first. If no component fits, use `.card` + utility classes.
- If a pattern repeats twice, extract a component in the same PR that needs it.
- Keep kid-facing copy playful, parent-facing copy concise.

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

If the page needs a pattern not in the list, add a row to §6 of this file in the same PR.

# 01 — Layouts & Global Primitives Audit

Date: 2026-04-28
Scope: layouts (`application`, `kid`, `parent`), `app/components/ui/` global primitives, `tailwind/theme.css`, `design_system.css`, `app/assets/stylesheets/components/`.
Reference: `DESIGN.md` (Duolingo Style).

---

## 1. Tokens (raw hex outside `tailwind/theme.css`)

### CRITICAL
- `app/components/ui/smiley_avatar/component.rb:5-16` — entire `COLOR_MAP` hard-codes 11 palette entries with raw hex (e.g. `#EDE9FE`, `#CFFAFE`, `#FCE7F3`, `#6D28D9`, `#0E7490`, `#1D4ED8`, `#047857`, `#0369A1`). Drift from theme palette and includes off-system blues/teals. → Rebuild map from CSS vars (`--c-<palette>-soft / -dark`) or move hex into `theme.css` as `--avatar-*` tokens.

### HIGH
- `app/components/ui/star_value/component.rb:54-56` — `#FFFFFF`, `#F4F4F5`, `#FFD24C`, `#E69400` raw hex for gradients. → Replace with `--surface`, `--surface-2`, `--star`, `--star-2`.
- `app/components/ui/approval_row/component.html.erb:64` — fallback `#FFF4D6`, `#B45309` inside inline `style` (not present in theme). → Drop fallbacks; rely on `--c-amber-soft` / `--c-amber-dark`.
- `app/components/ui/approval_row/component.html.erb:77` — fallback `#F5F5F7` for `--surface-2`. → Drop fallback (token exists).
- `app/components/ui/streak_badge/component.html.erb:1` — fallback `#CC7700` duplicates `--c-streak-2`. → Drop fallback.
- `app/components/ui/pin_modal/component.css:5` — `color: #fff` for avatar; `app/components/ui/pin_modal/component.css:1` overlay `rgba(0,0,0,0.45)` (DESIGN.md §15 specifies `rgba(75,75,75,0.45)`). → Use `--surface-on-primary` and the spec'd overlay color.
- `app/components/ui/confetti/confetti_controller.js:43,49` — JS array of `#58cc02 #1cb0f6 #ffc800 #ff4b4b #ffffff`. → Read from CSS vars via `getComputedStyle(document.documentElement)` or import a generated theme JSON.

### MEDIUM
- `app/components/ui/tooltip/tooltip.css:4` — `--tooltip-bg: var(--color-gray-900)`. `--color-gray-900` is not defined in `theme.css`. → Replace with `--text` (4B4B4B) or define a `--tooltip-bg` token.
- `app/components/ui/btn/btn.css:16-17` — `border-[rgba(26,42,74,0.1)]` and `bg-[rgba(26,42,74,0.04)]` use legacy Berry-Pop ink color (26,42,74). → Use `--hairline` / `--surface-2`.
- `app/components/ui/chip/component.rb:31` — same `rgba(26,42,74,0.1)` ink residue. → Replace with `--hairline`.
- `app/components/ui/tabs/component.rb:22` — inline `shadow-[0_3px_0_rgba(26,42,74,0.06)]` Berry-Pop ink. → Use `--shadow-card` family or `rgba(0,0,0,0.06)`.
- `app/components/ui/card/component.rb:28` — variant `primary` shadow `0 2px 0 rgba(44,42,58,0.04), 0 6px 16px rgba(44,42,58,0.05)` uses retired charcoal `#2C2A3A`. Also a soft blurry shadow (see §3). → Replace with `--shadow-btn-primary` + flat depth.

---

## 2. Typography (Nunito 700/800, no Fraunces/Berry-Pop residue)

### CRITICAL
- `app/views/shared/_head.html.erb:4` — Nunito loaded with weights `400;700;800;900`. DESIGN.md §3 specifies 700/800 only. 400 is loaded but never used and 900 is non-spec. → Trim to `wght@700;800`.

### HIGH
- `app/assets/stylesheets/components/typography.css:1-24` — `.h1..h6` use `font-semibold` (600) — below the spec'd 800. Generic Tailwind weights, not aligned to Duolingo Nunito 800. → Either delete the file (replaced by `Ui::Heading`) or re-emit using `font-extrabold`.
- `app/components/ui/heading/component.rb:5-7` — Sizes diverge from DESIGN.md §3: H1 32px (spec 26px), display 40px (spec missing), H4 15px. → Reconcile to 26/22/18/15.
- `app/components/ui/top_bar/component.html.erb:16` — title hardcoded `text-[26px]` (good) but always renders 26px regardless of having a back arrow; `Ui::Heading` should be reused.

### MEDIUM
- `app/components/ui/badge/component.rb:21,23` & `app/components/ui/chip/component.rb:19,21` — body weights mix `font-bold` (700) with `font-extrabold` (800) inconsistently for same size variants. → Unify per spec table (button/badge labels are 800).
- `app/components/ui/sidebar/sidebar.css:13,16,19` — sidebar links use generic `font-bold`. The actual parent sidebar in `_parent_nav.html.erb:53` hand-rolls `font-extrabold` instead of using `Ui::Sidebar`. → Either align primitive to 800 or delete unused primitive (see §7/§9).

### LOW
- `app/components/ui/modal/modal.css:17`, `drawer/drawer.css:17` — title classes `text-xl font-bold` (spec calls for 22px/800). → Bump to `text-[22px] font-extrabold`.
- No Fraunces / Berry-Pop string residue in scope (good). `BERRY-POP-REMAINING.md` is stale and can be archived (see §9).

---

## 3. Shadows (`0 4px 0` depth on interactive; no soft `0 8px 24px`)

### HIGH
- `app/components/ui/card/component.rb:28` — variant `primary` uses `0 6px 16px rgba(...)` blurry shadow. Violates §5. → Use `--shadow-btn-primary` (0 4px 0 var(--primary-2)).
- `app/components/ui/modal/modal.css:4`, `drawer/drawer.css:4`, `popover/popover.css:4`, `tooltip/tooltip.css:5`, `tabs/tabs.css:14`, `select/component.rb:64`, `form.css:135,139` — all use Tailwind's blurry `shadow-sm`. Spec §5 mandates flat `0 4px 0`. → Replace with `shadow-card` / `shadow-btn-secondary`.

### MEDIUM
- `app/components/ui/pin_modal/component.css:3` — `0 8px 0 rgba(0,0,0,0.12)` is correct per DESIGN.md §15 but radius is `20px` — spec says `24px`. Note the depth here is intentionally taller than the standard `0 4px 0`.
- `app/views/shared/_kid_nav.html.erb:11` — inline `box-shadow: 0 4px 0 rgba(0,0,0,0.08)` is correct depth, but inline (should use `shadow-card` utility).
- `app/views/shared/_parent_nav.html.erb:99` — mobile bottom nav has only `border-t` and `backdrop-blur-lg`; no depth shadow. Inconsistent with kid bottom nav. → Add a top-edge depth or shadow.

### LOW
- `Ui::Btn` hover applies `-translate-y-1` (4px) but DESIGN.md §13 specifies `translateY(-1px)` (optional); 4px is too much for press recovery rhythm. Active uses `translate-y-1` (4px) — spec says 2px. → Halve magnitudes.

---

## 4. Radii (10–16px range; modals 20px; avatars/pills 999)

### MEDIUM
- `app/components/ui/pin_modal/component.css:3` — modal radius 20px; DESIGN.md §15 explicitly mandates **24px** (modal exception). → Bump to 24px.
- `app/components/ui/modal/modal.css:27,31-33` — uses `--radius-modal` derived as `var(--r-sm) * 3 = 30px`. DESIGN.md §4 caps modal radius at 20px (and pin modal exception 24px). 30px violates "no soft 22–32px". → Set `--radius-modal: 20px`.
- `app/components/ui/dropdown/dropdown.css:9`, `popover/popover.css:5` — `--radius-dropdown = --r-sm * 1.5 = 15px` — within range but not aligned to scale. → Use `--r-lg` (14) or `--r-xl` (16).

### LOW
- `app/components/ui/list/component.css` — list rows have no radius; OK structurally but inconsistency with cards.

---

## 5. Buttons (press = `translateY(2px); box-shadow: none`; consistent variants)

### HIGH
- `app/components/ui/btn/btn.css:8-29` — uses `active:translate-y-1` (4px) and `active:` shadow utilities, not `box-shadow: none`. Spec §5 mandates `translateY(2px); box-shadow: none !important`. → Rewrite active state.
- `app/components/ui/btn/component.rb:2` — declared variants: `primary, secondary, ghost, danger, success, star`. Missing `outline` (used by `turbo_confirm/component.html.erb:8`) — runtime error or no-op. → Add `outline` or fix consumer.
- `app/components/ui/turbo_confirm/component.html.erb:1` — uses non-existent helpers `helpers.ui.modal`, `helpers.ui.btn` (snake-cased helper API). Confirm whether `Ui::Helpers` is wired; if not, this confirm dialog is broken. → Audit `helpers/ui/*` mapping.

### MEDIUM
- Inline button markup duplicated across views (`ls-btn-3d` class strings ~30+ files outside scope) — `Ui::Btn` is bypassed. Layouts/nav use `ls-btn-3d` via inline styles in `_kid_nav.html.erb` rather than `Ui::Btn`. → Migrate nav items to `Ui::Btn` w/ `variant: ghost/primary`.
- `app/components/ui/btn/btn.css:16` — ghost variant has no depth shadow at all (`shadow-none`). DESIGN.md state matrix has no row for ghost; either document or align.

### LOW
- `Ui::Btn` lacks `tone:` prop (DESIGN.md §6 declares `variant/size/tone`). Currently variant doubles as tone. → Either add `tone:` or update spec.

---

## 6. Layout structure (kid `max-w-[430px]`; parent expands w/ sidebar at `lg`)

### CRITICAL
- `app/views/layouts/kid.html.erb:12` — `<main>` uses `max-w-screen-md mx-auto` (768px). DESIGN.md §4 mandates `max-w-[430px]` mobile-first. → Change to `max-w-[430px]`.
- `app/views/layouts/application.html.erb:9` — body forces `data-palette="sky"`. Used by entry/profile-select screens, but overrides per-kid palette anywhere this layout renders. Should be neutral (no `data-palette` = green default). → Remove or set to default green.

### HIGH
- `app/views/layouts/parent.html.erb:14` — main column `max-w-[500px]` mobile / `lg:max-w-none`. DESIGN.md §4 says parent main is `max-w-[900px]` centered with `padding: var(--space-6) var(--space-7) 120px`. → Set `max-w-[900px]` and structured padding.
- `app/views/layouts/parent.html.erb:9` — body uses `lg:pl-[220px]` directly (sidebar offset). DESIGN.md §4 token `--width-sidebar` is defined but not used. → `lg:pl-sidebar` via Tailwind.
- `app/views/layouts/kid.html.erb:11` — `data-controller="fx"` mounted on `<body>`. OK but `application.html.erb` doesn't have it; entry screens lose celebration FX.

### MEDIUM
- `app/views/layouts/kid.html.erb` has no `BgShapes` render even though DESIGN.md §7 says kid shell renders `Ui::BgShapes`. (`fx_stage` is rendered, but `BgShapes` is the floating-orbs background.) → Add `<%= render Ui::BgShapes::Component.new %>`.
- `app/views/layouts/parent.html.erb` lacks `<main>` semantic tag; uses generic `<div>`.
- `app/views/layouts/application.html.erb:9` — `app-shell` class forces `100vh` overflow hidden — fine for entry but breaks if reused.

### LOW
- `application.html.erb` and `kid/parent` layouts repeat `<head>`/`yield :head` — extract once.
- `application.html.erb` has no `<html lang="pt-BR">`. → Add `lang="pt-BR"`.

---

## 7. Component reuse (duplicated markup vs. existing primitives)

### HIGH
- `app/views/shared/_kid_nav.html.erb:9-32` — entire kid bottom nav is hand-rolled (inline `style=`, `ls-btn-3d` strings). Should be a `Ui::Navbar` variant or new `Ui::BottomNav`. Also duplicates structure already in `Ui::Navbar`/`Ui::Sidebar`.
- `app/views/shared/_parent_nav.html.erb:23-90` & `99-120` — both desktop sidebar AND mobile bottom nav are hand-rolled with inline `style=` (e.g. lines 27, 59, 69). `Ui::Sidebar` and `Ui::Navbar` exist but are unused here. → Either consume them or delete the unused primitives.
- `app/views/shared/_parent_nav.html.erb:1-4` — pending count query lives inline in a partial (mixes business logic in views). → Move to a helper / decorator.
- `Ui::Card` (`component.rb:22`) — base classes encode Duolingo correctly, but inline `ls-card-3d` strings appear ~40 places in views. → Consumers should pass through `Ui::Card`.

### MEDIUM
- `app/components/ui/heading/component.rb` exists but `Ui::TopBar` re-implements heading inline (`top_bar/component.html.erb:16`). → Use `Ui::Heading`.
- `app/components/ui/select/component.rb:64` & `select/component.html.erb` — custom select coexists with `form.css` and `Ui::Toggle`; no consistent form primitive surface. → Document selection API.
- `app/components/ui/profile_picker/component.html.erb:14-18` overlap with `Ui::ProfileCard`. Two components for the same job? → Consolidate or document split.
- `Ui::Flash::Component` reads `flash` directly but layouts render it explicitly; ensure no double-render.

### LOW
- `Ui::Group` (`group.css`) references `.btn-default`, `.btn-secondary`, `.btn-outline` — these classes don't exist (Btn uses `.ui-btn--*`). Component is dead-on-arrival. → Update selectors to `.ui-btn--*` or delete.

---

## 8. Accessibility (aria, focus, semantic HTML)

### HIGH
- `app/views/layouts/kid.html.erb`, `parent.html.erb`, `application.html.erb` — no `<html lang>` attribute. PT-BR app.
- `app/views/shared/_parent_nav.html.erb:99` — mobile bottom `<div>` is a navigation region but not wrapped in `<nav aria-label>`. → Wrap in `<nav>`.
- `app/views/shared/_parent_nav.html.erb:14` — `id="sidebar-toggle"` duplicated as `class` and `id`; `<button>` lacks `aria-expanded` / `aria-controls="parent-sidebar"`.
- `app/views/shared/_kid_nav.html.erb:25-31` — "Sair" `button_to` has no `aria-label`; relies on text label only (OK), but icon-only logout in compact view may regress.
- `app/components/ui/btn/btn.css:8-29` — no `:focus-visible` styling; DESIGN.md §10 requires distinct focus ring on 3D buttons. → Add `focus-visible:ring`.

### MEDIUM
- `app/components/ui/select/component.html.erb:17-23` — visual trigger button has `aria-haspopup="listbox"` but the listbox panel uses `tabindex="-1"` and individual options lack `aria-activedescendant` wiring on the trigger. Verify keyboard focus loop.
- `app/components/ui/toggle/component.html.erb:10` — non-form variant uses `role="switch"` but no `tabindex`/keyboard handler. Read-only? Document.
- `app/components/ui/spinner/component.rb` — no `role="status"` or `aria-label="Carregando"`.
- `app/components/ui/flash/component.html.erb:4` — toast container lacks `role="status"` / `aria-live="polite"`.
- `app/components/ui/empty/component.rb:13-14` — `<h3>` is hardcoded; if empty appears in nested context it can break heading hierarchy.

### LOW
- `app/views/shared/_parent_nav.html.erb:93-95` — backdrop `<div>` is interactive (click closes drawer) but is a `<div>` without `role="button"` / `aria-label`.
- `app/components/ui/sidebar/sidebar.css` — sidebar links are `<a>` only; no `aria-current` styling.

---

## 9. Dead code / Berry-Pop residue

### HIGH
- `app/components/ui/group/group.css` — references nonexistent `.btn-default/.btn-outline/.btn-secondary` (see §7). Either dead or broken.
- `app/components/ui/turbo_confirm/component.html.erb` — references `helpers.ui.modal` API that may not exist; verify or remove.
- `.planning/BERRY-POP-REMAINING.md` — stale (mentions `--primary` lilac `#A78BFA`, Fraunces) and should be archived; current palette is Duolingo green.

### MEDIUM
- `app/assets/stylesheets/components/typography.css` — `.h1..h6` Tailwind generic; superseded by `Ui::Heading`. Dead. → Delete.
- `app/assets/stylesheets/components/redeem_modal.css:1` — comment says "Legacy redeem-modal kept only for any non-kid usages." Verify, then delete top section.
- `app/assets/stylesheets/components/form.css` — entire file is generic shadcn-style form classes (`.form__field`, `.form__toggler`) but DESIGN.md §8 specifies `.form-field` / `.form-label` / `.form-input` (single-dash). Likely unused; the actual form styling is inline in `_form.html.erb` views. → Audit usage and delete.
- `app/assets/stylesheets/components/body.css` — defines `.body` shell w/ `min-h-svh px-3 md:px-6`. Layouts don't reference `.body` class. Dead.
- `app/components/ui/avatar` directory exists alongside `kid_avatar`, `smiley_avatar`, `profile_card` — overlap. Audit which is canonical (DESIGN.md §6 lists `Ui::SmileyAvatar`).
- `app/components/ui/list`, `Ui::Table`, `Ui::Stepper`, `Ui::Tooltip`, `Ui::Popover`, `Ui::Dropdown`, `Ui::Pagy`, `Ui::Breadcrumbs`, `Ui::Sidebar`, `Ui::Navbar`, `Ui::Header`, `Ui::Accordion`, `Ui::Drawer` — none referenced from `app/views/` or layouts (grep returned 4 hits, all `Ui::Card`/`Ui::Modal`). These primitives exist but are not consumed; either ship usages or remove from the design surface.

### LOW
- `app/components/ui/timeline/component.yml:18` — sample fixture `Order #1234` (English copy in PT-BR app). Cosmetic.
- `app/components/ui/clipboard`, `celebration`, `confetti` — verify still used (confetti is, via `fx_controller`).

---

## Top 10 fixes — prioritized punch list

1. **Kid layout main width** — `app/views/layouts/kid.html.erb:12` `max-w-screen-md` → `max-w-[430px]` (DESIGN.md §4). Single highest visual impact.
2. **Parent layout main width** — `app/views/layouts/parent.html.erb:14` `max-w-[500px] lg:max-w-none` → `max-w-[900px]` centered with `--space-6/7` padding.
3. **`smiley_avatar` palette hex** — `app/components/ui/smiley_avatar/component.rb:5-16` — replace 11-entry COLOR_MAP with theme tokens (or add `--avatar-*` tokens to `theme.css`).
4. **Drop blurry `shadow-sm`** in modal/drawer/popover/tooltip/tabs/select/form CSS — replace with flat `shadow-card` / `shadow-btn-secondary` (§3 list).
5. **Button press contract** — `app/components/ui/btn/btn.css:8-29` rewrite `active:` to `translateY(2px) + box-shadow:none` (DESIGN.md §5/§13). Add `:focus-visible` ring.
6. **Card primary variant shadow** — `app/components/ui/card/component.rb:28` replace `0 6px 16px rgba(44,42,58,0.05)` (Berry-Pop ink + soft) with `shadow-btn-primary`.
7. **Sidebar/navbar inline duplication** — migrate `_kid_nav.html.erb` and `_parent_nav.html.erb` to consume `Ui::Sidebar` / `Ui::Navbar` (or delete unused primitives — see §9). Move `pending_count` query out of partial.
8. **Nunito weight loadout** — `_head.html.erb:4` trim to `wght@700;800` and add `<html lang="pt-BR">` to all 3 layouts.
9. **Modal radii** — `--radius-modal` 30px → 20px (theme.css), and `pin_modal/component.css` 20px → 24px (DESIGN.md §15 spec).
10. **Dead code sweep** — delete `components/typography.css`, `body.css`, `form.css` (verified unused) + `components/ui/group/group.css` (broken selectors); archive `.planning/BERRY-POP-REMAINING.md`.

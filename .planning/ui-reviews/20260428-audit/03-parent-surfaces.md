# Parent Surfaces UI Audit — 2026-04-28

Scope: `app/views/parent/**`, `app/views/layouts/parent.html.erb`, `app/views/shared/_parent_nav.html.erb`, parent-relevant `app/components/ui/*` (approval_row, category_row, category_tabs, profile_card, stat, stat_card, stat_metric, table, filter_chips, color_picker, color_swatch_picker, icon_picker, icon_tile, timeline, logo_mark, bg_shapes, clipboard, top_bar).

Severity: CRITICAL · HIGH · MEDIUM · LOW.

---

## 1. Tokens — raw hex / retired tokens

- HIGH · `app/components/ui/approval_row/component.html.erb:64` — fallback hex `#FFF4D6`/`#B45309` inside `var(--accent-soft, …)` for "Sugerida pela criança" badge. Replace fallback with existing tokens (`var(--star-soft)` / `var(--c-amber-dark)`) and drop hex.
- MEDIUM · `app/components/ui/approval_row/component.html.erb:77` — `var(--surface-2, #F5F5F7)` fallback hex for submission comment background. Drop hex; `--surface-2` is always defined.
- LOW · `app/views/parent/categories/_form.html.erb:5`, `app/views/parent/global_tasks/_form.html.erb:24`, `app/views/parent/profiles/_form.html.erb:4`, `app/views/parent/rewards/_form.html.erb:4` — error panels all use `var(--c-rose-soft)` directly; fine, but they duplicate the same block four times (see §7). Extract `Ui::FormErrors` or partial.
- INFO · "lilac" references in `views/parent/{categories,activity_logs,profiles}` and `Ui::StatCard`/`Ui::ProfileCard` are valid Duolingo accent (`--c-lilac` lives in `theme.css`); not Berry-Pop residue.

## 2. Typography — Nunito 700/800 / no Fraunces

- PASS · No `Fraunces`/`Inter` references in parent surfaces.
- LOW · `views/parent/dashboard/index.html.erb:51,83` and `views/parent/invitations/new.html.erb:14,16` use ad-hoc weights/sizes (`font-bold` body, h2 at `[16px]`) outside the canonical scale — DESIGN.md §3 calls H2 22px/800.
- LOW · `views/parent/dashboard/index.html.erb:27` and `activity_logs/index.html.erb:23,24,40` use 9–11px tracking labels — fine, but inconsistent (some pages use `text-[10px]`, some `[11px]`, some `[9px]`).

## 3. Shadows — `0 4px 0` depth

- PASS · Cards/buttons throughout parent surfaces use `0 3px 0`/`0 4px 0` consistently. No blurry `shadow-md/lg/xl` usage found.
- LOW · Mixed depth values: `0 3px 0` vs `0 4px 0` for card-shadow used inconsistently (e.g. dashboard streak chip `0 3px 0`, "Nova missão" button `0 4px 0`). DESIGN §5 says cards = `0 4px 0 rgba(0,0,0,0.08)`; buttons = `0 4px 0 var(--*-2)`. Filter pills 3px is correct.
- LOW · `views/parent/profiles/_form.html.erb:74` — uses `var(--c-<col>-dark, var(--c-<col>))` fallback chain in inline style; works but obscures intent.

## 4. Radii — 10–16px only

- PASS · No radii > 20px observed; modals not in scope.
- LOW · Sidebar nav items use `rounded-[14px]` (`shared/_parent_nav.html.erb:53`) and active state changes color, not thickness — matches §13. Mobile bottom nav pill is `rounded-[12px]` (good).

## 5. Layout — sidebar / dashboard grid / forms

- HIGH · `app/views/layouts/parent.html.erb:14` — main column is `max-w-[500px]` on mobile and **`lg:max-w-none`** at lg, contradicting DESIGN §4 which states main = **`max-w-[900px]`** centered. Currently parent pages stretch full width on desktop and look unbounded.
- MEDIUM · Forms use ad-hoc `max-w-[720px]` (categories, global_tasks, rewards forms) while `invitations/new.html.erb` uses `max-w-[480px]` via `Ui::Card`. No shared form container width.
- LOW · `views/parent/profiles/index.html.erb:25` uses `lg:grid-cols-2` for kid cards; `views/parent/dashboard/index.html.erb:60` uses `lg:grid-cols-1`. Inconsistent.

## 6. Page-structure consistency

- HIGH · No shared "page header" component. Every parent page hand-rolls the title+subtitle+CTA flex block (`dashboard:4-38`, `approvals:5-28`, `categories/index:4-19`, `rewards/index:4-19`, `profiles/index:5-22`, `global_tasks/index:21-34`, `activity_logs:9-28`, `settings/show:5-14`). 8 near-identical implementations.
- HIGH · Inconsistent back-arrow header: `categories/{new,edit}`, `rewards/{new,edit}`, `profiles/{new,edit}` hand-roll an arrow+title; `global_tasks/{new,edit}` use `Ui::TopBar::Component`. Two patterns for the same job. Standardize on `Ui::TopBar`.
- HIGH · `views/parent/invitations/new.html.erb` uses an entirely different look (`Ui::Card`, `Ui::Heading`, raw `block font-bold mb-1.5` labels) — does not match the form pattern used by categories/rewards/profiles. Looks orphaned.
- MEDIUM · Top-right "stat chip" pattern duplicated in `dashboard/index.erb:21-30` (streak), `approvals/index.erb:18-27` (pending), `activity_logs/index.erb:18-27` (events). Same markup, three copies. Extract `Ui::HeaderStatChip`.
- LOW · `screen-enter` vs `screen-enter-right` chosen arbitrarily (e.g. dashboard uses `enter`, approvals uses `enter-right`). No documented rule.
- LOW · `with-nav` missing on `profiles/{new,edit}.html.erb:1` while every other parent page sets it.

## 7. Component reuse / duplicated markup

- HIGH · "Primary CTA button" inline-styled `ls-btn-3d` markup duplicated 8+ times across parent index pages (dashboard, categories, rewards, profiles, global_tasks, settings — see grep: 36 inline button-styled spans vs 6 `Ui::Btn` calls). Should funnel through `Ui::Btn::Component` with `variant: "primary"`.
- HIGH · "Secondary cancel/back" inline-styled link duplicated in `categories/_form:62`, `rewards/_form:89`, `global_tasks/_form:224`, `profiles/_form:108`, `categories/new+edit`, `rewards/new+edit` etc. Use `Ui::Btn variant: "secondary"`.
- HIGH · Form-error panel duplicated 4× (categories, rewards, global_tasks, profiles forms). Extract `Ui::FormErrors` partial.
- HIGH · Form section-card wrapper (`bg-surface rounded-[16px] border-2 border-hairline p-[18px]` + `box-shadow: var(--shadow-card)`) duplicated 14+ times across form partials. Extract `Ui::FormSection` slot component.
- MEDIUM · `dashboard/index.erb:42-45` uses `Ui::StatCard`. Good. But streak chip inline at `dashboard:21-30` is the same shape as `Ui::StatCard` with tint "reward" — should be unified.
- MEDIUM · `Ui::Stat` exists (`components/ui/stat`) but only `Ui::StatCard` is used in parent. Possible dead/duplicate component. Audit which is canonical.
- MEDIUM · `Ui::Table` and `Ui::Timeline` components exist but no parent view uses them. Either dead code or activity_logs/extract should adopt them.
- LOW · `Ui::ColorPicker` (used elsewhere) and `Ui::ColorSwatchPicker` (used by categories form) coexist; `profiles/_form` re-implements color radio grid inline (lines 69-83) instead of either. Three implementations of the same picker.

## 8. Tables vs cards (list-view consistency)

- MEDIUM · Activity log uses bespoke "day-grouped card with rows" pattern (`activity_logs/index.erb:62-110`) — could be `Ui::Timeline`. No shared list/table primitive in use.
- LOW · No real "tables on desktop" pattern — everything is card grids. Consistent, but loses density at lg width.

## 9. Forms

- HIGH · `form-input` class promised by DESIGN §8 is used on some inputs (categories, rewards) but **not** on `global_tasks/_form` (line 43 uses ad-hoc tailwind classes), `profiles/_form` (line 42), `settings/_responsibles_card` (no input), `settings/_rules_card:32` (raw `<input type="number">` with inline classes), `settings/show:58` (PIN reset input ad-hoc). Three different input stylings.
- HIGH · `form-label` class never used. All labels reimplement `block text-[12px] font-extrabold uppercase tracking-[0.5px]` inline (8+ occurrences). Use the shared class from DESIGN §8.
- MEDIUM · Validation/error states differ per form (see §1, §7).
- MEDIUM · Settings rules toggle uses `Ui::Toggle` ✓, but week-start radio (`settings/_family_card:50-62`) reinvents pill-toggle inline; could be `Ui::FilterChips` or new `Ui::SegmentedControl`.
- LOW · `invitations/new.html.erb:14` label uses raw `font-bold` (700) where DESIGN §8 specifies 800 uppercase eyebrows.

## 10. Approval flows

- PASS · `Ui::ApprovalRow` reused in both `dashboard/index.erb` and `approvals/index.erb`. Compact vs full variants supported.
- PASS · `turbo_confirm` used on reject button via component, on category delete, profile delete, mission delete.
- LOW · Some approval/redemption confirms have copy variations ("Rejeitar este pedido…", "Rejeitar esta missão?") — fine but consider centralizing copy.

## 11. Accessibility

- MEDIUM · `settings/_responsibles_card:17-21` "Editar responsável" button has `aria-label` but no actual handler/href — dead/decorative button presented as interactive.
- MEDIUM · Color radios (`profiles/_form:69-83`, `color_swatch_picker`, `color_picker`) rely on color alone to convey selection on touch — `peer-checked` adds scale + check icon but check is `opacity-0` until checked; OK. But `color_swatch_picker` has no visible check, only `peer-checked:border-foreground` — borderline contrast on light tints.
- MEDIUM · `dashboard/index.erb:31-37` and others — primary CTA links use `ls-btn-3d` without `:focus-visible` outline beyond browser default; DESIGN §10 mandates distinct focus ring.
- LOW · `filter_chips` correctly uses `role="tablist"` / `aria-selected` ✓.
- LOW · `parent_nav` mobile bottom nav badge is a span with no aria-label ("3 pendências aguardando").

## 12. Dead / retired code

- LOW · `Ui::Stat` (component dir with value/label/icon/description sub-components) appears unused in parent surfaces; `Ui::StatCard` is the actual one in use. Confirm `Ui::Stat` isn't shipped elsewhere then remove.
- LOW · `Ui::Table`, `Ui::Timeline`, `Ui::ColorPicker` — exist but unused in parent surfaces audited. Verify usage in kid surfaces or remove.
- LOW · `views/shared/_parent_nav.html.erb:7,22` — duplicate `<%# Mobile sticky header %>` and `<%# Sidebar %>` comments.
- LOW · `parent_nav.erb:14` button has `id="sidebar-toggle"` but Stimulus controller targets via `data-action` — id is unused.

---

## Top 10 fixes prioritized

1. **HIGH §5** — Fix `layouts/parent.html.erb` main column: cap at `lg:max-w-[900px]` per DESIGN §4 (currently `lg:max-w-none`).
2. **HIGH §6** — Extract `Ui::PageHeader` component (title + subtitle + right slot) and replace 8 hand-rolled headers across dashboard/approvals/categories/rewards/profiles/global_tasks/activity_logs/settings.
3. **HIGH §6** — Standardize back-arrow sub-page header on `Ui::TopBar::Component`; convert `categories/{new,edit}`, `rewards/{new,edit}`, `profiles/{new,edit}` (currently hand-rolled).
4. **HIGH §7/§9** — Extract `Ui::FormSection` (16px white card + hairline + shadow + uppercase label slot) and replace ~14 inline form-section blocks across all 4 form partials.
5. **HIGH §7** — Extract `Ui::FormErrors` partial; remove 4 duplicated rose-tinted error panels.
6. **HIGH §7** — Funnel all primary/secondary CTAs through `Ui::Btn::Component`; remove ~30 inline `ls-btn-3d` blocks.
7. **HIGH §9** — Apply `form-input`/`form-label` classes (DESIGN §8) to every input/label in parent forms; eliminate 3 input stylings (global_tasks, profiles, settings).
8. **HIGH §6** — Rewrite `parent/invitations/new.html.erb` to match the shared form/page-header pattern (drop `Ui::Card` + `Ui::Heading` mismatch).
9. **HIGH §1** — Drop hex fallbacks `#FFF4D6`, `#B45309`, `#F5F5F7` in `Ui::ApprovalRow` (lines 64, 77).
10. **MEDIUM §7** — Extract `Ui::HeaderStatChip` for streak/pending/events corner stats (3 copies) and unify with `Ui::StatCard` styling rules.

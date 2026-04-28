# Kid Surfaces UI Audit — 2026-04-28

Scope: `app/views/kid/**`, kid-specific `app/components/ui/*`, `app/views/layouts/kid.html.erb` (context).
Reference: `DESIGN.md` (Duolingo style — Nunito 700/800, `0 4px 0` shadows, 10–16px radii, CSS-var-only colors).

Severity legend: CRITICAL · HIGH · MEDIUM · LOW.

---

## 1. Tokens — raw hex / retired colors

- LOW · `app/components/ui/smiley_avatar/component.rb:5-16` — entire `COLOR_MAP` hard-codes raw hex (`#EDE9FE`, `#FCE7F3`, `#1D4ED8`, `#0E7490`, etc.) for fill/tile/ring/ink. DESIGN.md §2 forbids raw hex outside `theme.css`. → Fix: move palette into CSS vars (or read from theme tokens via Ruby).
- LOW · `app/components/ui/confetti/confetti_controller.js:43,49` — raw brand hex (`#58cc02`, `#1cb0f6`, `#ffc800`, `#ff4b4b`, `#ffffff`) inline. → Fix: read from CSS custom properties via `getComputedStyle(document.documentElement)`.
- LOW · `app/components/ui/streak_badge/component.html.erb:1` — fallback hex `#CC7700` literal in `box-shadow`. → Fix: drop fallback, var is always defined in `theme.css`.
- LOW · `app/components/ui/mission_card/component.rb:38` — raw `rgba(26,42,74,0.08)` hardcoded shadow color (legacy "Berry Pop"–era ink). → Fix: use `var(--shadow-card)` or `rgba(0,0,0,0.08)` per DESIGN.md §5.
- INFO · No Fraunces, no `#a3a` lilac, no "Berry Pop" tokens found. ✓

## 2. Typography — Nunito + 700/800

- INFO · No Fraunces references in scope. All headings use `font-display` + `font-extrabold` correctly.
- LOW · `app/views/kid/missions/new.html.erb:25,33,44,54` — labels/inputs use generic `font-medium`/`font-bold`; DESIGN.md §3 mandates 700 minimum, 800 for inputs/buttons. Some `text-area`s drop to 14px medium — should be 700.
- LOW · `app/components/ui/activity_row/component.html.erb:6,10` — body `text-[13px] font-bold` and `text-[11px]` mixed with description; consistent but `text-xs` (11px) is the documented caption size — already correct, kept for note.
- LOW · `app/components/ui/redemption_row/component.html.erb:6` — `text-[16px]` instead of canonical `text-lg` (18px) for card title per DESIGN.md table.

## 3. Shadows — `0 4px 0` 3D depth

- HIGH · `app/views/kid/dashboard/index.html.erb:39` — "Trocar" button uses `box-shadow: 0 3px 0` (should be `0 4px 0` per DESIGN.md §5 button contract). Same `0 3px 0` recurs at lines 18, 25, 121, 168, 184(? no, 184 is `0 4px 0`), 204, 213, 267 (most are 2/3px chips, acceptable for tiny chips, but the "Trocar" and "Fiz!" buttons should be 4px).
- HIGH · `app/views/kid/dashboard/index.html.erb:213` — "Fiz!" button uses `box-shadow: 0 3px 0` instead of `0 4px 0`.
- HIGH · `app/views/kid/missions/new.html.erb:60,63` — submit + cancel use `0 3px 0` and `0 4px 0` inconsistently; primary action should be 4px depth via `Ui::Btn` not inline.
- MEDIUM · `app/views/kid/rewards/index.html.erb:101,119` — "Posso resgatar" cards use `0 5px 0` (over-deep) and inner CTA `0 3px 0`. DESIGN.md cards = `0 4px 0`.
- MEDIUM · `app/components/ui/history_row/component.html.erb:1` — uses `shadow-card` utility but combined with `border` (single px) instead of 2px hairline border per DESIGN.md §11.
- LOW · `app/components/ui/redemption_row/component.html.erb:1` — uses `var(--shadow-card)` but no 2px border; also `rounded-2xl` (~16px) ok.

## 4. Radii — 10–16px

- MEDIUM · `app/components/ui/pin_modal/component.css:3` — `.pin-card` uses `border-radius: 20px`. DESIGN.md §15 specifies 24px modal radius. CSS comment cap is 20 OK as "modal exception" allowed.
- MEDIUM · `app/components/ui/redemption_row/component.html.erb:1,2` — `rounded-2xl` (16px) on card OK, but inner icon tile `rounded-2xl` (16px) for a 48×48 tile; DESIGN.md §4 says small tiles 10–12px.
- LOW · `app/components/ui/history_row/component.html.erb:1` — `rounded-md` (= 6px from Tailwind default unless overridden) — likely below 10px floor. → Verify: should be `rounded-[12px]` or `rounded-[14px]`.
- LOW · `app/components/ui/history_row/component.html.erb:3` — disc `rounded-full` 40×40 OK. Surrounding card too narrow radius.
- LOW · `app/components/ui/kid_placeholder_card/component.html.erb:2` — `rounded-md` again, likely too small.

## 5. Layout — `max-w-[430px]` mobile-first kid shell

- CRITICAL · `app/views/layouts/kid.html.erb:12` — `<main class="... max-w-screen-md mx-auto pb-24 md:pb-10">` uses `max-w-screen-md` (768px) **not** the documented `max-w-[430px]`. DESIGN.md §4/§7 explicitly: kid shell = single column 430px wide. This is a foundational violation that lets every kid page sprawl on tablets.
- HIGH · `app/views/kid/missions/new.html.erb:2` — uses `max-w-[480px]` instead of 430px shell width. Inconsistent with DESIGN.md.
- MEDIUM · `app/views/kid/dashboard/index.html.erb:10` — wraps everything in `.screen.with-nav` (good) but layout already supplies p-6 padding, double padding likely.
- LOW · `app/views/kid/wallet/index.html.erb:17` — `grid-cols-1 sm:grid-cols-3` for week summary; on `max-w-[430px]` the 3-col will compress. Acceptable but verify.

## 6. Page structure consistency

- HIGH · Kid pages do **not** share a common header pattern. Dashboard hand-rolls streak/stars/switch chips inline (`index.html.erb:14-44`); rewards uses a custom `arrow-left + shop icon + balance card` row (`rewards/index.html.erb:10-60`); wallet uses `Ui::TopBar` (correct). Three different headers across three pages.
- HIGH · Balance is rendered three different ways: dashboard inline chip with count-up (`index.html.erb:24-34`), rewards balance hero card (`rewards/index.html.erb:31-50`), wallet via `StatMetric` (`wallet/index.html.erb:18`). `Ui::BalanceChip` exists but isn't used in any kid view.
- MEDIUM · Empty states: wallet uses `Ui::Empty` correctly; dashboard uses `Ui::Empty` correctly; rewards uses `Ui::Empty` correctly. ✓
- MEDIUM · `app/views/kid/missions/new.html.erb` has no header at all — no back arrow, no `Ui::TopBar`. Kid lands on a bare form.

## 7. Component reuse — duplicated markup

- CRITICAL · `app/views/kid/dashboard/index.html.erb:135-148` (completed) and `:154-173` (awaiting) and `_awaiting_row.html.erb` (awaiting again) duplicate the **same** "primary-soft / 2px primary border / check icon / star pill" card three times. Should collapse into one `Ui::MissionCard` "approved" / "waiting" variant.
- HIGH · `_awaiting_task.html.erb` (wallet panel) is a **fourth** waiting-task card markup with different colors (star tint instead of primary). Two divergent visual treatments for the same domain state.
- HIGH · `_completed_task.html.erb` is a **fifth** card style (40×40 icon) used nowhere visible — likely dead. → Verify references.
- HIGH · `app/views/kid/dashboard/index.html.erb:209-215` — inline `<button>` with hand-coded `ls-btn-3d` styling. Should be `Ui::Btn::Component`.
- HIGH · `app/views/kid/dashboard/index.html.erb:36-43` — "Trocar" submit hand-coded; should be `Ui::Btn::Component variant: "secondary"`.
- HIGH · `app/views/kid/rewards/index.html.erb:11-16` — back link hand-coded as 38×38 chip; should be `Ui::TopBar` or shared back-button component.
- HIGH · `app/views/kid/rewards/index.html.erb:53-59` — "Histórico" link hand-coded; should be `Ui::Btn` ghost variant.
- MEDIUM · `app/views/kid/missions/new.html.erb:60-63` — Cancelar/Submit hand-coded (full inline `style=`) instead of `Ui::Btn`.
- MEDIUM · `app/views/kid/rewards/index.html.erb:99-126` (affordable card) and `:149-179` (locked card) — large duplicated markup; extract `Ui::RewardCatalogCardKid` (kid-facing). Existing `Ui::RewardCatalogCard` is parent-only.
- MEDIUM · `app/views/kid/rewards/index.html.erb:65-82` — uses `cat-tabs` raw class instead of `Ui::FilterChips` / `Ui::CategoryTabs` (wallet uses `Ui::CategoryTabs` correctly).

## 8. Stars/points rendering

- HIGH · Dashboard star chips at `index.html.erb:24-33`, `:121-126`, `:167-172`, `:202-207` are hand-rolled instead of `Ui::StarBadge` / `Ui::BalanceChip` / `Ui::StarValue`. Inconsistent visual depth (`0 2px 0` vs `0 3px 0`).
- HIGH · `app/views/kid/rewards/index.html.erb:40-49` balance number uses raw `<span>` with inline `count-up` controller; `Ui::BalanceChip` already wraps that pattern with `count-up`.
- MEDIUM · `app/views/kid/rewards/index.html.erb:121-124,168-172` — reward cost displayed as raw `<span>` + icon, not `Ui::StarValue`.
- MEDIUM · `app/components/ui/redemption_row/component.html.erb:7` — uses `Ui::StarValue` ✓ but with `prefix: "−"` and `color: :gold` (gold gradient is for positive-affordance balance). For a spend, `color: :current` red would be clearer.

## 9. Animations

- MEDIUM · `app/views/kid/rewards/redeem.turbo_stream.erb:9-19` injects an inline `<script>` into `<body>` to manipulate DOM (close modals, bump count-up). DESIGN.md §11 forbids inline `style="..."` and this also bypasses Stimulus — replace with a Stimulus action or dedicated turbo-stream targets.
- MEDIUM · `app/views/kid/dashboard/index.html.erb:184` — `animation: slideInCard … <%= [i,5].min * 0.04 %>s both` — stagger cap of 5 ✓ per DESIGN.md §9. Same for rewards `:101,151`. ✓
- LOW · `app/views/kid/shared/_celebration.html.erb` — `data-fx-event="celebrate"` hooked to MutationObserver via `fx` controller (good). No `prefers-reduced-motion` guard at the partial level — relies on global `motion.css`. Verify the celebration modal honors it.
- LOW · `app/components/ui/confetti/confetti_controller.js` — `setInterval` runs for 3s, doesn't check `prefers-reduced-motion`. Should early-return when reduced-motion is preferred.
- LOW · `app/components/ui/profile_picker/component.css:1-6` — has reduced-motion guard ✓.
- LOW · `app/components/ui/pin_modal/component.css:15-17` — has reduced-motion guard ✓ but only for `.pin-dot`/`.pin-key`; `pin-card-pop` and `pin-modal-fade` keyframes still fire.

## 10. Accessibility

- HIGH · `app/views/kid/dashboard/index.html.erb:209-215` "Fiz!" button — no `aria-label` though label text is present (OK), but icon-only "Trocar" toggle at `:36-43` has icon + text ✓. The 38×38 back chip at `rewards/index.html.erb:11-16` has `aria: { label: "Voltar" }` ✓.
- HIGH · `app/views/kid/dashboard/index.html.erb:27-32` and `rewards/index.html.erb:41-49` — balance updates animate via `count-up` controller but element has **no `aria-live`** region. Screen-reader users miss balance changes. DESIGN.md §10 implies aria-live for live updates.
- MEDIUM · `app/components/ui/smiley_avatar/component.html.erb:1` — `role="img"` + `aria-label` ✓ but if `kid` doesn't respond to `name`, label is empty string (silent image). Add fallback.
- MEDIUM · `app/components/ui/kid_initial_chip/component.html.erb:1` — only `title` attribute, no `aria-label`. Title isn't read by all SR.
- MEDIUM · `app/components/ui/star_badge/component.rb:13-18` — pure decorative `<i>` with no `aria-hidden`. `Ui::StarValue` SVG correctly uses `aria-hidden="true"`.
- MEDIUM · `app/views/kid/rewards/index.html.erb:66-81` filter tabs — buttons have no `role="tab"` / `aria-selected` (DESIGN.md §10 mandates).
- MEDIUM · `app/views/kid/rewards/index.html.erb:272-278` disabled "Sim, quero!" — uses `style="opacity:0.5"` only, no `aria-disabled` (although `disabled` HTML attr present ✓).
- LOW · `app/components/ui/pin_modal/component.html.erb:32` — backspace key uses `⌫` glyph + `aria-label="Apagar"` ✓.
- LOW · `app/components/ui/pin_modal/component.html.erb:37` — "Esqueci meu PIN" is `<a>` with no `href` — not focusable/keyboard-actionable. → Make a `<button>`.
- LOW · `app/views/kid/rewards/redeem.turbo_stream.erb:10-18` — DOM-mutating script changes `style.display = "none"` and `style.overflow = "auto"` — invasive, avoids Stimulus, can leave focus trapped.

## 11. Dead code / retired styles

- MEDIUM · `app/views/kid/dashboard/_awaiting_row.html.erb` — appears used only by `complete.turbo_stream.erb` ✓; but its markup is duplicated again in `dashboard/index.html.erb:154-173`. Pick one.
- MEDIUM · `app/views/kid/dashboard/_completed_task.html.erb` — no references found in dashboard/index.html.erb (which inlines the markup directly). Likely dead. → Verify and delete or wire up.
- MEDIUM · `app/views/kid/dashboard/_profile_task.html.erb` — appears unused: dashboard/index.html.erb:177 inlines its own version; this partial uses `Ui::MissionCard` "bubble" variant. Either delete or refactor index to use partial.
- LOW · `app/assets/stylesheets/components/redeem_modal.css:1` — file header says "Legacy redeem-modal kept only for any non-kid usages. Active kid flow uses .redeem-ritual" — but `.redeem-ritual` *is* defined in this same file and used by kid rewards. Comment is misleading; rename file.
- LOW · `app/components/ui/smiley_avatar/component.rb:5-7` — `"lila"` and `"lilac"` keys are duplicates. Pick one.
- LOW · `app/components/ui/kid_placeholder_card/*` — used in parent surfaces; not really kid-scoped. (Out of true scope.)

---

## Top 10 fixes prioritized

1. **CRITICAL — fix kid shell width** (`layouts/kid.html.erb:12`): replace `max-w-screen-md` with `max-w-[430px]`. Single-line change that unblocks DESIGN.md §4/§7 compliance for every kid page.
2. **CRITICAL — collapse duplicated mission cards** (`dashboard/index.html.erb:135-173`, `_awaiting_row.html.erb`, `_awaiting_task.html.erb`, `_completed_task.html.erb`): introduce `Ui::MissionCard` `status: :approved | :waiting | :rejected` variants and delete the four divergent partials.
3. **HIGH — unify kid header**: extract `Ui::KidTopBar` (streak + balance + switch) and replace bespoke headers in dashboard, rewards, missions/new, wallet. Wallet already uses `Ui::TopBar` — extend it or build kid-specific sibling.
4. **HIGH — route every star/balance through components**: replace inline chips at `dashboard/index.html.erb:24-33,121-126,167-172,202-207` and `rewards/index.html.erb:31-60` with `Ui::BalanceChip` / `Ui::StarValue` / `Ui::StarBadge`.
5. **HIGH — replace hand-rolled buttons with `Ui::Btn`**: `dashboard/index.html.erb:36-43,209-215`; `missions/new.html.erb:58-64`; `rewards/index.html.erb:11-16,53-59,118-126,257-278`.
6. **HIGH — add `aria-live="polite"` to balance elements**: `profile_points_<id>` spans on dashboard and rewards must announce count-up changes.
7. **HIGH — normalize button shadows to `0 4px 0`**: dashboard "Trocar"/"Fiz!", rewards CTAs and locked cards (`0 3px 0` and `0 5px 0` outliers).
8. **MEDIUM — extract `Ui::KidRewardCard`** (affordable + locked variants) from `rewards/index.html.erb:99-181`. Eliminates ~80 lines of duplication.
9. **MEDIUM — remove inline `<script>` from `redeem.turbo_stream.erb`**: replace DOM mutation with a Stimulus `redeem` controller action and dedicated `turbo_stream.update`s. Restores focus management.
10. **MEDIUM — move `SmileyAvatar` palette to CSS vars**: `component.rb:5-16` is the largest concentration of raw hex outside `theme.css`; promote to `--avatar-<color>-fill/ring/ink` tokens (also fixes the duplicate `lila`/`lilac` keys).

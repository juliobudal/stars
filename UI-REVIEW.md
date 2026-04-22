# LittleStars — UI/UX Audit Report

**Date:** 2026-04-22
**Auditor:** GSD UI Auditor (Claude Sonnet 4.6)
**Baseline:** Abstract 6-pillar standards + Duolingo-style rebranding goals
**Screenshots:** Not captured — no dev server detected at localhost:3000 or localhost:5173

---

## Overall Score: 17/24

| Pillar | Score | Grade |
|--------|-------|-------|
| 1. Copywriting | 4/4 | Excellent |
| 2. Visuals | 3/4 | Good |
| 3. Color | 2/4 | Needs Work |
| 4. Typography | 3/4 | Good |
| 5. Spacing | 3/4 | Good |
| 6. Experience Design | 2/4 | Needs Work |

---

## Quick Wins Summary (all actionable fixes, under 30min each)

1. **CSS `--primary` never renders as Duolingo blue** — `design_system.css` imports last and overrides `brand.css`; fix by removing the conflicting `:root` variable block from `design_system.css`
2. **`complete.turbo_stream.erb` targets stale DOM IDs** — `awaiting_list`, `completed_section`, `missions_list` no longer exist in the redesigned dashboard; update to `panel-waiting` and use design_system components for flash
3. **`approve.turbo_stream.erb` flash uses unresolvable Tailwind classes** — `bg-brand-green`, `border-brand-green-depth` will render with no background; replace with `render Ui::Flash::Component.new`
4. **`pending_approvals_count` ID mismatch** — Turbo stream targets `pending_approvals_count` but the DOM renders `pending_approvals_kpi`; rename one to match the other
5. **Icon-only approve/reject buttons have no `aria-label`** — `parent/approvals/index.html.erb:57,62,93,98`; add `form: { aria: { label: "..." } }` or inline `aria-label`
6. **Hardcoded hex colors in wallet/activity views** — `#1a6a4a` and `#8a2e4a` repeated in `kid/wallet/index.html.erb:24-36` and `parent/activity_logs/index.html.erb:24-36`; replace with CSS variable references
7. **Bottom nav missing safe-area-inset** — `design_system.css` `.bottom-nav` uses `bottom: 20px` without `env(safe-area-inset-bottom, 0px)`; home indicator overlap on iPhone X+

## Big Opportunities Summary (major improvements needing dedicated work)

1. **Consolidate the dual design systems** — `brand.css`/`tailwind/theme.css` and `design_system.css` both define `:root` CSS variables with colliding names (`--primary`, `--success`, `--border`); a single source of truth is needed before the Duolingo rebrand can actually take effect visually
2. **Parent navigation** — No persistent nav in the parent interface; every sub-page requires tapping back to the dashboard hub; add a bottom bar or sidebar with direct links to Aprovações, Missões, Crianças
3. **Turbo stream template library debt** — Multiple turbo stream templates (`approve.turbo_stream.erb`, `approve_redemption.turbo_stream.erb`, `reject.turbo_stream.erb`, `complete.turbo_stream.erb`) use raw Tailwind classes and old HTML from before the design system refactor; these need systematic replacement with the current component library

---

## Pillar 1: Copywriting — 4/4

### Findings

The copywriting is the app's strongest pillar. The Duolingo-inspired Portuguese voice is warm, playful, and consistent throughout both interfaces. No generic "Submit", "OK", or "Cancel" patterns were found.

**Kid interface highlights:**
- `kid/dashboard/index.html.erb:57` — "Pra Fazer" / "Aguardando" tab labels are natural kid speech, not technical status labels
- `kid/dashboard/index.html.erb:107` — "Terminou essa missão? Um responsável vai confirmar." is perfectly clear for a child
- `kid/dashboard/index.html.erb:108` — "Ainda não" / "Terminei!" are conversational, context-specific CTAs
- `kid/rewards/index.html.erb:56` — "Faltam X estrelinhas" affordance on locked items is motivating rather than discouraging
- `kid/wallet/index.html.erb:64` — Empty state: "Complete missões ou faça resgates pra começar o histórico" is inviting
- `sessions/index.html.erb:8` — "Quem vai brilhar hoje?" is an excellent hero headline

**Parent interface highlights:**
- `parent/dashboard/index.html.erb:88` — "Para começar as missões, adicione o primeiro filho(a)." has a clear next action embedded in the empty state
- Destructive confirms have specific copy: "Tem certeza? Isso removerá a missão permanentemente." — contextual, not generic

**Minor note — LOW:**
- `parent/global_tasks/index.html.erb:4` — page title "Banco de Missões" is more adult-facing than the rest of the gamified vocabulary ("Lojinha", "Estrelinhas", "Missões"). Consider "Missões da Família" for consistency.

---

## Pillar 2: Visuals — 3/4

### Findings

**Strengths:**
- `Ui::BgShapes::Component` provides organic blurred gradient shapes on every screen — effective atmospheric layering with zero asset overhead
- `Ui::KidAvatar::Component` generates colored circular avatars with Phosphor face icons — coherent, charming, no image file dependencies
- Mission card "bubble" variant with category-colored circles and bottom-shadow is visually distinctive and gamified
- `Ui::Celebration::Component` + `celebration_controller.js` — 60-piece confetti burst with central glow is polished and proportionate
- `Ui::Lumi::Component` mascot has 5 mood states (happy, excited, thinking, sad, wow) giving it genuine personality
- Session screen with staggered card entry animations (`slideInCard`) creates a strong first impression
- `.card-tap:active { transform: translateY(4px) }` and `.pop-on-tap:active` give tactile press feedback

**MEDIUM — Lumi depends entirely on Phosphor CDN with no fallback:**
`app/components/ui/lumi/component.rb:23-24` — Lumi is two `<i>` tags that require `unpkg.com/@phosphor-icons` to load. No `<img>` fallback, no inline SVG. If Phosphor CDN is slow (slow mobile, corporate proxy) or blocked, the mascot is invisible. This is especially high-risk because Lumi is rendered on the session screen (first impression) and inside every mission confirmation modal.

**MEDIUM — Mission card bubble border has no guard for `primary` category:**
`mission_card/component.html.erb:49` — `border: 3px solid var(--c-<%= category_data[:color] %>)`. When `category_data[:color]` is `"primary"`, this resolves to `var(--c-primary)` which is undefined. The `kid_avatar/component.rb:17` correctly special-cases this to `var(--primary)`, but the mission card template does not. Primary/Geral category missions will render with no visible border.

**LOW — Empty states use `Ui::IconTile` (a small square icon tile) but Lumi is available.** For the kid interface, an excited or thinking Lumi would be more emotionally resonant than a generic icon tile in empty states.

**LOW — Parent avatar is purely functional.** `parent/dashboard/index.html.erb:7-10` shows a `user-circle` icon in a soft circle with no personalization beyond color selection. Parent avatars support the same icon system as kid avatars (`faceParent`) but the `faceKid` variants (fox, hero, princess) are explicitly reserved for children only via the form options at `profiles/_form.html.erb:13`.

### Quick Wins
- Guard mission card bubble border: in `mission_card/component.html.erb:49`, replace `var(--c-<%= category_data[:color] %>)` with an ERB ternary outputting `var(--primary)` when color == "primary"
- Add `aria-label` to approve/reject icon-only buttons: `parent/approvals/index.html.erb:57,62,93,98`

### Big Opportunities
- Replace Phosphor CDN load for Lumi with self-hosted or inline SVG fallback
- Add Lumi poses (sad or thinking) to kid-interface empty states

---

## Pillar 3: Color — 2/4

### Findings

This is the most critical pillar. The Duolingo rebrand color palette is defined correctly in `brand.css` but is being systematically overridden by `design_system.css`, which is loaded last.

**CRITICAL — CSS variable collision prevents Duolingo rebrand from rendering:**

Import order in `app/assets/stylesheets/application.css`:
```
@import "./brand.css";          // Line 2: --primary: var(--duo-blue) = #1CB0F6
@import "./design_system.css";  // Line 9: --primary: #2e7df6  (OVERWRITES)
```

Affected variables and their consequences:

| Variable | brand.css value | design_system.css value (wins) | Impact |
|----------|-----------------|-------------------------------|--------|
| `--primary` | `#1CB0F6` (Duolingo cyan-blue) | `#2e7df6` (standard blue) | All primary buttons, active tabs, focus rings render wrong color |
| `--success` | `#58CC02` (Duolingo green) | `#2eca7f` (muted mint) | Approve buttons, earn badges, success states wrong |
| `--border` | `#E5E5E5` (color token) | `2px solid rgba(...)` (shorthand) | Cards using `border: var(--border)` from design_system render correctly, but Tailwind utilities using `border-color: var(--color-border)` will receive a shorthand value instead of a color — potential broken borders |
| `--danger` | `#FF4B4B` (Duolingo red) | `#ff5258` (very similar) | Minor |

The Duolingo palette (`--duo-green`, `--duo-blue`, `--duo-yellow`) defined in `brand.css:16-27` is never referenced anywhere in the views. It is defined but unreachable because `--primary` is always overridden before any component uses it.

**HIGH — Dark mode has no coverage in `design_system.css`:**
`brand.css:56-80` defines `.dark` variants. `design_system.css` defines its palette only in `:root`. Custom classes using `var(--bg-deep)`, `var(--surface)`, `var(--text)` have no dark equivalents — those variables don't exist in the `.dark` scope, so they will fall back to browser defaults.

**MEDIUM — Hardcoded hex colors in views (copy-pasted between two views):**
- `kid/wallet/index.html.erb:24,25,35,36` — `color: #1a6a4a` (earn), `color: #8a2e4a` (spend)
- `parent/activity_logs/index.html.erb:24,25,35,36` — identical hardcoded values
- `kid/dashboard/index.html.erb:24` — `color: "#ffc41a"` passed to icon component

These should reference CSS variables (`var(--c-mint)` for earn, `var(--c-rose)` for spend, `var(--star)` for star icon).

**MEDIUM — Turbo stream flash templates use Tailwind classes that won't resolve:**
- `approve.turbo_stream.erb:9` — `bg-brand-green`, `border-brand-green-depth` are not defined Tailwind utilities
- `approve_redemption.turbo_stream.erb:9` — same issue; flash renders with transparent background
- `reject.turbo_stream.erb:4` — `bg-red-600` is standard Tailwind and will work, but is inconsistent with `var(--danger)`

### Quick Wins
- Remove the `:root` block from `design_system.css` (lines 6-73) that redefines `--primary`, `--success`, `--danger`, `--border`, `--text-*`, `--bg-*`. These are duplicates of what `brand.css` defines. Custom vars like `--star`, `--c-peach`, `--r-sm` that are unique to `design_system.css` should remain.
- Replace hardcoded hex colors in `kid/wallet/index.html.erb` and `parent/activity_logs/index.html.erb` with CSS variable references
- Fix Turbo stream flash templates to use `render Ui::Flash::Component.new` or `style="background-color: var(--success)"`

### Big Opportunities
- Choose one CSS variable system as the single source of truth; currently `brand.css` (for Tailwind-integrated theming) and `design_system.css` (for custom component classes) are parallel, conflicting systems
- Add dark mode variable overrides to `design_system.css` to match the `.dark` block in `brand.css`

---

## Pillar 4: Typography — 3/4

### Findings

**Strengths:**
- Two complementary fonts: Nunito (round, warm) for body and Fredoka (geometric, playful) as display — both fit the kids-app personality
- `design_system.css` defines three semantic text roles: `.h-display` (800 weight, tight tracking), `.subtitle` (17px, muted color), `.eyebrow` (12px, uppercase, wide tracking) — clean separation of hierarchy levels
- Fluid type on display headings: `h1.display { font-size: clamp(36px, 5vw, 56px) }` handles different viewport sizes without media query fragmentation
- `font-weight: 600` on body text (`design_system.css:111`) ensures readability for young readers at smaller sizes

**MEDIUM — Font system split creates inconsistency between Tailwind utilities and design_system classes:**
- `tailwind/theme.css:2` — `--font-sans: 'Fredoka', ...` (Fredoka is the Tailwind sans font)
- `design_system.css:62-63` — `--font-display: 'Nunito', ...` and `--font-body: 'Nunito', ...`

Result: Tailwind utility `font-sans` renders Fredoka. Design system classes render Nunito. Flash toasts (`flash/component.html.erb:7`) use `font-extrabold` (Tailwind utility = Fredoka). Buttons use `design_system.css` `.btn` which specifies `font-family: var(--font-display)` = Nunito. Fredoka and Nunito will render in adjacent UI elements without a declared intent to use both.

**MEDIUM — `Ui::TopBar` title hardcodes `font-size: 30px`:**
`top_bar/component.html.erb:13` — `style="font-size: 30px;"` is outside the `clamp()` system. On narrow screens (320px), this will not scale down. Mission titles and page titles will overflow or truncate without ellipsis handling.

**LOW — No line-height specification on `.h-display` beyond 1.05.** For CJK or RTL language support this could cause issues, but for Portuguese this is fine.

**LOW — `design_system.css:173` — `.h-display-dark` class is defined but never used in any view or component.** Dead CSS.

### Quick Wins
- Align font stacks: change `tailwind/theme.css:2` to `'Nunito', ui-sans-serif, ...` to match `--font-body`, making Tailwind utilities consistent with design_system classes
- Add `overflow: hidden; text-overflow: ellipsis; white-space: nowrap;` to `Ui::TopBar` title for long names on small screens

### Big Opportunities
- Evaluate consolidating to a single font (Nunito or Fredoka) — two fonts add ~60KB and the visual difference is subtle enough that the target audience (children) will not perceive it as a design decision

---

## Pillar 5: Spacing — 3/4

### Findings

**Strengths:**
- `design_system.css` defines a consistent scale: `--space-1: 4px` through `--space-8: 56px` — 8-point-adjacent, appropriate for touch UIs
- Card padding is consistently `14-18px` throughout views (between `--space-4` and `--space-5`)
- `.screen` has `padding: var(--space-5) var(--space-6)` = 24px / 32px — generous breathing room
- `with-nav` adds `padding-bottom: 120px` — sufficient clearance above the floating bottom-nav
- `grid-2` collapses to single column at 640px (`design_system.css:572`) — basic mobile responsiveness

**HIGH — 214 inline `style=` attributes in views:**
The 214 inline style attributes across the kid and parent views means every spacing decision is locked into the template. `kid/dashboard/index.html.erb:6` has `style="justify-content: space-between; z-index: 2; flex-shrink: 0;"` — a recurring pattern that should be a named class. Systematic spacing changes require editing dozens of files.

**MEDIUM — `z-index: 2` applied to nearly every content div with no documented layering system:**
`kid/dashboard/index.html.erb:6,18,54,75,128` and `parent/dashboard/index.html.erb:21,48,97` each have `z-index: 2` as inline style. The `.viewport` container and `.bg-shapes-wrapper` (z-index: 0) establish the layer, but the content divs individually setting z-index: 2 is fragile — a future component with z-index: 1 would render beneath all content.

**MEDIUM — Bottom nav lacks safe-area-inset-bottom:**
`design_system.css:388-389` — `.bottom-nav` uses `bottom: 20px` with no `env(safe-area-inset-bottom, 0px)`. On iPhones with home indicator (iPhone X and all models since), the nav icons overlap with the system gesture area — a significant UX issue for the primary target device category.

**LOW — Staggered animation delay scales indefinitely with list length:**
`kid/dashboard/index.html.erb:77` — `animation-delay: <%= @index * 0.05 %>s`. With 10 tasks, the last card enters at 500ms — perceptible as latency. With 20 tasks (possible for a busy family), the last card enters at 1000ms.

**LOW — Reward cards in `grid-2` have no `min-width` guard.** On screens narrower than 360px, cards at `calc(50% - 8px)` may be too narrow to display the icon + title + badge comfortably.

### Quick Wins
- Add `padding-bottom: calc(20px + env(safe-area-inset-bottom, 0px))` to `.bottom-nav` in `design_system.css:388`
- Extract `z-index: 2; flex-shrink: 0;` into a `.content-layer` utility class in `design_system.css`
- Cap animation stagger: `<%= [i, 5].min * 0.04 %>s` to prevent >200ms delays

### Big Opportunities
- Systematically replace inline `style=` spacing/layout attributes with named utility classes — reduces template complexity by ~60% and enables theming

---

## Pillar 6: Experience Design — 2/4

### Findings

**Strengths:**
- `count_up_controller.js` animates the star balance on Turbo Stream updates — excellent micro-interaction that makes earning feel real
- `celebration_controller.js` confetti burst on redemption is a well-implemented emotional peak
- `Ui::Flash::Component` auto-dismisses after 2200ms — well-calibrated duration
- All major screens have empty states with helpful copy and a clear next action
- Destructive actions use `turbo_confirm` with specific contextual messages
- Turbo Frame on `approvals_list` enables approve/reject without full page reload
- `turbo_stream_from current_profile.family, "approvals"` in parent layout enables real-time approval broadcast

**CRITICAL — `complete.turbo_stream.erb` targets stale DOM IDs:**

`kid/missions/complete.turbo_stream.erb` references three IDs that no longer exist in the redesigned dashboard:

| Stream target | Current DOM id | Status |
|--------------|----------------|--------|
| `awaiting_list` (line 3) | `panel-waiting` (dashboard:128) | Silently fails |
| `completed_section` (line 8) | Does not exist | Silently fails |
| `missions_list` (line 26) | Does not exist | Silently fails |

When a kid marks a task complete:
1. Task is removed from "Pra Fazer" — works correctly
2. Task should appear in "Aguardando" tab — never happens
3. The "Aguardando" tab badge count does not update
4. Flash renders old HTML with `bg-indigo-50` / `text-indigo-800` classes (line 20-23) from a pre-redesign template

**CRITICAL — Confetti never fires on parent approval:**

`approve.turbo_stream.erb:5` appends `data-controller="ui--confetti"` to the body. The celebration controller is registered as `celebration` (via `celebration_controller.js`). No `ui--confetti` controller exists in the registration. The confetti on parent approval has been silently broken since the controller was renamed.

**HIGH — `pending_approvals_count` DOM target mismatch:**

`approve.turbo_stream.erb:25` and `reject.turbo_stream.erb:19` update `id="pending_approvals_count"`. The parent dashboard renders the KPI with `id="pending_approvals_kpi"` (`parent/dashboard/index.html.erb:33`). The real-time counter update silently targets a non-existent element.

**HIGH — Parent interface has no persistent navigation:**

`layouts/parent.html.erb` has no nav bar, no sidebar, no persistent menu. Every sub-page requires tapping the TopBar back arrow to return to the dashboard, then tapping a tile again. The most common parent workflow (checking approvals, then checking the task bank) requires 4 taps where a 1-tap bottom nav would suffice.

**HIGH — No loading state on approve/reject buttons:**

Approve buttons (`btn-success btn-icon`) submit immediately with no visual loading state and no turbo_confirm guard. On a slow connection, a parent can tap approve multiple times. Consider `data-turbo-submits-with="..."` to disable the button after first tap.

**MEDIUM — Unusual flash render in `redeem.turbo_stream.erb:13`:**

```ruby
render Ui::Flash::Component.new.tap { |c| flash.now[:notice] = "Resgate solicitado!" }
```

This sets `flash.now` as a side effect inside a render call. The flash component reads from the global `flash` object in its template — this coupling is fragile. Additionally, `turbo_stream.prepend "flash"` will accumulate toasts if multiple redemptions fire quickly because the prepend doesn't clear existing toasts first.

**MEDIUM — No Turbo progress bar styling.** Turbo's default progress bar renders in its default blue color. On the kid interface with the warm blue brand, this is approximately matching, but it has not been styled to use `var(--primary)` or branded colors.

**LOW — No visible per-item loading state on task completion.** When a kid taps "Terminei!" in the confirmation modal, the modal closes but there is no spinner or visual feedback during the Turbo request. On slow connections this creates a gap of uncertainty.

**LOW — Reject action on `approve_redemption.turbo_stream.erb` (line 9) uses `bg-brand-green` for a rejection confirmation** — the wrong semantic color. Should be danger/red.

### Quick Wins
- Fix `complete.turbo_stream.erb`: update `prepend "awaiting_list"` to target `panel-waiting`, remove dead `completed_section` and `missions_list` replacements, replace old flash HTML with `render Ui::Flash::Component`
- Fix `approve.turbo_stream.erb:5`: change `data-controller="ui--confetti"` to `data-controller="celebration"` and add `data-celebration-target="layer"` to the inner div
- Fix `pending_approvals_count` → `pending_approvals_kpi` in both approve/reject turbo stream files
- Add `aria-label="Aprovar"` and `aria-label="Rejeitar"` to icon-only approval buttons

### Big Opportunities
- Rebuild all turbo stream templates using the current component library — they are currently the biggest inconsistency in the codebase
- Add a persistent parent bottom nav bar (4 items: Início, Aprovações, Missões, Lojinha) with badge count on Aprovações
- Add `data-turbo-submits-with` to approve/reject forms to prevent double-submission

---

## Files Audited

**Views (24 files):**
`app/views/layouts/kid.html.erb`, `app/views/layouts/parent.html.erb`,
`app/views/shared/_head.html.erb`, `app/views/sessions/index.html.erb`,
`app/views/kid/dashboard/index.html.erb`, `app/views/kid/rewards/index.html.erb`,
`app/views/kid/wallet/index.html.erb`, `app/views/kid/missions/complete.turbo_stream.erb`,
`app/views/kid/rewards/redeem.turbo_stream.erb`, `app/views/parent/dashboard/index.html.erb`,
`app/views/parent/approvals/index.html.erb`, `app/views/parent/approvals/approve.turbo_stream.erb`,
`app/views/parent/approvals/approve_redemption.turbo_stream.erb`,
`app/views/parent/approvals/reject.turbo_stream.erb`,
`app/views/parent/approvals/reject_redemption.turbo_stream.erb`,
`app/views/parent/global_tasks/index.html.erb`, `app/views/parent/global_tasks/_form.html.erb`,
`app/views/parent/rewards/index.html.erb`, `app/views/parent/rewards/_form.html.erb`,
`app/views/parent/profiles/index.html.erb`, `app/views/parent/profiles/_form.html.erb`,
`app/views/parent/activity_logs/index.html.erb`

**Components (14 files):**
`app/components/ui/mission_card/component.rb` + `component.html.erb`,
`app/components/ui/lumi/component.rb`, `app/components/ui/top_bar/component.rb` + `component.html.erb`,
`app/components/ui/balance_chip/component.rb`, `app/components/ui/kid_avatar/component.rb`,
`app/components/ui/celebration/component.rb`, `app/components/ui/flash/component.rb` + `component.html.erb`,
`app/components/ui/empty/component.rb`, `app/components/ui/btn/component.rb`,
`app/components/ui/icon/component.rb`, `app/components/ui/badge/component.rb`,
`app/components/ui/bg_shapes/component.rb`, `app/components/ui/modal/component.rb`

**Stylesheets (5 files):**
`app/assets/stylesheets/application.css`, `app/assets/stylesheets/brand.css`,
`app/assets/stylesheets/design_system.css`, `app/assets/stylesheets/tailwind/theme.css`,
`app/assets/stylesheets/tailwind/animations.css`

**JavaScript (5 files):**
`app/assets/controllers/celebration_controller.js`, `app/assets/controllers/count_up_controller.js`,
`app/assets/controllers/tabs_controller.js`, `app/assets/controllers/ui_modal_controller.js`,
`app/components/ui/modal/modal_controller.js`

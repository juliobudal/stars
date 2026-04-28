# UI Audit — Consolidated Plan (2026-04-28)

Scope: full UI audit against `DESIGN.md` (Duolingo system). Read-only auditors produced 4 reports in this directory.

## Severity Roll-up

| Domain | C | H | M | L |
|---|---|---|---|---|
| 01 Layouts + global UI | 4 | 22 | 22 | 11 |
| 02 Kid surfaces | 2 | 14 | 17 | 16 |
| 03 Parent surfaces | 0 | 12 | 11 | 16 |
| 04 Auth/shared | 1 | 17 | 17 | 9 |
| **Total** | **7** | **65** | **67** | **52** |

## Headline issues

- **Layout widths wrong on both shells** — kid `max-w-screen-md` (768px) vs spec 430px; parent `lg:max-w-none` vs spec 900px. Single biggest visual win.
- **Mission card duplicated 4×** on kid surfaces; should be `Ui::MissionCard` status variants.
- **Parent pages duplicate page-header markup 8×** + form-section card markup 14× + error panel 4×.
- **~30 inline `ls-btn-3d` blocks** across parent surfaces bypass `Ui::Btn`.
- **Auth forms hand-roll inputs** (no `<label>`, no `autocomplete`, no field errors); logo lockup duplicated 3+ pages.
- **PWA manifest is unbranded scaffolding**; mailers ship with zero brand chrome.
- **Token leakage**: `SmileyAvatar::COLOR_MAP` (11 raw-hex palettes), `Ui::ApprovalRow` (#FFF4D6/#B45309/#F5F5F7), `Ui::Card` primary shadow uses Berry-Pop ink.
- **`Ui::Btn` press contract wrong** — uses `translate-y-1 + colored shadow` instead of `translateY(2px) + box-shadow:none`. Misses `:focus-visible` ring.
- **Blurry `shadow-sm` in modal/drawer/popover/tooltip/tabs/select** — should be flat `0 4px 0`.
- **Nunito loaded with weights 400/900** — spec only allows 700/800. Missing `<html lang>`.
- **`_kid_nav` / `_parent_nav`** reimplement nav by hand; `Ui::Sidebar`/`Ui::Navbar`/many other primitives unused.
- **Inline `<script>`** in `redeem.turbo_stream.erb` mutates DOM/focus.
- **Dead code**: `components/typography.css`, `body.css`, `form.css`, `group/group.css`, 8 empty `form_builders/*.yml`.

## Fix Plan — Waves

### Wave 0 — Quick wins (single agent, ~30 min, no deps)
1. `layouts/kid.html.erb:12` width fix (430px)
2. `layouts/parent.html.erb:14` width fix (900px)
3. `_head.html.erb:4` Nunito → 700;800 only + `lang="pt-BR"`
4. Delete dead CSS (`typography.css`, `body.css`, `form.css`, `group/group.css`)
5. Archive `.planning/BERRY-POP-REMAINING.md`

### Wave 1 — Foundation primitives (sequential, blocks Wave 2)
Build/fix shared components everything else depends on:
- **Fix** `Ui::Btn` active state + focus ring (DESIGN §5/§13)
- **Fix** `Ui::Card` primary shadow (drop Berry-Pop ink)
- **Fix** modal/drawer/popover/tooltip/tabs/select to flat `0 4px 0`
- **Fix** modal radii (theme.css `--radius-modal` 30→20px; pin_modal 20→24px)
- **New** `Ui::PageHeader` (parent title + subtitle + right slot)
- **New** `Ui::FormSection` (white card + hairline + uppercase label slot)
- **New** `Ui::FormErrors` partial
- **New** `Ui::Brand` (logo lockup for auth)
- **New** `Ui::KidTopBar` (streak + balance + switch)
- **Extend** `Ui::MissionCard` with `status: :approved | :waiting | :rejected`
- **New** `Ui::HeaderStatChip` (parent corner stats)
- **Tokens**: add `--avatar-<color>-fill/ring/ink` set; migrate `SmileyAvatar::COLOR_MAP`

### Wave 2 — Surface adoption (parallel, 4 agents)
After Wave 1 lands, dispatch in parallel:

**2A — Kid surfaces**
- Adopt `Ui::KidTopBar` in dashboard/rewards/missions/wallet
- Collapse mission-card partials → `Ui::MissionCard` variants
- Route stars through `Ui::BalanceChip` / `Ui::StarValue` / `Ui::StarBadge`
- Inline buttons → `Ui::Btn`; normalize shadows
- `aria-live="polite"` on balance spans
- Extract `Ui::KidRewardCard` (affordable + locked)
- Replace inline `<script>` in `redeem.turbo_stream.erb` with Stimulus

**2B — Parent surfaces**
- Adopt `Ui::PageHeader` in 8 pages
- Adopt `Ui::TopBar` for back-arrow sub-pages (categories/rewards/profiles new+edit)
- Adopt `Ui::FormSection` × 14 form blocks
- Adopt `Ui::FormErrors` × 4 panels
- ~30 inline `ls-btn-3d` → `Ui::Btn`
- `form-input`/`form-label` classes everywhere
- Rebuild `parent/invitations/new`
- Fix `Ui::ApprovalRow` hex fallbacks

**2C — Auth/shared**
- Adopt `Ui::Brand` in family_sessions/profile_sessions/registrations/password_resets/invitations
- Real `<label>` + `autocomplete` on all auth inputs
- Field-level error rendering (registration + password_resets)
- Rebuild `invitations/show` to auth shell pattern
- Align `password_resets/*` with login card pattern
- Mailer layout + branded CTA in password_mailer/invitation_mailer
- PWA manifest rewrite (name, theme_color #58CC02, icons)

**2D — Nav primitives**
- Migrate `_kid_nav` and `_parent_nav` to `Ui::Sidebar` / `Ui::Navbar`, OR delete unused primitives
- Move `pending_count` query out of partial into controller/helper

### Wave 3 — Polish & cleanup (single agent)
- Decide `app/components/form_builders/*` (implement matching yml specs OR delete stubs)
- Service worker: real precache + offline fallback OR remove registration
- Sweep remaining MEDIUM/LOW per-report findings
- `bundle exec rspec` + visual smoke test (kid + parent flows)

## Notes
- Waves 0 → 1 → 2 (parallel) → 3 is the dependency order. Don't start Wave 2 until Wave 1 components exist.
- All commits English, conversational PT-BR per CLAUDE.md.
- Each wave should produce atomic commits (one logical change per commit) so we can bisect if regressions appear.

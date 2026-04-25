# Session Handoff — Parent UI Polish + Pendency Audit

Date: 2026-04-25
Branch: `main`
Last commits:
```
3af6f33 chore: rubocop autocorrect (case indent + array literal spacing)
ef070f9 fix(ui): parent shell polish — full-bleed layout, tighter sidebar, FamilySelector + KidPlaceholderCard
2258fb7 fix(auth): clear stale family cookie when family record is gone
```

---

## What This Session Shipped

### Parent shell polish (commit `ef070f9`)
- **Layout** (`app/views/layouts/parent.html.erb`): dropped `lg:max-w-6xl mx-auto`. Full-bleed by default with `lg:px-8` gutter. New `:container_class` yield slot for narrow opt-in.
- **Sidebar** (`app/views/shared/_parent_nav.html.erb`): nav items reduced `px-4 py-3 text-[15px]` → `px-3 py-2 text-[14px]`, icons 20 → 18.
- **FamilySelector** (NEW `app/components/ui/family_selector/`): circular initial badge + truncated name + chevron on `bg-bg-soft` tile. Dropdown menu deferred.
- **KidPlaceholderCard** (NEW `app/components/ui/kid_placeholder_card/`): replaces broken `ghost-add-card` (CSS class deleted in `129d153` Tailwind v4 refactor). Dashed-border card matching kid-card height with hover lift.
- **Form opt-ins**: `content_for :container_class, "lg:max-w-3xl lg:mx-auto"` added to profiles/global_tasks/rewards/invitations new+edit; `lg:max-w-4xl` on settings/show.

### Auth fix (commit `2258fb7`)
- `FamilySessionsController#new` now clears stale `family_id` cookie when the Family record was deleted. Prevents `ERR_TOO_MANY_REDIRECTS`. 2 request specs added.

Verification: 11/11 system specs green; rubocop clean on new components; visual screenshot confirms all 4 user complaints resolved.

---

## Pendency Audit (3 parallel Explore agents, 2026-04-25)

### Audit results — most "pendencies" already shipped

| Group | Total items | HANDLE | SKIP | ALREADY-DONE |
|-------|------------:|-------:|-----:|-------------:|
| Parent UI residuals | 5 | 1 | 4 | 0 |
| Icon picker plan (T1–T9 + repo hygiene) | 12 | 0 | 0 | 12 |
| Goofy lake / 9-wave UI / design gaps | 7 | 0 | 1 | 6 |

### Real pendencies for next session

**Tier 1 — quick wins (under 30 min)**

1. **Settings legacy headings** — `app/views/parent/settings/show.html.erb:24`
   - Replace `<h2 class="font-display text-xl font-bold mb-4">PINs dos perfis</h2>` with `Ui::Heading::Component.new(size: :h2, class: "mb-4")`.
   - Also consider: wrap raw `<ul>` of PIN reset rows in a list ViewComponent if pattern repeats elsewhere — otherwise leave inline.

**Tier 2 — design polish (post-MVP, larger scope)**

2. **Hardcoded color migration** — `.planning/ui-reviews/ui-review-pixel-perfect.md:25-31` flags 23 hardcoded color values across views/components. Sweep to design tokens (`var(--primary)`, `var(--c-rose)`, etc.). Estimate: 1 phase.

3. **Font scale consolidation** — same audit flags 12 distinct `text-[Npx]` sizes across the app. Consolidate to the 5 sizes already defined in `Ui::Heading::Component` (`h1 32 / h2 22 / h3 18 / h4 15 / display 40`) plus body `text-[14px]`. Estimate: 1 phase.

4. **Destructive-action confirmations** — same audit notes missing confirms on irreversible actions. Currently uses `data: { turbo_confirm: ... }` ad hoc. Standardize via a `Ui::ConfirmAction` helper or convention doc. Estimate: 0.5 phase.

### Confirmed not actionable (skipped with rationale)

- **Duplicate empty-state in kid index** — `Ui::KidPlaceholderCard` (always) and `Ui::Empty` (only when empty) are visually separated by grid layout; not actually overlapping.
- **`border-border` token** — defined in `theme.css:115` as `--border: var(--hairline)`. Not orphan.
- **Mobile bottom nav density** — 22px icons + `text-[10px]` are intentional thumb targets in 72px nav. Different design context than sidebar.
- **`KidManagementCard` not using `Ui::Card` primitive** — only 2 cards (KidManagement + RewardCatalog) bypass primitive; both need custom data-palette + overflow behavior. Refactor cost > benefit.
- **Vite HMR WS errors in browser console** — dev-only, port mapping artifact (10302).

### Confirmed already done (closed in earlier sessions)

- All 9 icon-picker plan tasks (commits `57bbb69` → `54617ce`).
- Tag-split fix (`5d352b3`), manifest gitignore, `bin/setup` icons:sync hook.
- 9-wave UI plan W1–W8 (Opus-approved 5/8 first pass; W4/W5/W6 re-fixed in `c817e75`/`6f08b99`/`c522e65`).
- Today's commits (`cd50cb2`, `fdf9ebb`, `ef070f9`) collectively close Spacing, Visuals, and Experience pillars from the 6-pillar pixel-perfect audit.

---

## Recommended next-session entry point

```
1. Quick win: settings/show.html.erb — Ui::Heading swap (10 min, single commit).
2. Decide on Tier 2 scope: pick one of {color migration, font scale, confirmations}
   based on roadmap priority. Each warrants its own phase.
3. Re-run pendency audit if more than a week passes between sessions —
   memory drifts, codebase moves.
```

Audit source: 3 Explore agents dispatched 2026-04-25. Full per-item evidence available in conversation transcript.

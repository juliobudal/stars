# Parent UI Pixel-Perfect — Refactor Strategy (Phase 3, Opus)

**Date:** 2026-04-24
**Reviewer:** Opus (Phase 3)
**Inputs:**
- Audit: `docs/superpowers/audits/2026-04-24-parent-ui-pixel-perfect-audit.md`
- Gap inventory: `docs/superpowers/audits/2026-04-24-gap-inventory.md`
- Master plan: `docs/superpowers/plans/2026-04-24-parent-ui-pixel-perfect.md`

**Status:** APPROVED WITH CORRECTIONS — see §1

---

## 1. Consolidation Validation

The gap inventory from Phase 2 was **directionally correct** but contains **four stale assumptions** after verification against the current tree (commits through `5b67d6c`). These must be corrected before Phase 4 begins.

| # | Inventory claim | Reality (verified in code) | Action |
|---|---|---|---|
| 1 | `.eyebrow` letter-spacing 0.12em → 0.24em | `design_system.css:246` already `0.24em` | **DROP** — already fixed |
| 2 | `.stat-icon-tile` "no CSS rule defined, inline only" | `design_system.css:380-387` exists, `border-radius: 12px` | **REWRITE** gap: radius 12px → 10px (spec target) |
| 3 | `.chip-sm` "not verified / possibly missing" | `design_system.css:431-437` exists: `10px / 3px 9px / 0.12em / 600w` | **REWRITE** gap: target 11px / 4px 10px / 0.08em / 800w |
| 4 | Sidebar nav partial "location TBD" | `app/views/shared/_parent_nav.html.erb`; CSS desktop override at `design_system.css:1017-1042` already `border-radius: 14px` + `var(--primary-soft)` active bg | **PARTIALLY DONE** — desktop sidebar matches target; the *mobile/top* `.nav-item` base rule (`design_system.css:537-565`) still uses `999px` pill + `var(--star)` active. Gap is mobile-only, not cross-surface. |

Everything else in the inventory is accurate. The HIGH-priority framing is correct once the four corrections above are applied.

**Approval:** Consolidation APPROVED for Phase 4 conditional on the corrections above. Net remaining work is smaller than the inventory implied (several items resolved in the Tailwind-4 / design-token migration landed in `c98f3ec` and `98e69a7`).

---

## 2. Prioritized Refactor Sequence

Ordering principles:
1. **Token/CSS edits before ERB edits** — cross-cutting class changes ripple automatically; doing components first risks double-touching files.
2. **Independent components in parallel**, sequential only where a shared token changes.
3. **High-visibility surfaces first** (dashboard + approvals) because regressions there are most detectable.
4. **Card border-radius left last** — highest blast radius, lowest visual delta.

### Wave A — Token & CSS-rule edits (single commit, ~15 min)

Single file: `app/assets/stylesheets/design_system.css`.

| Change | Line(s) | Before | After | Rationale |
|---|---|---|---|---|
| A1 `.stat-icon-tile` radius | 383 | `border-radius: 12px` | `border-radius: 10px` | Spec §3.5 / audit §1 |
| A2 `.chip-sm` sizing | 431–437 | `font-size:10px; padding:3px 9px; letter-spacing:0.12em; font-weight:600` | `font-size:11px; padding:4px 10px; letter-spacing:0.08em; font-weight:800` | Spec §2.2 |
| A3 base `.nav-item` (mobile) | 541–564 | `border-radius:999px`, active `background:var(--star)` | `border-radius:14px`, active `background:var(--primary-soft); color:var(--text)` | Match desktop sidebar convention already in §1017–1042 |

**Dependency:** Wave A is a prerequisite for Wave B because B removes inline overrides that assume current CSS values.

### Wave B — Component ERB edits (parallelizable)

Each row is an independent atomic commit.

| # | File | Change | Complexity |
|---|---|---|---|
| B1 | `app/components/ui/stat_card/component.html.erb` | Remove the `font-size:26px` inline from `.h-display` and the `font-size:12px` from `.text-caption` (tokens already express these). Leave `background: <%= tint[:bg] %>` inline — it is data-driven. | LOW |
| B2 | `app/components/ui/kid_progress_card/component.html.erb` | Avatar 60px → 56px (width + height + matching shadow offsets if present). | LOW |
| B3 | `app/components/ui/approval_row/component.html.erb` | Checkbox `width:18px; height:18px` → `20px`. Normalize the two inner `.row` gaps: the `margin-bottom:10px` cluster gap and `gap:8px` meta gap → both `gap:10px`. | MEDIUM |
| B4 | `app/views/parent/dashboard/index.html.erb` | Recent-activity card: top/bottom padding 4px → 14px (keep horizontal as-is). | LOW |
| B5 | `app/components/ui/mission_list_row/component.html.erb` | Verify `.chip-sm` class is applied to frequency/category badges (no size overrides inline). Add class where missing. After Wave A this picks up the correct sizing automatically. | LOW |
| B6 | `app/components/ui/reward_catalog_card/component.html.erb` | Same chip-sm verification. Optional: responsive grid gap in `app/views/parent/rewards/index.html.erb` via `clamp(14px, 2vw, 28px)`. | MEDIUM |

### Wave C — Optional / deferred

| # | Item | Recommendation |
|---|---|---|
| C1 | Global `.card` border-radius 16px → 22px | **Defer.** This touches every card in both parent and kid layouts. Ship as a separate milestone with before/after screenshots. Not a blocker for "pixel-perfect parent UI" — reference @Stars uses 22px but the 16px app value is internally consistent. If pursued, do it as a token change (`--r-md: 22px`) with a kid-module smoke test. |
| C2 | Rewards grid responsive gap (14 → clamp 16-28) | Include in Wave B (B6) or defer to Wave C — low risk either way. |
| C3 | Approval button horizontal padding tightening on desktop | Defer; current full-width buttons work and no regression reported. |

---

## 3. Implementation Strategy

**Chosen approach: Token-first (CSS class edits) + minimal component touches.**

Rejected alternatives:
- *Inline Tailwind utility swap* — the codebase recently moved **away** from inline styles (`98e69a7`, `d0f283a`); reintroducing utilities would fight the direction of travel.
- *ViewComponent API refactor* (e.g., add `size:` slots) — over-engineering for a <10 px, <5 component delta.
- *Single mega-commit* — bad for bisect; the 3 Wave-A rules and 6 Wave-B component edits should land as distinct atomic commits so any visual regression can be pinpointed.

**Rule of thumb per file:** if the change is a magic number that is repeated in more than one place, edit the CSS class; if it is a one-shot, edit the ERB.

---

## 4. Risk Assessment

| Wave / item | Risk | Blast radius | Mitigation |
|---|---|---|---|
| A1 stat-icon-tile radius (2px delta) | **LOW** | Parent dashboard only — 4 stat cards | Visual diff check on `/parent` |
| A2 chip-sm (sizing + weight bump) | **MEDIUM** | Every `.chip-sm` use: approval_row (2), mission_list_row, reward_catalog_card, and any activity/summary chips | Grep for `chip-sm` before/after; Capybara snapshot on approvals + missions |
| A3 `.nav-item` mobile base (radius + active bg) | **MEDIUM** | Kid layout also uses `.nav-item` (bottom-nav). Desktop parent override at :1017 is scoped by `body.parent-layout .side-nav` so unaffected. **Kid bottom-nav inherits the base rule.** | Before committing, verify kid bottom-nav still reads correctly or scope A3 under `body.parent-layout` instead of the base rule. **Recommended:** scope under `body.parent-layout` to avoid cross-module regression. |
| B1 stat_card cleanup | LOW | Parent dashboard | — |
| B2 kid_progress_card avatar 60→56 | LOW | Dashboard + profiles index | — |
| B3 approval_row checkbox + gap | LOW | Approvals page only | Bulk-select Stimulus controller keys off `data-bulk-select-target`, not sizing — safe |
| B4 dashboard recent-activity padding | LOW | Single view | — |
| B5/B6 chip-sm application | LOW | Covered by Capybara after A2 | — |
| C1 global card radius (if pursued) | **HIGH** | All cards, both modules | Separate phase; visual QA checklist |

### Hidden risk called out

**A3 collision with kid bottom-nav.** The base `.nav-item` rule at line 537 is shared between parent top nav (mobile) and kid bottom nav. The inventory described this as "parent nav partial" and missed the cross-module coupling. Recommend scoping A3 under `body.parent-layout .nav-item` (or the existing `.side-nav` / a new `.top-nav` selector) rather than editing the global rule. This preserves kid UX and stays within the spirit of the audit ("parent sidebar active state").

---

## 5. Test Coverage Plan

The project uses RSpec + Capybara (no visual-regression snapshot tooling today). Coverage is behavioral, not pixel — so the test plan is "don't break the rendered HTML contract" plus manual visual QA for pixel deltas.

| Wave | Automated | Manual visual QA |
|---|---|---|
| A1 | No new spec — rule change, no DOM contract change | Diff `/parent` dashboard before/after |
| A2 | Existing approvals / missions specs must still pass (they assert chip text, not size). If no chip-presence spec exists for `mission_list_row`, add one: "renders `.chip-sm` with category label". | Screenshot approvals row + missions list |
| A3 | Add request spec (if missing) asserting `.side-nav .nav-item.active` present on current path. Keeps the active-state contract. | Navigate through all 6 parent sections on mobile + desktop |
| B1–B6 | Component spec already covers render; extend assertions where a measurable attribute changes (e.g., avatar `width:56px` inline in kid_progress_card). | Dashboard + approvals + profiles + rewards screenshot pass |
| C1 (if done) | Full suite + kid module smoke | Full visual QA |

**Suggested new/updated specs (budget: <30 min):**
- `spec/components/ui/kid_progress_card_component_spec.rb` — assert avatar `width: 56px` in rendered HTML.
- `spec/components/ui/approval_row_component_spec.rb` — assert checkbox `width: 20px`.
- `spec/components/ui/mission_list_row_component_spec.rb` — assert `.chip-sm` class applied.
- `spec/system/parent/navigation_spec.rb` — active nav state renders with `primary-soft` bg (assert via class presence, not computed style).

No new tooling required. Visual-regression tooling (Percy/Chromatic) is out of scope for this phase; revisit if C1 is pursued.

---

## 6. Estimated Scope

| Wave | Files | Commits | Effort |
|---|---|---|---|
| A (tokens) | 1 | 1 | ~20 min |
| B (components) | 6 | 4–6 | ~90 min |
| Test updates | 3–4 | bundled with B | ~30 min |
| Manual QA | — | — | ~30 min |
| **Total (A + B + tests)** | **~10** | **5–7** | **~3 h** |
| C1 global card radius | ~1 CSS + wide QA | 1 | separate phase |

File count matches the inventory's "Files Requiring Changes" table minus the already-resolved `.eyebrow` entry.

---

## 7. Implementation Readiness

**Ready to start Phase 4** once the four consolidation corrections in §1 are acknowledged. Recommended entry point: Wave A as a single commit, then Wave B components in priority order (B3 approvals → B1 stat_card → B4 dashboard → B2 kid_progress_card → B5/B6 chips).

**Blocked on:** nothing.

**Open decisions kicked to implementer:**
1. Scope A3 under `body.parent-layout` vs keep global? **Recommendation: scope it.**
2. Pursue C1 (global card radius 22px) now or defer? **Recommendation: defer.**
3. Rewards responsive grid gap — include or defer? **Recommendation: include in B6, low cost.**

---

## 8. Adjustments to the Consolidation

Apply before Phase 4 kickoff:
1. Strike the `.eyebrow` letter-spacing row from Dashboard + Activity Logs tables (already 0.24em).
2. Rewrite the `.stat-icon-tile` row: "radius 12px → 10px" (not "add rule").
3. Rewrite the `.chip-sm` row: "update size 10→11 / padding 3/9→4/10 / letter-spacing 0.12→0.08 / weight 600→800" (not "verify").
4. Narrow the sidebar nav row: scope is the base `.nav-item` rule (mobile surfaces), not the already-correct desktop `.side-nav` override.

With those edits, the inventory becomes an accurate Phase 4 work order.

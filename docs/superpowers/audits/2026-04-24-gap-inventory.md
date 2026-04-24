# Parent UI Gap Inventory — Consolidated from Audit

**Date:** 2026-04-24  
**Source:** Audit findings at `docs/superpowers/audits/2026-04-24-parent-ui-pixel-perfect-audit.md`  
**Status:** Ready for Phase 3 (Opus refactor plan review)

---

## Dashboard (PRIORITY: HIGH)

| Detail | Current | Target | Impact | Files |
|--------|---------|--------|--------|-------|
| **Spacing:** Stat icon tile radius | 16px (--r-md) | 10px | Icons appear slightly too rounded | `app/components/ui/stat_card/component.html.erb` |
| **Typography:** Eyebrow letter-spacing | 0.12em | 0.24em | Stat labels feel cramped | `.eyebrow` class in design_system.css |
| **Sizing:** Avatar consistency | 60px (inconsistent) | 56px | Large avatars inconsistent across kid_progress_card vs other components | `app/components/ui/kid_progress_card/component.html.erb` |

---

## Sidebar Navigation (PRIORITY: HIGH)

| Detail | Current | Target | Impact | Files |
|--------|---------|--------|--------|-------|
| **Spacing & Colors:** Active nav state | Purple full bg (#7C3AED), white text, 999px radius | Soft lilac bg (#EDE9FE), dark text, 14px radius | Active state too heavy/pill-like vs reference | Parent nav partial (location TBD) |
| **Spacing:** Nav item padding | To be measured | 10-12px standard | Verify alignment with reference padding | Parent nav partial |

---

## Approvals Queue (PRIORITY: HIGH)

| Detail | Current | Target | Impact | Files |
|--------|---------|--------|--------|-------|
| **Sizing:** Checkbox dimensions | 18px | 20px | Slightly smaller than reference (minor accessibility) | `app/components/ui/approval_row/component.html.erb` |
| **Spacing:** Row internal consistency | Variable (12px / 8px gaps) | Uniform 10-12px | Spacing slightly inconsistent | `app/components/ui/approval_row/component.html.erb` |

---

## Task/Mission Management (PRIORITY: HIGH)

| Detail | Current | Target | Impact | Files |
|--------|---------|--------|--------|-------|
| **Sizing & Typography:** Chip sizing (.chip-sm) | Not verified — assuming 12px? | 11px, 4px 10px padding, 0.08em letter-spacing | Frequency/category badges may be oversized or undersized | `app/components/ui/mission_list_row/component.html.erb`, `app/views/parent/global_tasks/index.html.erb` |
| **Spacing:** Filter chip margin-bottom | 14px | 14px | ✅ Match — no action | — |

---

## Profiles (PRIORITY: MEDIUM)

| Detail | Current | Target | Impact | Files |
|--------|---------|--------|--------|-------|
| **Sizing:** Avatar in kid_progress_card | 60px with 4px border | 56px with 4px border | Consistency across dashboard + profile cards | `app/components/ui/kid_progress_card/component.html.erb` |
| **Spacing:** Color band height | 48px | 48px | ✅ Match — no action | — |
| **Spacing:** Stat box padding | 10px 12px | 10px 12px | ✅ Match — no action | — |

---

## Rewards (PRIORITY: MEDIUM)

| Detail | Current | Target | Impact | Files |
|--------|---------|--------|--------|-------|
| **Spacing:** Grid gap responsive | 14px | 16-28px responsive | Slight gap tightness on smaller screens | `app/views/parent/rewards/index.html.erb` |
| **Sizing & Typography:** Chip sizing (.chip-sm) | Not verified | 11px, 0.08em letter-spacing | Category label sizing needs verification | `app/components/ui/reward_catalog_card/component.html.erb` |
| **Sizing:** Card border-radius | 16px (--r-md) | 22px (reference @Stars) | Cards slightly less rounded than reference | `.card` CSS rule in design_system.css |

---

## Settings (PRIORITY: LOW)

| Detail | Current | Target | Impact | Files |
|--------|---------|--------|--------|-------|
| **Spacing:** Card padding | 20px | 20px | ✅ Match — no action | — |
| **Spacing:** Select padding | 6px 10px | 6px 10px | ✅ Match — no action | — |
| **Sizing:** Form control sizing | Standard | Standard | ✅ Match — no action | — |

---

## Activity Logs (PRIORITY: MEDIUM)

| Detail | Current | Target | Impact | Files |
|--------|---------|--------|--------|-------|
| **Typography:** Eyebrow letter-spacing | 0.12em | 0.24em | "Ganhou"/"Gastou" labels feel cramped | `.eyebrow` class in design_system.css |
| **Spacing:** Activity card padding | 4px top/bottom (tight) | 14px standard | Recent activity section on dashboard feels cramped | `app/views/parent/dashboard/index.html.erb` |
| **Sizing:** Icon disc sizing | 40px (summary) / 48px (list) | Reference shows 48px (list), 22-26px icons inside | Proportions correct; no action | — |

---

## Invitations & Other Views (PRIORITY: LOW)

| Detail | Current | Target | Impact | Files |
|--------|---------|--------|--------|-------|
| General spacing + typography | Mostly aligned | Reference | No major gaps found | `app/views/parent/invitations/` |

---

## ViewComponent Summary

| Component | Status | Issues | Priority |
|-----------|--------|--------|----------|
| `approval_row` | Mostly aligned | Checkbox 18px → 20px, row spacing inconsistency | HIGH |
| `stat_card` | Missing CSS rule | Icon tile border-radius needs 10px rule | HIGH |
| `kid_progress_card` | Mostly aligned | Avatar 60px → 56px, stat box padding OK | MEDIUM |
| `activity_row` | Mostly aligned | Eyebrow letter-spacing (shared) | HIGH |
| `mission_list_row` | Needs verification | Chip-sm sizing verification | HIGH |
| `reward_catalog_card` | Needs verification | Chip-sm sizing verification, card radius | MEDIUM |

---

## Consolidated Priority Order for Refactoring

### Phase 3a: Foundation Fixes (Required for all components)
1. **Update eyebrow letter-spacing** — Global `.eyebrow` class: 0.12em → 0.24em
   - Impacts: Dashboard (stat labels), Activity logs ("Ganhou"/"Gastou")
   - File: `app/assets/stylesheets/design_system.css`
   - Scope: 1 CSS class change

2. **Add stat-icon-tile CSS rule** — New rule for `.stat-icon-tile`
   - Current: Inline styles only
   - Target: border-radius: 10px, background: var(--c-category-tint)
   - File: `app/assets/stylesheets/design_system.css`
   - Scope: 1 new CSS rule

3. **Verify/fix .chip-sm sizing** — Check if 11px applied everywhere
   - Components: mission_list_row, reward_catalog_card, approval_row
   - If missing: Add/update `.chip-sm` rule to 11px, 4px 10px padding, 0.08em letter-spacing
   - File: `app/assets/stylesheets/design_system.css`

### Phase 3b: Component Updates (By Priority)
1. **Dashboard & Profile Cards** (HIGH)
   - Stat card: Use `.stat-icon-tile` rule (instead of inline)
   - Kid progress card: Reduce avatar from 60px → 56px
   - Recent activity: Increase padding from 4px → 14px

2. **Sidebar Navigation** (HIGH)
   - Update active state: Purple pill → soft lilac, 14px radius, dark text
   - Verify padding consistency

3. **Approval Queue** (HIGH)
   - Fix checkbox sizing: 18px → 20px
   - Standardize row spacing to 10-12px uniform

4. **Rewards Grid** (MEDIUM)
   - Consider responsive gap adjustment (14px → 16-28px)
   - Verify chip-sm application

5. **Card Border-Radius Strategy** (MEDIUM)
   - Decision: Update `.card` global rule (16px → 22px) — BREAKING
   - OR: Override per component
   - Recommend: Component-by-component override (safer)

### Phase 3c: Validation & Testing
- Add/update RSpec + Capybara visual assertions
- Test responsive breakpoints
- Verify no visual regressions on kid module

---

## Implementation Strategy Recommendation for Phase 3 (Opus)

**Approach:** Token-first, then component-specific fixes
1. Start with `.eyebrow` letter-spacing (lowest risk, highest impact)
2. Add `.stat-icon-tile` CSS rule (unblock dashboard)
3. Verify `.chip-sm` sizing (cross-component)
4. Component refactors in priority order (sidebar → approval → rewards)
5. Border-radius strategy decision (separate ADR)

**Risk Assessment:**
- LOW RISK: Typography token updates (eyebrow, chip-sm)
- MEDIUM RISK: Component sizing (avatar 60→56px, sidebar active state)
- HIGH RISK: Global card border-radius change (breaking, wide impact)

**Test Coverage Plan:**
- Regression test each component after refactor
- Visual assertions on dashboard + approvals (most visible)
- Responsive grid testing (rewards, activity logs)

---

## Files Requiring Changes (Summary for Opus)

| File | Changes | Complexity |
|------|---------|------------|
| `app/assets/stylesheets/design_system.css` | Add `.stat-icon-tile`, verify `.chip-sm`, update `.eyebrow` | LOW |
| `app/components/ui/stat_card/component.html.erb` | Use `.stat-icon-tile` class (remove inline styles) | LOW |
| `app/components/ui/kid_progress_card/component.html.erb` | Reduce avatar 60px → 56px | LOW |
| `app/components/ui/approval_row/component.html.erb` | Checkbox 18px → 20px, standardize spacing | MEDIUM |
| `app/views/parent/dashboard/index.html.erb` | Activity card padding 4px → 14px | LOW |
| Parent nav partial (location TBD) | Sidebar active state refactor | MEDIUM |
| `app/components/ui/mission_list_row/component.html.erb` | Verify chip-sm application | LOW |
| `app/components/ui/reward_catalog_card/component.html.erb` | Verify chip-sm, consider grid gap | MEDIUM |

---

**Status:** ✅ CONSOLIDATION COMPLETE — Ready for Opus Phase 3 review

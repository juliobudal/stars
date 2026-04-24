# Parent Module UI Pixel-Perfect Refinement Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Audit all parent view components (ERB + ViewComponent) against @Stars/pages/parent-* design references and refactor to pixel-perfect consistency across spacing, typography, colors, shadows, and sizing.

**Architecture:** Three-phase workflow:
1. **Audit phase (Haiku)** — Scan all 24 parent views + existing components; document pixel deviations vs @Stars refs
2. **Consolidation** — Synthesize audit into structured gap inventory by component + detail type
3. **Plan review (Opus)** — Opus reviews consolidation + proposes refactor sequence + priority

**Tech Stack:** Rails ViewComponents · Tailwind 4 · Design tokens (CSS vars) · RSpec + Capybara for regression

---

## Phase 1: Initial Audit (Haiku Subagent)

### Task 1: Audit Parent Views Against @Stars References

**Files to examine:**
- Parent views: `app/views/parent/{dashboard,approvals,global_tasks,profiles,rewards,settings,activity_logs,invitations}/`
- Reference: @Stars/pages/parent-* (dashboard, approvals, task-list, profile, rewards, settings)
- Output: Detailed findings document

**Audit checklist (what Haiku must report):**

- [ ] **Dashboard comparison** (`parent/dashboard/index.html.erb` vs @Stars/pages/parent-dashboard)
  - Spacing: header gap, card padding, section margins
  - Typography: heading font-size/weight, body text treatment
  - Colors: background, card backgrounds, text contrast
  - Shadows: depth on cards, hover states
  - Sidebar/nav structure if present

- [ ] **Approvals queue** (`parent/approvals/index.html.erb` vs @Stars/pages/parent-approvals)
  - List item spacing (row height, internal padding)
  - Action button sizing + spacing
  - Badge styling (color, font-size, padding)
  - Pending vs completed visual state

- [ ] **Task management** (`parent/global_tasks/index.html.erb` + `_form.html.erb` vs @Stars/pages/parent-tasks)
  - Task card layout (spacing, sizing)
  - Form field spacing + label styling
  - Button sizing + primary/secondary styling
  - Category/tag styling

- [ ] **Profiles** (`parent/profiles/` views vs @Stars/pages/parent-profiles)
  - Profile card dimensions + padding
  - List styling + spacing between items
  - Avatar sizing
  - Edit form layout

- [ ] **Rewards** (`parent/rewards/` views vs @Stars/pages/parent-rewards)
  - Reward tile sizing + spacing
  - Point display styling
  - Form layout matching task form

- [ ] **Settings** (`parent/settings/show.html.erb` vs @Stars/pages/parent-settings)
  - Card layout (spacing, borders, shadows)
  - Section grouping
  - Form controls alignment

- [ ] **Activity logs** (`parent/activity_logs/index.html.erb`)
  - Log entry styling + spacing
  - Timeline/chronological visual if present
  - Icon + text pairing

- [ ] **Existing ViewComponents** — Any parent-scoped components in `app/components/`
  - Audit for alignment with above standards

**Deliverable:** Structured findings document listing:
```
## Component: Dashboard
### Spacing
- [GAP FOUND] Header nav gap is 16px, should be 18px per @Stars
- [GAP FOUND] Card padding is 20px, should be 28px
- [OK] Section margins match

### Typography
- [OK] H1 font-size matches
- [GAP FOUND] Body text is 14px, should be 15px

### Colors
- [OK] Background matches

### Shadows
- [GAP FOUND] Card shadow too strong, should be softer

...
```

---

## Phase 2: Consolidation (You)

### Task 2: Synthesize Audit Findings into Gap Inventory

**Input:** Haiku's audit findings document

**Output:** Structured gap list organized by:
- **Component** (dashboard, approvals, etc.)
- **Detail type** (spacing, typography, color, shadow, sizing)
- **Priority** (blocker if dashboard, high if approvals/task-list, medium if settings)
- **Pixel change** (16px → 18px, etc.)

Example structure:
```markdown
## Dashboard (PRIORITY: BLOCKER)
- Spacing: header gap 16→18px, card padding 20→28px
- Typography: body 14→15px
- Shadows: card shadow softening needed
- Layout: confirm nav structure matches @Stars

## Approvals Queue (PRIORITY: HIGH)
- Spacing: list row height consistency
- Typography: badge font adjustments
- Sizing: action button dimensions

...
```

---

## Phase 3: Opus Plan Review (Opus Subagent)

### Task 3: Opus Reviews Consolidation + Proposes Refactor Plan

**Input:** Consolidated gap inventory from Task 2

**Opus must deliver:**
- [ ] Refactor sequence (which components first, dependencies)
- [ ] Implementation strategy (design tokens vs inline Tailwind vs component refactoring)
- [ ] Risk assessment (regression test coverage needed, complexity per component)
- [ ] Estimated scope per component
- [ ] Approval/sign-off on consolidation accuracy

**Deliverable:** Refactor strategy document with:
- Prioritized component order
- Token/class definitions needed
- Regression test coverage plan
- Implementation approach per component type

---

## Phase 4: Implementation (Post-Plan Approval)

### Task 4: Update Design Tokens + Utilities (If Needed)

**Files:**
- Modify: `app/assets/stylesheets/design_system.css`
- Modify: `app/components/ui/tokens.rb` (if using CSS vars)

- [ ] Add/update spacing tokens (padding, gap, margin standards)
- [ ] Ensure typography tokens exist (font-sizes, weights)
- [ ] Add shadow utility classes if missing
- [ ] Verify color palette completeness

### Task 5-N: Refactor Components by Priority

**Per component (dashboard → approvals → tasks → etc.):**

- [ ] Update spacing (padding, margins, gaps)
- [ ] Update typography (font-size, weight, line-height)
- [ ] Update colors (use tokens, not hardcoded)
- [ ] Update shadows (use token utilities)
- [ ] Add/update regression tests (Capybara visual assertions)
- [ ] Commit atomic change per component

---

## Subagent Dispatch Sequence

```
YOU (initial request)
  ↓
[Haiku] Task 1: Audit all parent views
  ↓ (returns findings doc)
[You] Task 2: Consolidate findings
  ↓ (returns gap inventory)
[Opus] Task 3: Review + propose refactor plan
  ↓ (returns refactor strategy)
[You/Subagents] Task 4-N: Implement refactors
  ↓ (atomic commits per component)
DONE
```

---

## Success Criteria

- [ ] All parent views visually match @Stars/pages/parent-* references (pixel-verified)
- [ ] Spacing consistent (headers, cards, sections, list items)
- [ ] Typography consistent (headings, body, labels, badges)
- [ ] Colors use design tokens (no hardcoded hex in views)
- [ ] Shadows standardized across cards
- [ ] RSpec + Capybara regression tests pass
- [ ] No visual regressions on kid module
- [ ] Zero unfixed gaps from audit

---

## Notes

- Dashboard is the showcase — prioritize it first
- @Stars reference is source of truth for pixel measurements
- Changes should be backwards-compatible (existing tests still pass)
- If new tokens are needed, define them in Phase 4 before refactors

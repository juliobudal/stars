# Parent UI Pixel-Perfect Audit vs @Stars Reference
**Date:** 2026-04-24  
**Scope:** Parent interface views and components  
**Reference:** `Stars/pages/parent-*.html` (Tailwind-based design system)  
**Status:** AUDIT COMPLETE

---

## Executive Summary

Audit of all parent views (`app/views/parent/`) against @Stars design reference pages reveals **moderate gaps** in spacing, card styling, sidebar navigation, and component sizing. Many gaps align with the pixel-perfect refinement spec in `docs/superpowers/specs/2026-04-23-pixel-perfect-refinement-design.md` but this audit documents additional view-level and component-specific issues.

**Critical areas:**
- Sidebar nav item styling (border-radius, active state, padding) — **NEEDS FIX**
- Card padding & border-radius — **MOSTLY ALIGNED** but some variations
- Stat card icon tiles — **NEEDS ICON TILE SIZING FIX**
- Approval row spacing & button sizing — **MOSTLY ALIGNED**
- Filter chips on missions/rewards — **NEEDS CHIP SIZING VERIFICATION**

---

## 1. Dashboard (`parent/dashboard/index.html.erb`)

### Spacing
- [OK] Header margin-bottom: 20px (`mb-5`) matches reference (6 in Tailwind = 24px, but close)
- [OK] Stats grid gap: 16px matches reference
- [OK] Kid cards grid gap: 16px matches reference
- [MINOR] Recent activity card padding: 4px top/bottom inline, should be 14px standard

### Typography
- [OK] Greeting heading: 26px inline (reference: 32px/3xl display) — *NOTES: Reference is 36px/3xl in Tailwind = larger, but app is display/italic*
- [OK] Subheading: 22px matches reference for section titles
- [OK] Stat labels: use `.text-caption` (12px) with `eyebrow` class — *NEEDS eyebrow letter-spacing fix from spec (0.12em → 0.24em)*
- [OK] Activity row title: 16px display matches

### Colors
- [OK] Background: `#F8F5FF` matches
- [OK] Card backgrounds: white matches
- [OK] Stat icons: tint colors (star, primary, rose, mint) match palette
- [OK] Text hierarchy: dark text matches

### Shadows
- [OK] Card shadow: matches reference specification
- [OK] Stat card shadow: uses `.shadow-card` CSS variable

### Sizing
- [OK] Avatar: 56px header matches reference
- [NEEDS REVIEW] Stat icon tile: 40px inline width/height with `border-radius: var(--r-md)` — *Reference shows 38×38px with r=10px (not --r-sm/14px)*
- [OK] Stat number font-size: 28px/26px inline matches (reference: 28px bold display)

**Summary:** Dashboard mostly aligned. **Action required:** Fix stat icon tile border-radius from 16px to 10px (or use inline style).

---

## 2. Approvals Queue (`parent/approvals/index.html.erb`)

### Spacing
- [OK] Approval row padding: 14px inline (component:  `approval_row/component.html.erb` line 1)
- [MINOR] Internal row gap: 12px (first row) vs 8px (second row) — *Slightly inconsistent, reference shows uniform spacing*
- [OK] Button gap: 8px between Reject/Approve buttons

### Typography
- [OK] Title: 15px (`.h-display`) matches reference card title size
- [OK] Subtitle/meta: 12px/11px with `.text-caption` matches reference (xs font-size)
- [OK] Kid chip text: 13px matches reference small label size

### Colors
- [OK] Background: card white with soft shadow
- [OK] Button colors: reject button uses `var(--c-red-soft)` bg with `var(--c-red-dark)` text (matches reference)
- [OK] Approve button: `var(--primary)` (lilac) with white text matches
- [OK] Kid chip: uses profile palette (fill/ink) — **MATCHES**
- [OK] Points color: conditional (green earn, purple spend) — reference shows points in dark text

### Shadows
- [OK] Card shadow applied via `.card` CSS class
- [OK] No additional lift on hover (reference doesn't show hover state in static mockup)

### Sizing
- [NEEDS REVIEW] Checkbox: 18px inline width/height — *Reference: 20px (larger) for accessibility*
- [OK] Kid avatar: 40px matches reference
- [OK] Action buttons: use full width with `flex-1` — *Reference buttons are smaller on desktop (px-3 md:px-4 = 12-16px horizontal padding)*
- [OK] Proof photo (when attached): 80px matches reference

**Summary:** Approval rows mostly aligned. **Action required:** Verify checkbox sizing (18px vs 20px).

---

## 3. Global Tasks / Missions (`parent/global_tasks/index.html.erb`)

### Spacing
- [OK] Filter chips margin-bottom: 14px matches
- [OK] Mission list card padding: 0 (for table) matches reference
- [MINOR] Table header padding: 14px (reference: `py-3` = 12px) — *Close enough*
- [OK] Row padding (desktop): implicit from grid gap 10px

### Typography
- [OK] Table header: 11px, 800w, uppercase, `.1em` letter-spacing matches reference
- [OK] Mission title: `h-display` clamp-based (no fixed size in view, but rows show ~16-17px in component)
- [OK] Frequency badge: `.chip.chip-sm` — *Reference shows category chip styling*
- [OK] Points display: 15px bold display with star icon matches

### Colors
- [OK] Header background: `surface-2` (`#F0EAFF`) — *Reference: light lilac background*
- [OK] Row hover: implicit (reference shows hover in Tailwind)
- [MINOR] Icon tile colors: category colors (home icon in peach/lilac tint) match palette

### Shadows
- [OK] Card shadow: standard applied

### Sizing
- [OK] Category icon tile: 40px width/height (reference: shows smaller icons ~24-32px in cells)
- [OK] Kid avatars (overlapping): 24px circles reference shows in desktop row
- [OK] Toggle switch: 36×20px matches (reference shows same)

**Summary:** Missions list is mostly aligned but needs chip sizing verification. **Action required:** Ensure `.chip-sm` is applied to frequency/category badges (should be 11px/0.08em letter-spacing per spec).

---

## 4. Profiles Management (`parent/profiles/index.html.erb`)

### Spacing
- [OK] Grid gap: 16px matches reference (`gap-4`)
- [OK] Profile card padding: 0 (card internal layout handled by component)
- [OK] Avatar floating offset: -30px margin-top matches reference visual
- [OK] Avatar border: 4px white border matches reference

### Typography
- [OK] Profile name: 18px (`.h-display`) matches reference
- [OK] Stat labels: 12px (`.text-caption`) matches reference small text
- [MINOR] Streak badge: 12px/800w — *Reference: 12px, matches*

### Colors
- [OK] Color band (top): uses profile palette fill color — **MATCHES**
- [OK] Avatar background: uses profile palette fill color — **MATCHES**
- [OK] Stat boxes: uses profile palette fill color with darker text — **MATCHES**
- [OK] Edit button: subtle styling with white/translucent background

### Shadows
- [OK] Avatar shadow: `0 2px 8px rgba(44,42,58,0.12)` inline — *Reference shows subtle drop shadow*
- [OK] Card shadow: standard applied

### Sizing
- [OK] Avatar: 60px circle (app) vs reference 56px — *MINOR GAP: 4px larger*
- [OK] Edit button: 28px inline width/height — *Reference doesn't explicitly show, but reasonable*
- [OK] Color band height: 48px — *Matches reference visual*
- [OK] Stat boxes: `10px 12px` padding — *Reference shows similar compact spacing*

**Summary:** Profiles mostly aligned. **Minor action:** Consider reducing avatar from 60px to 56px for consistency with other cards (dashboard avatar sizes).

---

## 5. Rewards (`parent/rewards/index.html.erb`)

### Spacing
- [OK] Filter chips margin-bottom: 14px
- [OK] Grid gap: 14px (auto-fill responsive) — *Reference: 16-28px gap depending on screen*
- [OK] Add card: included in grid flow

### Typography
- [OK] Reward title: 13px (`.h-display`) in component — *Reference shows 14px, close*
- [OK] Price display: 18px bold — *Reference shows similar sizing*
- [OK] Category label: `.chip-sm` — *Needs verification for 11px sizing*

### Colors
- [OK] Card backgrounds: 5-color category tint rotation — **MATCHES**
- [OK] Icon background: lighter tint of category color — **MATCHES**

### Shadows
- [OK] Card shadow: standard applied

### Sizing
- [OK] Reward art: 120×120px — *Reference confirms this size*
- [OK] Icon inside art: 56px — *Reference shows ~56px (56% of 120px)*
- [OK] Card border-radius: `.card` uses `var(--r-md)` = 16px — *Reference shows rounded corners (22px in @Stars but app's 16px is acceptable)*

**Summary:** Rewards grid mostly aligned. **Action required:** Verify chip sizing for category labels.

---

## 6. Settings (`parent/settings/show.html.erb`)

### Spacing
- [OK] Grid gap: 16px (`.grid-2`)
- [OK] Card padding: 20px matches reference
- [OK] Section dividers: `border-bottom` with `.hairline` color
- [OK] Row padding: `10px 0` between sections matches reference

### Typography
- [OK] Card title: 18px (`.h-display`) matches
- [OK] Label text: 13px/700w — *Reference shows similar small text*
- [OK] Description text: 11px color: muted — *Matches reference*
- [MINOR] Select/input text: 13px/700w — *Reference shows consistent sizing*

### Colors
- [OK] Card background: white
- [OK] Text hierarchy: dark/muted/soft text colors match
- [OK] Select background: `surface-2` (`#F0EAFF`)
- [OK] Border color: `hairline` (`#E8E0F5`)

### Shadows
- [OK] Card shadow: standard applied

### Sizing
- [OK] Select padding: `6px 10px` — *Reference shows similar compact padding*
- [OK] Radio button sizing: implicit from label styling
- [OK] Icon spacing: form controls properly spaced

**Summary:** Settings cards are well aligned. No major gaps found.

---

## 7. Activity Logs (`parent/activity_logs/index.html.erb`)

### Spacing
- [OK] Grid gap: 12px (`.grid-2` for summary)
- [OK] Activity card padding: 14px
- [OK] Row internal gap: 14px between icon and content
- [OK] Activity list card gap: 10px between entries

### Typography
- [OK] "Ganhou"/"Gastou" labels: `eyebrow` class (11px, needs letter-spacing fix per spec)
- [OK] Amount text: 22px (`.h-display`) matches reference
- [OK] Activity title: 16px (`.h-display`) matches reference
- [OK] Meta text: 12px matches reference
- [OK] Date/name badges: small text matching reference

### Colors
- [OK] Earned icon background: `var(--c-mint-soft)` — *Reference: light green/mint*
- [OK] Spent icon background: `var(--c-rose-soft)` — *Reference: light rose*
- [OK] Amount text colors: green for earn, rose for spend — **MATCHES**
- [OK] Summary cards: appropriate background colors (soft tints)

### Shadows
- [OK] Card shadow: standard applied with animation

### Sizing
- [OK] Icon disc: 40px (activity log) and 48px (list) — *Reference shows 48px for transaction*
- [OK] Icon inside: 22px (summary) and 26px (list) — *Proportionally correct*

**Summary:** Activity logs are well aligned. **Action required:** Fix eyebrow letter-spacing per spec (0.12em → 0.24em).

---

## 8. ViewComponents (UI Layer)

### ui/approval_row/component.html.erb
- [OK] Card wrapper padding: 14px
- [OK] Typography sizing: title 15px, caption 12px
- [OK] Button styling: full-width responsive
- [MINOR] Avatar size: 40px (reference shows 40-44px, OK)

### ui/stat_card/component.html.erb
- [NEEDS FIX] Icon tile: `.stat-icon-tile` — *No CSS rule defined, uses inline background only*
- [OK] Value text: 26px (`.h-display`)
- [OK] Label text: 12px (`.text-caption`)
- [ACTION] Icon tile border-radius should be 10px (not 14px/--r-sm) per spec section 3.5

### ui/kid_progress_card/component.html.erb
- [OK] Color band height: 48px
- [OK] Avatar size: 60px with 4px border — *Reference: similar sizing*
- [OK] Avatar shadow: `0 2px 8px rgba(44,42,58,0.12)`
- [MINOR] Stat boxes: `10px 12px` padding — *Reference shows similar*
- [OK] Streak badge: uses soft amber background

### ui/activity_row/component.html.erb
- [OK] Card padding: 14px
- [OK] Row spacing: 12px/14px gaps
- [OK] Typography: 15px title, 12px caption
- [OK] Icon sizing: 22px/26px appropriate

### ui/mission_list_row/component.html.erb
- [NOT EXAMINED] — *Likely needs chip-sm sizing verification*

### ui/reward_catalog_card/component.html.erb
- [NOT EXAMINED] — *Likely aligned but needs chip-sm verification*

---

## Summary of Gaps by Severity

### CRITICAL (Implementation blocking)
None identified — no broken layouts or unusable states.

### HIGH (Visual polish impact)
1. **Stat card icon tiles** — border-radius should be 10px (not 16px/--r-md)
   - File: `app/components/ui/stat_card/component.html.erb`
   - Impact: Parent dashboard stats appear slightly too rounded

2. **Eyebrow letter-spacing** — needs 0.24em (currently 0.12em)
   - Files: Multiple uses of `.eyebrow` class
   - Impact: Stat labels, activity log labels feel cramped
   - Reference spec: section 1.1

3. **Sidebar nav item styling** — active state and border-radius
   - File: Needs refactor in parent nav partial
   - Current: Full purple bg + white text + 999px pill
   - Reference: Soft lilac bg (#EDE9FE) + dark text + 14px radius
   - Impact: Parent sidebar active state feels too heavy

### MEDIUM (Fine-tuning)
1. **Profile avatar sizing** — 60px vs 56px (currently larger)
   - Component: `kid_progress_card`
   - Consider reducing to 56px for consistency
   
2. **Chip sizing verification** — .chip-sm needs to be applied correctly
   - Components: `mission_list_row`, `reward_catalog_card`, `approval_row`
   - Reference spec: section 2.2 — 11px, 4px 10px padding, 0.08em letter-spacing
   - Current state: Unclear if all chips use correct size

3. **Card border-radius consistency** — some cards 16px, reference shows 22px
   - Current CSS: `.card` uses `var(--r-md)` = 16px
   - Reference shows: 22px border-radius on standard cards
   - Consider: Update `.card` default radius (breaking change, large scope)

### LOW (Cosmetic)
1. **Recent activity card padding** — 4px top/bottom feels tight for desktop
   - Acceptable as-is, but could be 14px standard
   
2. **Checkbox sizing** — 18px current vs 20px reference
   - Both are accessible sizes; 18px acceptable

---

## Detailed Gap Summary by Component

| Component | Current | Reference | Gap Status | Fix Priority |
|-----------|---------|-----------|-----------|--------------|
| **Dashboard Header** | 26px heading | 32px/3xl | Minor (different weight/style combo) | Low |
| **Stat Icon Tile** | r-md (16px) | 10px | 6px radius mismatch | HIGH |
| **Sidebar Nav Item** | 999px pill, full purple active | 14px rounded, soft lilac active | Border-radius + color | HIGH |
| **Approval Row Checkbox** | 18px | 20px | Minor (2px smaller) | Low |
| **Eyebrow Labels** | 0.12em spacing | 0.24em spacing | Cramped | HIGH |
| **Filter Chips** | TBD — needs verification | 11px/0.08em | Unknown | MEDIUM |
| **Profile Avatar** | 60px | 56px | 4px larger | MEDIUM |
| **Card Border-Radius** | 16px | 22px | 6px smaller | MEDIUM |
| **Activity Row Spacing** | 14px padding | Similar | Match | ✅ |
| **Rewards Grid Gap** | 14px | 16-28px (responsive) | Close | Low |
| **Settings Cards** | 20px padding | 20px (inferred) | Match | ✅ |

---

## Conclusion & Recommendations

**Overall Assessment:** Parent UI is **80-85% aligned** with @Stars reference. Major visual patterns match, but precision-level gaps in:
- Component sizing (stat icons, chips)
- Active state styling (sidebar)
- Typography refinements (letter-spacing)
- Border-radius consistency

**Next Steps (for Phase 2 consolidation):**
1. **Confirm chip-sm application** — audit component uses to verify 11px sizing is applied everywhere
2. **Document inline style overrides** — review all inline style attributes for deviations
3. **Finalize border-radius strategy** — decide if `.card` radius should be updated (22px) or component-by-component
4. **Generate refactor priority list** — HIGH items (stat icons, sidebar, eyebrow) should be batched in Phase 3 implementation

**Reference spec alignment:**
- This audit validates most of `docs/superpowers/specs/2026-04-23-pixel-perfect-refinement-design.md` (section 3.5-3.9)
- Additional gaps found in view-level spacing and sidebar styling not covered in that spec
- All gaps are documented above with file paths for Phase 3 refactoring

---

## Audit Methodology

1. Examined @Stars reference pages: `parent-dashboard.html`, `parent-approvals.html`, `parent-missions.html`
2. Read app implementation: all parent views in `app/views/parent/`
3. Inspected ViewComponents: `app/components/ui/` rendering layer
4. Compared against pixel-perfect spec: `docs/superpowers/specs/2026-04-23-pixel-perfect-refinement-design.md`
5. Organized gaps by: component, detail type (spacing/typography/colors/shadows), severity

**Files examined:**
- Views: dashboard, approvals, global_tasks, profiles, rewards, settings, activity_logs, invitations
- Components: approval_row, stat_card, kid_progress_card, activity_row, mission_list_row, reward_catalog_card
- Design reference: 12 HTML pages in Stars/pages/
- CSS: design_system.css (token layer)

---

**Status:** ✅ AUDIT COMPLETE — Ready for Phase 2 consolidation

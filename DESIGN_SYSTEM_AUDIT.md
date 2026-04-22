# Design System Compliance Audit — LittleStars

**Status:** MVP UI/UX rebranding to Duolingo-inspired playful design system  
**Design Source:** `/design/` folder (React component library)  
**Target App:** Rails 8 fullstack with ViewComponent

---

## Design System Overview

**Core Principles:** Flat · Rounded · Blue-dominant (sky palette) · Playful · Duolingo-inspired

**Key Assets:**
- **Palettes:** Sky (default), Aurora (sunset), Galaxy (forest)
- **Mascot:** Lumi (golden star smiley)
- **Colors:** Hard saturated secondaries + soft pastel backgrounds
- **Shadows:** Chunky drop shadows (4px default)
- **Typography:** Nunito (display) + system fonts
- **Radius:** Generous (14-40px)
- **Animations:** Spring ease-in-out, confetti, pop-in

---

## Page-by-Page Audit

### **1. PROFILE SELECT** (Sessions#index)
**Design File:** `design/screens/profile-select.jsx`  
**Rails Route:** `sessions#index` → `/`  
**Narrative:** "Quem vai brilhar hoje?" — profile picker with Lumi mascot

**Components Needed:**
- [x] `BgShapes` (blue variant) — background decorative shapes
- [x] `Lumi` (excited mood) — mascot greeting
- [x] `KidAvatar` — profile card avatars (large, 96px)
- [x] `StarBadge` — kid balance display
- [x] Typography: Eyebrow + H1 display + subtitle
- [ ] **MISSING:** Colorized profile cards with 3px border + chunky shadow matching kid colors
- [ ] **MISSING:** Chip-based role badge ("Responsável" for parents, star count for kids)
- [ ] **MISSING:** Stagger animation on profile cards (`slideInCard` @ 50ms intervals)
- [ ] **MISSING:** Interactive button press feedback (translateY on mouseDown)

**Current Implementation:** Check `app/views/sessions/index.html.erb`

---

### **2. PARENT DASHBOARD** (Parent::Dashboard#index)
**Design File:** `design/screens/parent-dashboard.jsx`  
**Rails Route:** `parent/dashboard#index` → `/parent`  
**Narrative:** Hub for parent: KPI tiles, kid progress, action buttons

**Components Needed:**
- [x] `BgShapes` (blue variant)
- [x] `KidAvatar` (54px for "Visão Geral" section)
- [x] `StarBadge`
- [x] Progress track (visual bar for kid mission completion %)
- [x] Typography: H2 display, eyebrow, subtitle
- [ ] **MISSING:** Parent avatar (circular, 56px, primary-soft bg)
- [ ] **MISSING:** KPI stat cards (3-column grid: stars, awaiting count, kid count)
  - Star count + "Estrelinhas" label
  - Clock icon (peach) + pending count + "Aguardando" label
  - Users icon + kid count + "Crianças" label
- [ ] **MISSING:** "Visão Geral" kid cards
  - Color-coded border + shadow (from kid.color)
  - Avatar + name + balance (star + number)
  - Progress bar (height: 10px, color: kid's primary color)
  - "X/Y missões hoje" text
  - Stagger animation per kid
- [ ] **MISSING:** "Gerenciar" grid (auto-fill cards)
  - Tiles: Aprovações, Banco de Missões, Crianças, Lojinha, Extrato
  - Each with icon-tile (46×46, color-matched)
  - Color-coded border + shadow
  - Badge on Aprovações tile (red circle, top-right) if pending count > 0
  - Grid stagger animation
- [ ] **MISSING:** Logout button (btn-secondary btn-icon)

**Current Implementation:** Check `app/views/parent/dashboard/index.html.erb`

---

### **3. APPROVALS** (Parent::Approvals#index)
**Design File:** `design/screens/parent-approvals.jsx`  
**Rails Route:** `parent/approvals#index` → `/parent/approvals`  
**Narrative:** Approve/reject kid task submissions. Each kid section groups pending tasks.

**Components Needed:**
- [x] `BgShapes` (cool variant)
- [x] `TopBar` (back button, title "Aprovações", subtitle, waiting count chip on right)
- [x] `KidAvatar` (44px)
- [x] `EmptyState` (mint color, "Tudo em dia!")
- [x] `useToast`
- [ ] **MISSING:** `TopBar` implementation in Rails
  - Back button (btn-secondary btn-icon, arrow-left)
  - Title + subtitle stacked
  - Right slot: chip displaying pending count (peach bg, clock icon)
- [ ] **MISSING:** Kid approval sections
  - Kid avatar (44px) + name + chip ("N pedido(s)")
  - Cards per task:
    - Mission icon-tile (color from mission category)
    - Mission title + category chip (sm) + star reward
    - Two buttons below: Reject (btn-danger) + Approve (btn-success btn-lg)
    - Flash animation on approve/reject:
      - Approve: green border, mint-soft bg, success icon in circle
      - Reject: red border, coral-soft bg, shake animation
- [ ] **MISSING:** Toast notifications on approve/reject
  - Success: "+X ⭐ para {kid.name}!"
  - Error: "Devolvido pra refazer"
- [ ] **MISSING:** Screen transition animation (slideInR = right)

**Current Implementation:** Check `app/views/parent/approvals/index.html.erb`

---

### **4. MISSION BANK (ADMIN)** (Parent::GlobalTasks#index)
**Design File:** `design/screens/parent-bank.jsx`  
**Rails Route:** `parent/global_tasks#index` → `/parent/bank`  
**Narrative:** Create/edit missions. Modal form for mission details.

**Components Needed:**
- [x] `BgShapes` (blue variant)
- [x] `TopBar` (back button, title, subtitle, "+ Nova" button on right)
- [x] `useToast`
- [ ] **MISSING:** TopBar with right-slot button
  - "+ Nova" button (btn-primary) to open modal
- [ ] **MISSING:** Mission list cards
  - Icon-tile (52px, color from category)
  - Mission title + category chip (sm) + frequency chip (outlined)
  - Star count + icon on right
  - Chevron right
  - Border: outlined, stagger animation
- [ ] **MISSING:** Modal mission form
  - Title/subtitle
  - Icon picker (grid of icon options)
  - Title text field
  - Stars number field
  - Category select
  - Frequency select
  - Save + Remove (if existing) + Cancel buttons
- [ ] **MISSING:** Form fields styling per design system
  - Labels (uppercase, 13px, bold)
  - Inputs: 14px, r-md, border on focus + primary soft shadow

**Current Implementation:** Check `app/views/parent/global_tasks/`

---

### **5. KID PROFILES** (Parent::Profiles#index)
**Design File:** `design/screens/parent-kids.jsx`  
**Rails Route:** `parent/profiles#index` → `/parent/kids`  
**Narrative:** Manage kid profiles: add/edit name, icon, color, view balance.

**Components Needed:**
- [x] `BgShapes` (warm variant)
- [x] `TopBar` (back, title, subtitle, "+ Adicionar" button)
- [x] `KidAvatar` (64px per card)
- [x] `useToast`
- [ ] **MISSING:** TopBar with right-slot "+ Adicionar" button
- [ ] **MISSING:** Kid cards
  - Color-coded border + shadow (from kid.color)
  - Avatar (64px) + name
  - Two chips: star balance + mission count
  - Edit icon on right
  - Clickable → opens modal form
- [ ] **MISSING:** Modal kid form
  - Icon picker (face options)
  - Color picker (6-color grid)
  - Name text field
  - Save + Remove (if existing) + Cancel buttons

**Current Implementation:** Check `app/views/parent/profiles/` and kid form

---

### **6. REWARD SHOP ADMIN** (Parent::Rewards#index)
**Design File:** `design/screens/parent-shop-history.jsx` (first part)  
**Rails Route:** `parent/rewards#index` → `/parent/shop-admin`  
**Narrative:** Create/edit shop rewards. Similar to mission bank.

**Components Needed:**
- [x] `BgShapes`
- [x] `TopBar`
- [x] `useToast`
- [ ] **MISSING:** Same structure as Mission Bank
  - Reward list cards (icon-tile, title, cost in stars)
  - Modal form (icon picker, title, cost, category)

**Current Implementation:** Check `app/views/parent/rewards/`

---

### **7. ACTIVITY LOG / HISTORY** (Parent::ActivityLogs#index)
**Design File:** `design/screens/parent-shop-history.jsx` (second part)  
**Rails Route:** `parent/activity_logs#index` → `/parent/history`  
**Narrative:** Show earn/spend transaction history for selected kid.

**Components Needed:**
- [x] `TopBar`
- [ ] **MISSING:** History list
  - Transaction cards per entry:
    - Icon-tile (icon from activity)
    - Label + amount
    - "Earn" (green badge) or "Spend" (orange badge)
    - Timestamp
    - Grouped by kid or date-based display

**Current Implementation:** Check `app/views/parent/activity_logs/index.html.erb`

---

### **8. KID VIEW (HOME)** (Kid::Dashboard#index or similar)
**Design File:** `design/screens/kid-view.jsx`  
**Rails Route:** `kid#index` → `/kid` (or `/`)  
**Narrative:** Kid's task dashboard. Portal card showing balance + progress. Tabs: To Do / Awaiting.

**Components Needed:**
- [x] `BgShapes` (blue variant)
- [x] `Lumi` (mood changes: happy if todos, excited if todos empty)
- [x] `KidAvatar` (56px in header)
- [x] `BalanceChip` (large version: 28px star, 28px padding)
- [x] `useToast`
- [ ] **MISSING:** Header
  - KidAvatar (56px) + "Oi, {name}!" greeting + Lumi (56px, mood-driven)
- [ ] **MISSING:** Portal card (primary-colored, full-width)
  - Floating star icon in circle (white bg, animated)
  - "Meu Cofrinho" label + balance (44px font) + "estrelinhas guardadas"
  - "Lojinha" button (btn-star)
  - Progress section below:
    - "PROGRESSO DE HOJE" label + "X/Y ✨" count
    - Progress bar (white fill, white background with opacity)
- [ ] **MISSING:** Tabs section
  - Tab 1: "Pra Fazer" (target icon) — shows pending count in white pill badge
  - Tab 2: "Aguardando" (clock icon) — shows waiting count in peach pill badge
  - Active tab: primary bg, white text, shadow
- [ ] **MISSING:** Mission cards (two styles: bubble + ticket)
  - **Ticket style (default):**
    - Icon-tile (56px, category color) + title + category chip (sm) + star count
    - "Aguardando" chip if status=waiting
    - Clickable → opens modal
    - Stagger animation per card
  - **Bubble style (alt):**
    - Rounded bubble appearance (design shows more round/bubbly)
    - Same info layout
  - Disabled opacity + cursor if awaiting
- [ ] **MISSING:** Modal confirmation for task completion
  - Lumi (thinking mood, 76px)
  - Icon-tile (88px) for mission
  - Mission title + category chip + star reward chip
  - Subtitle: "Terminou essa missão? Um responsável vai confirmar."
  - Two buttons: "Ainda não" (btn-secondary) + "Terminei!" (btn-primary btn-lg)
  - **After submit:**
    - Success circle (success color, 96px) with check icon
    - "Enviado!" title + "Aguardando aprovação ✨"
- [ ] **MISSING:** Bottom navigation (sticky)
  - 4 buttons: Missões (target), Loja (bag), Extrato (scroll), Sair (logout)
  - Active button: primary bg, white text, shadow
  - Hover: lighter bg
- [ ] **MISSING:** Celebration/Confetti on mission complete (if applicable)

**Current Implementation:** Check Rails kid view files

---

### **9. KID SHOP** (Kid::Rewards#index or similar)
**Design File:** `design/screens/kid-shop.jsx`  
**Rails Route:** `kid/rewards#index` → `/kid/shop`  
**Narrative:** Kid browses shop rewards. Purchase flow with celebration.

**Components Needed:**
- [x] `BgShapes` (warm variant)
- [x] `TopBar` (back button, title, subtitle, balance chip on right)
- [x] `BalanceChip` (small version on right slot)
- [x] `useToast`
- [x] `Celebration` (confetti on purchase)
- [ ] **MISSING:** Reward grid (2 columns, stagger animation)
  - Circular icon area (84px, color-coded per item)
  - Reward title
  - Star cost chip (chip-star)
  - "Faltam X ⭐" text if can't afford
  - Disabled state: 55% opacity, grayscale filter
  - Hover/press feedback
- [ ] **MISSING:** Purchase modal
  - Item icon-tile (large)
  - Item title + cost in stars
  - Confirm button (btn-primary btn-lg)
  - **After purchase:**
    - Celebration effect (confetti + star burst)
    - Success feedback
    - Toast: success notification
- [ ] **MISSING:** Bottom navigation (same as KidView)

**Current Implementation:** Check Rails kid shop view

---

## Critical Styling Gaps

### **Typography**
- [ ] H1/H2/H3 display fonts (clamp sizing per design)
- [ ] Eyebrow (12px, uppercase, letter-spacing 0.12em, text-soft color)
- [ ] Subtitle (17px, text-muted, 600 weight)
- [ ] Button text (16px, 800 weight, display font)

### **Spacing & Layout**
- [ ] Space tokens: 4, 8, 12, 16, 24, 32, 40, 56px
- [ ] Flex utilities: `.row`, `.col`, `.center`, `.spacer`, `.noshrink`, `.wrap`
- [ ] Grid: `.grid-2`, `.grid-3`, `.grid-auto`

### **Buttons**
- [ ] `.btn-primary` — primary bg, white text, chunky shadow (0 4px 0 primary-2)
- [ ] `.btn-secondary` — white bg, text color, subtle shadow
- [ ] `.btn-ghost` — transparent, border, hover: light bg
- [ ] `.btn-danger`, `.btn-success`, `.btn-star` — color variants
- [ ] `.btn-icon` — 48px circle, no padding
- [ ] `.btn-lg`, `.btn-sm` — size variants
- [ ] Hover/active states: transform up, enhanced shadow

### **Cards**
- [ ] `.card` — white bg, r-lg radius, padding-5, subtle shadow + border
- [ ] `.card-primary` — primary color, white text, chunky shadow
- [ ] `.card-flat` — no shadow
- [ ] Color-coded borders for context (kid cards, tile cards)

### **Chips**
- [ ] `.chip` — soft bg + color-matched text
- [ ] `.chip-star`, `.chip-peach`, `.chip-rose`, `.chip-mint`, `.chip-sky`, `.chip-lilac`, `.chip-coral`
- [ ] `.chip-outline` — white bg, border, text color
- [ ] Inline icon + text

### **Modals**
- [ ] Backdrop blur + dark overlay
- [ ] Pop-in animation (scale + translate)
- [ ] Generous padding (space-6)
- [ ] r-xl radius
- [ ] Chunky shadow

### **Animations**
- [ ] `slideInCard` — opacity 0 + translateY(16px)
- [ ] `slideIn` / `slideInR` — left/right slide + fade (0.4s)
- [ ] `popIn` — scale(0.85) + pop out (cubic-bezier easing)
- [ ] `shake` — left-right vibration for rejection
- [ ] `float` / `bounce` — for Lumi mascot
- [ ] Stagger delays on cards (index × 40-60ms)

### **Colors**
- [ ] CSS variable fallbacks for palette switching
- [ ] Soft + hard variants per color (e.g., `--c-peach` + `--c-peach-soft`)
- [ ] Text colors: `--text`, `--text-muted`, `--text-soft`
- [ ] Danger/success semantic colors

### **Icons**
- [ ] Phosphor icon integration (via CDN or local font)
- [ ] Icon sizing: 12, 14, 16, 18, 20, 22, 24, 26, 48, 56px
- [ ] Color inheritance: `color="currentColor"` for inline icons

---

## Component Implementation Checklist

### **Shared Components** (Global)
- [ ] `Lumi` — mascot with mood states
- [ ] `BgShapes` — decorative background (3 variants: blue, warm, cool)
- [ ] `Icon` — Phosphor icon wrapper
- [ ] `IconTile` — icon in colored box
- [ ] `KidAvatar` — circular profile icon
- [ ] `StarBadge` — star icon badge
- [ ] `BalanceChip` — star count display (animated counter)
- [ ] `Celebration` — confetti effect
- [ ] `Modal` — dialog wrapper
- [ ] `TopBar` — header with nav + slots
- [ ] `EmptyState` — blank state message
- [ ] `useToast` / Toast system — notifications

### **Session Flow**
- [ ] ProfileSelect page (Lumi, avatars, login)

### **Parent Routes**
- [ ] Dashboard (KPI tiles, kid overview, action buttons)
- [ ] Approvals (task approval queue, approve/reject flow)
- [ ] Global Tasks Bank (create/edit missions)
- [ ] Kid Profiles (manage kids, add/edit)
- [ ] Rewards Shop (create/edit shop items)
- [ ] Activity Log (transaction history per kid)

### **Kid Routes**
- [ ] Dashboard/Home (task portal, tabs, mission cards, modal flow)
- [ ] Rewards Shop (purchase flow, celebration)
- [ ] History/Activity Log (personal transaction history)
- [ ] Bottom Navigation (global kid nav)

---

## Notes

1. **Palette Switching:** App must support live theme switching (Sky / Aurora / Galaxy) via `data-palette` attribute on root.
2. **Animations:** Stagger intervals should be consistent (~40-60ms per card/item).
3. **Color System:** Use `COLOR_MAP` (kid.color → bg/fg/ink) for consistent theming.
4. **Icon Strategy:** Map logical names (e.g., `target`, `bag`) to Phosphor glyph names.
5. **Responsive:** Design assumes mobile-first. Media queries for desktop tweaks at 640px+.
6. **Z-index Management:** Ensure proper layering (bg shapes @ z:0, content @ z:2, modals @ z:100).

---

## Priority Phases

### **Phase 1: Foundation** (highest impact)
- Design system CSS variables + utilities
- Button, card, chip components
- Icon system + Phosphor integration
- Layout utilities (flex, grid, spacing)

### **Phase 2: Shared UI**
- Modal + TopBar + Toast
- EmptyState + Progress
- KidAvatar + BalanceChip
- Lumi mascot + BgShapes

### **Phase 3: Pages**
- Session/ProfileSelect
- Parent Dashboard
- Kid Home + Approvals
- Shop (admin + kid)

### **Phase 4: Polish**
- Animations + transitions
- Responsive refinements
- Palette switching
- Celebration/confetti effects

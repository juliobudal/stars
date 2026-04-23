# Pixel-Perfect Refinement: LittleStars → Stars/ Reference

**Date:** 2026-04-23  
**Reference:** `Stars/src/` — Direction A "Soft Candy" with Berry Pop palette  
**Scope:** All views, components, and design tokens  

---

## 0. Methodology

The reference (Stars/) is the authoritative design truth.  
The app already uses the correct palette, fonts (Fraunces + Nunito), and shadow system.  
The gaps are precision-level: spacing values, chip sizing, letter-spacing direction, radius usage, and specific component metrics that accumulate into a "not quite there" feel.

Fixes are organized by layer: **tokens → CSS components → views**.

---

## 1. Token Fixes (`design_system.css` — `:root`)

### 1.1 Eyebrow / Label Letter-Spacing

| Token | App | Reference | Fix |
|-------|-----|-----------|-----|
| `.eyebrow` letter-spacing | `0.12em` | `0.24em` | Change to `0.24em` |
| `.eyebrow` font-size | `12px` | `11px` | Change to `11px` |
| `.eyebrow` font-family | `var(--font-display)` = Fraunces | Nunito 800w | Change to `var(--font-body)` |

**Why it matters:** Eyebrows ("MEU COFRINHO", "LOJINHA DA") are the most-read uppercase labels. Current 0.12em feels cramped; reference breathes at 0.24em.

### 1.2 Bottom Nav Offset

| Token | App | Reference | Fix |
|-------|-----|-----------|-----|
| `.bottom-nav` bottom | `calc(20px + env(...))` | `32px` | `calc(32px + env(safe-area-inset-bottom, 0px))` |

### 1.3 Progress Bar Height

| Token | App | Reference | Fix |
|-------|-----|-----------|-----|
| `.progress-track` height | `14px` | `12px` | `12px` |

---

## 2. Component CSS Fixes

### 2.1 Buttons

**Base `.btn` padding** — Reference uses tighter default than app:

| Selector | App | Reference | Fix |
|----------|-----|-----------|-----|
| `.btn` padding | `14px 28px` | `12px 20px` | `12px 20px` |
| `.btn` font-size | `16px` | `16px` | ✅ keep |
| `.btn-sm` padding | `10px 20px` | `8px 14px` | `8px 14px` |
| `.btn-sm` font-size | `14px` | `14px` | ✅ keep |
| `.btn-lg` padding | `18px 36px` | `14px 24px` | `14px 24px` |
| `.btn-icon` size | `48px × 48px` | `44px × 44px` | `44px × 44px` |

**Button hover**: Reference lifts `translateY(-4px)`, not `-1px`:
- `.btn:hover { transform: translateY(-2px); }` (split diff — 4px is for cards, -1px too subtle)  
  → Reference: `-4px` on cards, `-2px` on buttons. Update app to `-2px`.

### 2.2 Chips / Badges

Reference chips are significantly smaller and have positive (breathing) letter-spacing — opposite of app.

| Property | App | Reference | Fix |
|----------|-----|-----------|-----|
| `.chip` padding | `6px 14px` | `4px 10px` | `4px 10px` |
| `.chip` font-size | `13px` | `11px` | `11px` |
| `.chip` letter-spacing | `-0.01em` | `0.08em` | `0.08em` |
| `.chip` font-weight | `800` | `800` | ✅ keep |

**Star chip ink color** — App uses amber `#92400E`, reference uses charcoal `#2B2A3A`:
```css
/* current: wrong */
.chip-star { color: #92400E; }
/* fix: */
.chip-star { color: var(--text); }  /* #2B2A3A */
```

**Category chip colors** (small 10-11px label chips in mission cards):  
Add `.chip-sm` variant — 10px font, `3px 9px` padding, `0.12em` letter-spacing, weight `900`.

### 2.3 Cards

**Card border-radius** — App's `.card` uses `var(--r-lg)` = 32px. Reference standard cards: 22px (`--r-md`). Only featured/large containers use 28px (doesn't exist as token → add).

| Selector | App | Reference | Fix |
|----------|-----|-----------|-----|
| `.card` border-radius | `var(--r-lg)` = 32px | 22px | Change to `var(--r-md)` (22px) |
| `.card` padding | `var(--space-5)` = 24px | 18-28px (18px standard) | `var(--space-4)` (16px) base, views add more as needed |

Add new token: `--r-featured: 28px` for the profile picker cards, featured banners.

**Card padding** update — Reference shows `SPACE.md = 18px` for regular cards. App's 24px is generous but slightly inflated. Change `.card` default to 20px (balanced).

### 2.4 Nav Items

**Nav icon size** — App SVGs render at 22px; reference uses 18px in bottom nav.

```css
/* fix */
.nav-item svg { width: 18px; height: 18px; }
```

**Sidebar nav items** (parent layout, desktop):

| Property | App | Reference | Fix |
|----------|-----|-----------|-----|
| `.side-nav .nav-item` padding | `10px 14px` | `12px 14px` | `12px 14px` |
| `.side-nav .nav-item` border-radius | `999px` | `14px` | `14px` |
| active nav-item bg | `var(--primary)` + white text | `var(--primary-soft)` + dark text + lilac icon | Fix active state |

**Active sidebar item** in reference: background = soft lilac (`#EDE9FE`), text = `#2B2A3A`, icon = `#A78BFA`. App uses full purple background + white text — too heavy. Fix:

```css
body.parent-layout .side-nav .nav-item.active {
  background: var(--primary-soft);
  color: var(--text);
  font-weight: 800;
}
body.parent-layout .side-nav .nav-item.active svg {
  color: var(--primary);
}
```

### 2.5 Balance Chip

App `.balance-chip`: `padding: 8px 16px 8px 10px`, `gap: 8px`. Reference: identical — ✅ **no change needed**.

### 2.6 Form Labels

App `.form-label`: `letter-spacing: 0.08em`. Reference labels/eyebrows: `0.24em`.  
Update `.form-label` to `letter-spacing: 0.16em` (midpoint — form labels are inline, 0.24em too wide in form context).

### 2.7 Modal

App modal: `border-radius: var(--r-xl)` = 40px. Reference: modals use same large radius (`r-xl`).  
✅ No change — reference confirms 40px for modal.

### 2.8 Icon Tile

App `.icon-tile`: `border-radius: var(--r-md)` = 22px. Reference icon tiles: smaller rounded square with ~14px radius.  
Fix: `border-radius: var(--r-sm)` = 14px.

### 2.9 Mission Node

App `.mission-node`: 84px × 84px. Reference: 84px. ✅ Match.  
App shadow, colors: ✅ Match reference exactly.

### 2.10 Status Chips

App `.status-chip`: 28px × 28px pill. Reference: 28px × 28px. ✅ Match.  
Colors: ✅ Match.

---

## 3. View-Specific Fixes

### 3.1 Sessions (Profile Picker) — `sessions/index.html.erb`

| Element | App | Reference | Fix |
|---------|-----|-----------|-----|
| Page title font-size | `42px` inline | `42px` | ✅ |
| Title letter-spacing | `-0.02em` | `-0.02em` | ✅ |
| Subtitle font-size | `16px` | `16px` | ✅ |
| Profile card border-radius | `28px` inline | `28px` | ✅ |
| Profile card padding | `32px` inline | `32px` | ✅ |
| Avatar circle size | `124px` | `124px` | ✅ |
| Avatar inner smiley | — | — | verify SVG renders correctly |
| Profile name size | `24px` inline | `24px` | ✅ |
| Stars pill bg | `#FFF4CC` | `#FFF4CC` | ✅ |
| Streak pill bg | `#FFEDE0` | `#FFEDE0` | ✅ |
| "RESPONSÁVEL" label | `11px uppercase` | `11px 0.24em` | Fix letter-spacing to `0.24em` |
| Grid gap | `28px` | `28px` | ✅ |
| Add profile card | dashed border, transparent | dashed `var(--hairline)` | ✅ |
| Footer link to parent area | present | present | ✅ |

**Action**: Fix "RESPONSÁVEL" label letter-spacing. Everything else aligned.

### 3.2 Kid Dashboard — `kid/dashboard/index.html.erb`

| Element | App | Reference | Fix |
|---------|-----|-----------|-----|
| Header avatar size | 56px | 56px | ✅ |
| Header greeting font | `h-display` | display 18px | verify inline style |
| Streak pill height | `44px` | 44px | ✅ |
| Cofrinho card internal spacing | varies | `SPACE.md=18px` | audit inline gaps |
| Balance label "MEU COFRINHO" | eyebrow class | 11px/800w/0.24em | fixed by eyebrow token change |
| Points chip font | 18px | 18px | ✅ |
| Progress track height | 14px | 12px | fixed by token change |
| Mission path rail | 3px dashed | 3px dashed `hairline` | ✅ |
| Mission node size | 84px | 84px | ✅ |
| Horizontal gap node→card | 18px | 18px | ✅ |
| Mission card title size | `h-display` clamp | 19px fixed | Add `.mission-title { font-size: 19px; }` |
| Category chip on card | `.chip` 13px | 11px 0.08em | fixed by chip token change |
| Points badge on card | `.chip-star` amber ink | charcoal ink | fixed by chip-star fix |
| "AGORA" badge | `star-soft` bg | star bg, dark text | ✅ |
| Finish node | 84px, star-soft bg | 84px, `#FFF4CC` | ✅ |
| Lumi inside finish node | 58px | 58px | ✅ |
| Modal padding | var(--space-6)=32px | var(--space-6) | ✅ |
| Modal card radius | var(--r-xl)=40px | r-xl | ✅ |
| Celebration controller | present | present | ✅ |

**Actions**:  
- Add `.mission-title` class with fixed 19px  
- Chip fixes from §2.2 ripple here  
- Eyebrow fix from §1.1 ripples here  

### 3.3 Kid Rewards/Shop — `kid/rewards/index.html.erb`

| Element | App | Reference | Fix |
|---------|-----|-----------|-----|
| Featured banner grid | 2-col | 2-col, gap 28px | ✅ |
| Featured banner padding | 28px | 28px | ✅ |
| Featured banner radius | `var(--r-lg)=32px` | 28px (`--r-featured`) | Add `--r-featured` token, apply |
| "✨ EM DESTAQUE" chip | chip-primary | `#EDE9FE` bg, lilac text | chip-primary is ✅ if primary-soft correct |
| Category tabs | tabs controller | pill tabs | verify active=purple, inactive=white |
| Reward grid card bg (tints) | 5-color rotation | 5 category tints | ✅ |
| Reward art size | 120×120px | 120px | ✅ |
| Reward art icon size | 56px (56% of container) | ~56px | ✅ |
| Reward card title | 14px `h-display` | 14px | ✅ |
| Card entrance animation | staggered slideInCard | staggered | ✅ |
| "Meus Prêmios" section title | h3 display | 24px h-display | verify size |
| Redeemed reward card | horizontal, icon 64px | icon 64px lilac bg | ✅ |
| Redemption modal calc table | card with bg-mid | `bg-soft` bg | verify background token |

**Actions**:  
- Add `--r-featured: 28px` token  
- Apply `--r-featured` to featured banner  
- Chip size fixes ripple here  

### 3.4 Kid Wallet — `kid/wallet/index.html.erb`

| Element | App | Reference | Fix |
|---------|-----|-----------|-----|
| Transaction icon disc | 48px, r=14px | 48px, r=14px | ✅ |
| Transaction title | 16px display | 16px display | ✅ |
| Amount color | green/purple | green earned, purple redeemed | ✅ |
| Amount size | 18px | 18px | ✅ |
| Date/meta chips | small chips | 11px 0.08em | fixed by chip change |

### 3.5 Parent Dashboard — `parent/dashboard/index.html.erb`

| Element | App | Reference | Fix |
|---------|-----|-----------|-----|
| Header avatar | 56px | 56px | ✅ |
| Greeting text | `h-display` | display, name prominent | ✅ |
| Pending approvals banner | gradient primary→purple | gradient | ✅ |
| Banner icon tile size | 52px | 52px | ✅ |
| Banner padding | 20px | 20px | ✅ |
| 4-col stats grid gap | 16px | 16px | ✅ |
| Stat card icon tile | 38×38px, r=10px | 38×38px | icon-tile: r-sm=14px too big → use `border-radius: 10px` for stat tiles |
| Stat number font | 28px h-display | 28px | ✅ |
| Stat label | eyebrow | 11px/0.24em | fixed by eyebrow change |
| Child cards grid | 3-col | 3-col | ✅ |
| Child card color band | top colored band | top colored band | ✅ |
| Child avatar in card | 56px | 56px | ✅ |
| Child name size | 22px display in ink | 22px | ✅ |
| Streak label | 11px/800w | 11px/800w | ✅ |
| Stats section padding | 16-20px | 18-20px | ✅ |
| Recent activity row padding | 14px | 14px | ✅ |
| Activity amount colors | green/purple | green/purple | ✅ |

**Actions**:  
- Stat card icon tile: use inline `border-radius: 10px` instead of `.icon-tile` default (or add `.icon-tile-sm` variant with 10px)  
- Eyebrow fix from §1.1 ripples here  

### 3.6 Parent Global Tasks — `parent/global_tasks/index.html.erb`

| Element | App | Reference | Fix |
|---------|-----|-----------|-----|
| Table header | uppercase 11px 0.1em | 11px 0.1em | close — ✅ |
| Filter chips | tabs chip row | same | verify chip sizes use chip-sm |
| Frequency badges | soft chips | 12px chips | update to use `.chip.chip-sm` |
| Points display | star icon + 15px display | star icon + 15px | ✅ |
| Toggle switch | 36×20px | 36×20px | ✅ |
| Kid avatars (overlapping) | 24px circles | 24px | ✅ |

### 3.7 Parent Approvals — `parent/approvals/index.html.erb`

| Element | App | Reference | Fix |
|---------|-----|-----------|-----|
| Tab pill switcher | dark active, count pill | dark/white pill | ✅ |
| Mission approval card padding | 18px | 18px | ✅ |
| Icon tile size | 52px | 52px | ✅ |
| Card title | 17px h-display | 17px | ✅ |
| Kid name + avatar | 22px mini avatar | 22px | ✅ |
| Action buttons | icon-only, danger/success | icon-only 44px | verify `.btn-icon` 44px fix applies |
| Empty state | "Tudo em dia! 🎉" | message card | ✅ |

### 3.8 Parent Sidebar — `shared/_parent_nav.html.erb`

| Element | App | Reference | Fix |
|---------|-----|-----------|-----|
| Sidebar width | 260px | 260px | ✅ |
| Sidebar padding | 24px 16px | 24px 16px | ✅ |
| Brand icon radius | 10px | 10px | ✅ |
| Nav item padding | 10px 14px | 12px 14px | Fix (§2.4) |
| Nav item border-radius | 999px (pill) | 14px | Fix (§2.4) |
| Active: bg | full purple | soft lilac + dark text | Fix (§2.4) |
| Approval badge | peach pill, top-right | coral pill, 8px padding | ✅ colors match |
| Gap between nav sections | 24px | 24px | ✅ |
| Gap between nav items | 2px | 2px | ✅ |

### 3.9 Kid Bottom Nav — `shared/_kid_nav.html.erb`

| Element | App | Reference | Fix |
|---------|-----|-----------|-----|
| Container border-radius | var(--r-full) | 999px | ✅ |
| Container padding | 8px | 10px 14px outer | Fix to `padding: 10px 14px` |
| Container bottom | 20px | 32px | Fix (§1.2) |
| Item padding | 10px 14px | 10px 16px | Close — update to `10px 16px` |
| Icon size | 22px | 18px | Fix (§2.4) |
| Active: bg | star (gold) | star (gold) | ✅ |
| Active: show label | yes | yes | ✅ |
| Inactive: transparent | yes | yes | ✅ |
| Box shadow | `0 4px 0 + 0 16px 40px` | `shadowRaised = 0 4px 0 + 0 18px 36px` | Minor: update 40px→36px, opacity tune |

---

## 4. New CSS Additions Required

```css
/* Add to design_system.css :root */
--r-featured: 28px;       /* profile picker cards, featured banners */

/* Add component variants */
.chip-sm {
  font-size: 10px;
  padding: 3px 9px;
  letter-spacing: 0.12em;
  font-weight: 900;
  border-radius: var(--r-full);
}

.icon-tile-sm {
  border-radius: 10px;    /* stat card icons in parent dashboard */
}

.mission-title {
  font-family: var(--font-display);
  font-style: italic;
  font-weight: 700;
  font-size: 19px;
  letter-spacing: -0.01em;
  line-height: 1.2;
}
```

---

## 5. Summary of Changes by File

### `app/assets/stylesheets/design_system.css`

**Token changes (`:root`):**
- `--r-featured: 28px` (add)

**Component changes:**
- `.eyebrow`: font-size `12px→11px`, letter-spacing `0.12em→0.24em`, font-family → `var(--font-body)`
- `.btn`: padding `14px 28px → 12px 20px`
- `.btn:hover`: translateY `-1px → -2px`
- `.btn-sm`: padding `10px 20px → 8px 14px`
- `.btn-lg`: padding `18px 36px → 14px 24px`
- `.btn-icon`: size `48px → 44px`
- `.chip`: padding `6px 14px → 4px 10px`, font-size `13px → 11px`, letter-spacing `-0.01em → 0.08em`
- `.chip-star`: color `#92400E → var(--text)` (#2B2A3A)
- `.chip-sm` (add)
- `.card`: border-radius `var(--r-lg) → var(--r-md)`, padding `var(--space-5) → 20px`
- `.icon-tile`: border-radius `var(--r-md) → var(--r-sm)` (14px)
- `.icon-tile-sm` (add)
- `.mission-title` (add)
- `.mission-node`: ✅ no change
- `.status-chip`: ✅ no change
- `.bottom-nav`: bottom `calc(20px+...) → calc(32px+...)`, padding `8px → 10px 14px`
- `.bottom-nav` shadow: `40px → 36px`
- `.nav-item`: padding `10px 14px → 10px 16px`, SVG size `22px → 18px`
- `.progress-track`: height `14px → 12px`
- `.form-label`: letter-spacing `0.08em → 0.16em`
- Parent sidebar `.nav-item`: padding `10px 14px → 12px 14px`, border-radius `999px → 14px`
- Parent sidebar `.nav-item.active`: bg soft-lilac, text dark, icon primary (not full purple)

### View-level inline style fixes

- `sessions/index.html.erb`: "RESPONSÁVEL" label → add `letter-spacing: 0.24em`
- `kid/dashboard/index.html.erb`: task title element → use `.mission-title` class; stat tiles use `.icon-tile-sm`
- `parent/dashboard/index.html.erb`: stat icon tiles → `border-radius: 10px` or `.icon-tile-sm`
- Featured reward banner in `kid/rewards/index.html.erb` → border-radius `var(--r-featured)` (28px)

---

## 6. Priority Order for Implementation

1. **P0 — Token + Core component CSS** (high visual impact, one file)
   - eyebrow, chip, button, card, nav item changes in `design_system.css`
2. **P1 — New CSS additions** (chip-sm, mission-title, icon-tile-sm, r-featured)
3. **P2 — Sidebar active state** (parent nav)
4. **P3 — View inline style fixes** (session label, stat tiles, featured banner radius)
5. **P4 — Bottom nav** (offset + padding + shadow)

---

## 7. Non-Issues (Confirmed Match)

The following are aligned and require no changes:

- Color palette (all tokens) ✅
- Shadow system (card, lift, btn direction) ✅  
- Mission node: 84px, colors, glow ✅  
- Status chip: 28px pill, colors ✅  
- Balance chip structure ✅  
- Modal: radius 40px, popIn animation ✅  
- Screen slide-in animation ✅  
- Progress fill color ✅  
- Star mascot + Lumi SVG components ✅  
- Smiley avatar SVG system ✅  
- Reward art tints (5-color rotation) ✅  
- Category CATEGORIES map (colors, icons) ✅  
- Turbo stream integration ✅  
- Celebration confetti controller ✅  
- Toggle switch (36×20px) ✅  
- Activity log entry structure ✅  

---

## 8. Design Principles to Uphold

Every change must preserve:
1. **Soft Candy language**: no hard edges, no heavy borders, no dark-mode-like contrast
2. **Star economy**: gold (#FFC53D) is always reward/currency — never overloaded
3. **Lilac as primary action**: #A78BFA for CTAs, active states, brand
4. **Person color system**: each profile's fill/ring/ink palette untouched
5. **Fraunces italic** for all display headings (titles, card titles, mission names)
6. **Nunito 800w** for all labels, chips, buttons, nav items
7. **Breathing labels**: positive letter-spacing on ALL uppercase text (0.12em minimum, 0.24em for eyebrows)

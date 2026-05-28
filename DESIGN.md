---
name: LittleStars
description: Gamified family task manager with a tactile, encouraging Duolingo-style visual language.
colors:
  primary: "#58CC02"
  primary-depth: "#46A302"
  primary-soft: "#DCFCE7"
  primary-glow: "#86EFAC"
  star: "#FFC800"
  star-depth: "#E0A800"
  star-soft: "#FFF4DA"
  reward-text: "#B36F00"
  info-sky: "#1CB0F6"
  info-sky-depth: "#1899D6"
  info-sky-soft: "#DDF4FF"
  character-lilac: "#CE82FF"
  character-lilac-depth: "#A855E0"
  streak-coral: "#FF9600"
  streak-coral-depth: "#CC7700"
  danger: "#FF4B4B"
  danger-depth: "#C53232"
  bg: "#F7F7F7"
  surface: "#FFFFFF"
  surface-muted: "#F7F7F7"
  hairline: "#E5E5E5"
  text: "#4B4B4B"
  text-muted: "#777777"
  text-soft: "#AFAFAF"
typography:
  display:
    fontFamily: "Nunito, system-ui, sans-serif"
    fontSize: "36px"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "normal"
  headline:
    fontFamily: "Nunito, system-ui, sans-serif"
    fontSize: "26px"
    fontWeight: 800
    lineHeight: 1.15
    letterSpacing: "normal"
  title:
    fontFamily: "Nunito, system-ui, sans-serif"
    fontSize: "22px"
    fontWeight: 800
    lineHeight: 1.2
    letterSpacing: "normal"
  subtitle:
    fontFamily: "Nunito, system-ui, sans-serif"
    fontSize: "18px"
    fontWeight: 800
    lineHeight: 1.25
    letterSpacing: "normal"
  body:
    fontFamily: "Nunito, system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 700
    lineHeight: 1.5
    letterSpacing: "normal"
  label:
    fontFamily: "Nunito, system-ui, sans-serif"
    fontSize: "11px"
    fontWeight: 800
    lineHeight: 1.2
    letterSpacing: "0.5px"
rounded:
  sm: "10px"
  md: "12px"
  lg: "14px"
  xl: "16px"
  featured: "20px"
  full: "999px"
spacing:
  "1": "4px"
  "2": "10px"
  "3": "14px"
  "4": "20px"
  "5": "28px"
  "6": "36px"
  "7": "48px"
  "8": "64px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface}"
    typography: "{typography.label}"
    rounded: "{rounded.lg}"
    padding: "14px 20px"
  button-primary-active:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: "14px 20px"
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    typography: "{typography.label}"
    rounded: "{rounded.lg}"
    padding: "14px 20px"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    rounded: "{rounded.xl}"
    padding: "16px"
  stat-card:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.text}"
    rounded: "{rounded.xl}"
    padding: "16px"
  filter-pill:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-muted}"
    typography: "{typography.label}"
    rounded: "{rounded.sm}"
    padding: "8px 14px"
  filter-pill-selected:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.primary-depth}"
    typography: "{typography.label}"
    rounded: "{rounded.sm}"
    padding: "8px 14px"
  input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text}"
    typography: "{typography.body}"
    rounded: "{rounded.lg}"
    padding: "12px 14px"
  badge-star:
    backgroundColor: "{colors.star-soft}"
    textColor: "{colors.reward-text}"
    typography: "{typography.label}"
    rounded: "{rounded.full}"
    padding: "4px 10px"
  toggle:
    backgroundColor: "{colors.primary}"
    rounded: "{rounded.full}"
    width: "52px"
    height: "30px"
---

# Design System: LittleStars

## 1. Overview

**Creative North Star: "The Encouraging Arcade"**

LittleStars is a cooperative game between parents and kids, and the interface should feel like a friendly arcade cabinet, not an admin panel. Every interactive surface is a physical, pressable object: it sits on a flat 3D depth shadow (`0 4px 0`), depresses on touch, and springs back. The system never punishes. Errors are gentle, progress is celebrated with confetti and pulses, and the dominant color is an optimistic Duolingo green. The mood is **encouraging, playful, formative**: a child should want to open the app alone, and a parent should feel the screen time is building character rather than numbing it.

This is a **product** register: the design serves the task (configure a chore, approve it, redeem a reward, finish a knowledge pill), it is not the product itself. Density is low and mobile-first. The kid shell is a single thumb-reachable column capped at `430px`; the parent shell is a calm dashboard with a fixed sidebar. Hierarchy comes from bold weight (Nunito 700/800) and tactile depth, not from drop shadows, gradients, or glass.

What this system explicitly rejects: the retired "Berry Pop" era (lilac `#A78BFA`, Fraunces display serif, soft blurry `rgba(...) 0 4px 12px` shadows). It also rejects generic SaaS sterility, gradient text, blurry glassmorphism, and the cold corporate dashboard look. If a screen could pass for a B2B analytics tool, it has failed.

**Key Characteristics:**
- Tactile 3D depth on every interactive element (`0 4px 0`), with a mandatory press-and-spring motion contract.
- One bold typeface (Nunito) at heavy weights; 700 is the floor, 800 is the emphasis.
- Compact radii (10–16px), never the soft 22–32px of the retired era.
- Duolingo green primary, with a small cast of saturated accents (star gold, sky blue, character lilac, streak coral) used by role.
- Per-kid palette theming: a `data-palette` attribute re-tints only the primary family; depth, type, and radii stay constant.
- Single token source of truth in `app/assets/stylesheets/tailwind/theme.css`; raw hex is forbidden everywhere else.

## 2. Colors

A bright, saturated, candy-shop palette anchored by one optimistic green, with each accent assigned a fixed semantic job so the screen never reads as random color noise.

### Primary
- **Duolingo Green** (`#58CC02`): the brand spine. Primary buttons, progress fills, active states, success. Carries roughly 30–50% of an action-heavy screen.
- **Green Depth** (`#46A302`): the depth-shadow color *under* the green, never a fill. Gives primary buttons their pressable 3D base.
- **Mint Tint** (`#DCFCE7`): soft surfaces, selected-pill backgrounds, the focus ring glow.

### Secondary
- **Star Gold** (`#FFC800`): the star economy currency. Balances, rewards, streak rewards, difficulty pickers. Gold is *the points color*; do not use it decoratively.
- **Star Depth** (`#E0A800`) / **Star Tint** (`#FFF4DA`) / **Reward Text** (`#B36F00`): the gold's depth shadow, its soft surface, and the high-contrast text color for star counts on light tints.

### Tertiary
- **Sky Blue** (`#1CB0F6`): informational accent and the parent sidebar active state. Calm, secondary to green.
- **Character Lilac** (`#CE82FF`): kid identity and avatars only. This is the *people* color, not a generic accent.
- **Streak Coral** (`#FF9600`): streaks, flames, and soft warnings. Heat and momentum.
- **Danger Red** (`#FF4B4B`): destructive actions and hard errors only. Rare by design.

### Neutral
- **App Background** (`#F7F7F7`): the canvas behind both shells. Never pure white, never pure black.
- **Surface White** (`#FFFFFF`): cards and elevated objects.
- **Surface Muted** (`#F7F7F7`): insets, chips, idle picker cells.
- **Hairline** (`#E5E5E5`): the 2px border on every card and field.
- **Text** (`#4B4B4B`) / **Text Muted** (`#777777`) / **Text Soft** (`#AFAFAF`): the foreground ramp. There is no `#000` text anywhere.

### Named Rules
**The One Source Rule.** Every color in a view comes from a CSS variable defined in `tailwind/theme.css`. Raw hex outside that file is forbidden. The single sanctioned exception is `public/offline.html`, which must render with no stylesheet available and therefore inlines its own brand hex; any brand-color change must be mirrored there by hand.

**The Semantic Color Rule.** Each accent has one job: gold is points, lilac is people, coral is streaks/warnings, sky is info, red is danger. Never reach for an accent because a screen "needs more color". Color is meaning, not decoration.

**The Per-Kid Tint Rule.** `data-palette="peach|rose|mint|sky|lilac|coral"` on the kid shell reassigns only the `--primary` family. Shadows, typography, and radii always inherit the Duolingo defaults. A kid's theme tints the brand, it does not redesign the app.

## 3. Typography

**Display Font:** Nunito (with `system-ui, sans-serif` fallback)
**Body Font:** Nunito (the only family; display and body are the same face at different weights)
**Label/Mono Font:** none distinct; labels are Nunito 800 uppercase.

**Character:** Nunito is rounded, warm, and friendly: a face that reads as approachable to a child without becoming childish. The entire system runs on weight contrast within this one family. There is no serif, no second font, no italic display. Fraunces and Inter are explicitly banned.

### Hierarchy
- **Display** (800, 36px / `--text-3xl`, line-height 1.1): the largest celebratory numbers and hero moments. Used sparingly.
- **Headline / H1** (800, 26px / `--text-2xl`, line-height 1.15): page titles ("Quem é você?").
- **Title / H2** (800, 22px / `--text-xl`, line-height 1.2): section headings.
- **Subtitle / H3** (800, 18px / `--text-lg`, line-height 1.25): card titles.
- **Body** (700, 14–15px / `--text-base`, line-height 1.5): default running text. Cap measure at 65–75ch.
- **Label** (800, 11px / `--text-xs`, uppercase, letter-spacing 0.5px): eyebrows, button labels, badge text, form labels.

### Named Rules
**The 700 Floor Rule.** Body text never drops below `font-weight: 700`. Headings, buttons, stat numbers, and badge labels are `800`. Light and regular weights do not exist in this system; thin type would break the chunky, tactile feel.

**The One Voice Rule.** One typeface, full stop. Hierarchy is achieved by scale and weight, never by introducing a second family. If a screen feels flat, increase the weight or size step (ratio ≥1.25), do not add a font.

## 4. Elevation

This system conveys depth through **hard, flat, offset shadows** (`0 4px 0` with zero blur), not soft ambient shadows. Every elevated object looks like a physical key or tile resting on the surface, with a colored "side" visible beneath it. Blur is reserved exclusively for the decorative background orb layer (`Ui::BgShapes`); it never appears on a functional element. Lifted blurry card shadows from the retired era are banned.

### Shadow Vocabulary
- **Card depth** (`box-shadow: 0 4px 0 rgba(0,0,0,0.08)`): the canonical kid card. Use `surface-card-3d`.
- **Card depth, subtle** (`0 4px 0 rgba(0,0,0,0.06)`): parent dashboard sections. Use `surface-card-3d-soft`.
- **Card depth, light / heavy** (`0 4px 0 rgba(0,0,0,0.04)` / `0.12`): chips/mini-cards and hero/featured cards respectively.
- **Button depth** (`0 4px 0 var(--{tone}-depth)`): primary/success/destructive/warning/secondary buttons each rest on their own depth color via the `shadow-btn-*` utilities. Hover adds 1px (`0 5px 0`), active collapses to `0 1px 0`.
- **Lift** (`0 6px 0 rgba(0,0,0,0.08)`): the hover state of a card, paired with `translateY(-2px)`.

### Named Rules
**The 3D Motion Contract.** Any element carrying a depth shadow must press and spring. On `:active` it sets `transform: translateY(2px); box-shadow: none` over `transition: transform 0.05s`. Cards instead lift on `:hover` (`translateY(-2px)` + lift shadow). This is mandatory, and every such element must include a `prefers-reduced-motion: reduce` override that disables the transition. The `ls-btn-3d`, `ls-card-3d`, and sibling utilities encode this; never hand-roll it.

**The Hard-Shadow Rule.** Depth shadows are `0 4px 0` with no blur and no spread. A blurry button shadow (`rgba(...) 0 4px 12px`) is the single clearest sign the design has regressed to the retired Berry Pop era. If it looks soft, it is wrong.

## 5. Components

Reusable UI lives as `Ui::*` ViewComponents under `app/components/ui/<name>/`. Always reach for an existing component before writing inline markup; if a pattern recurs twice, extract a component in the same PR. The library is large (buttons, cards, rows, avatars, badges, chips, forms, overlays); the canonical primitives below define the visual contract every component follows.

### Buttons
- **Shape:** 14px corners (`--r-lg`).
- **Primary:** green fill (`#58CC02`), white uppercase 800 label, padding `14px 20px`, resting on `0 4px 0 var(--primary-2)`.
- **Hover / Active:** hover deepens to `0 5px 0`; active collapses to `0 1px 0` with `translateY(2px)`, per the 3D Motion Contract.
- **Secondary / Ghost:** white fill, 2px hairline border, dark text, gray depth (`0 4px 0 #C9C9C9`). Driven by `Ui::Btn` `variant:`/`tone:`, which selects the matching `shadow-btn-*` utility.

### Chips & Pills
- **Filter pill** (`Ui::FilterChips`): idle is white + 2px hairline + faint depth; selected is a colored tint fill + 2px colored border + colored depth. State swaps the *color*, never the border thickness. Needs `role=tablist`/`role=tab` + `aria-selected`.
- **Badges** (`Ui::StarBadge`, `Ui::StreakBadge`, `Ui::Badge`): pill-shaped tint surfaces with a matching dark text color (star = gold tint + reward-text; streak = coral).

### Cards / Containers
- **Corner style:** 16px (`--r-xl`); modals and hero step up to 20px (`--r-featured`).
- **Background:** white surface on the `#F7F7F7` canvas.
- **Border:** always 2px hairline (`var(--border-card)`). 2px borders are universal; selected state recolors the border.
- **Shadow strategy:** `surface-card-3d` (0.08) for kid hierarchy, `surface-card-3d-soft` (0.06) for parent dashboard. See Elevation.
- **Internal padding:** 16px default. Cards lift on hover (`ls-card-3d`).
- **Nesting is banned.** Never put a depth card inside another depth card.

### Inputs / Fields
- **Style:** white fill, 2px hairline border, 14px radius, Nunito 700 at 15px (`.form-input` / `Ui::Select`).
- **Focus:** border shifts to `var(--primary)` and a 3px soft glow appears (`box-shadow: 0 0 0 3px var(--primary-soft)`). No outline-style focus on fields.
- **Label:** uppercase 12px, 800, letter-spacing 0.5, `var(--text-muted)`.
- **Toggle** (`Ui::Toggle`): 52×30 green track + white thumb with an inset depth shadow.

### Navigation
- **Kid shell:** a sticky bottom pill nav, single column capped `max-w-[430px]` (`md:560`, `lg:720`), `Ui::BgShapes` orb layer behind, `data-palette` on `<body>`.
- **Parent shell:** a fixed 220px left sidebar at ≥1024px (white, 2px right hairline), off-canvas drawer below. Active nav item = soft tint background + 2px colored border + colored text (sky accent in mocks; primary green also valid). Main column `max-w-[1100px]`.

### Motion & Feedback (signature behavior)
Motion is tokenized in `tailwind/motion.css` and consumed only via utility classes; raw `ms`/`s` durations in component CSS are blocked by `make lint-motion`. Easing is exponential ease-out (`--ease-spring`, `--ease-spring-soft`, `--ease-snap`); never bounce or elastic on layout. Durations run `--dur-instant` (80ms press) through `--dur-ambient` (2500ms idle loops). Use the `ls-*` press utilities and `anim-*` spring/effect classes (`anim-pop-in`, `anim-count-up` on balance changes, `anim-reward-unlock`, confetti on success). Stagger lists by `index * 0.04s`, capped at 5 items. Every motion class ships a `prefers-reduced-motion: reduce` fallback.

### Iconography
Functional icons are HugeIcons SVG via `Ui::Icon`; never emoji and never `<img>` for affordances. The one sanctioned exception is the Academy "método do mistério" narrative (🤔 💡 🔮 🦉), where emoji are decorative content, always `aria-hidden="true"` and never the sole label of a control.

## 6. Do's and Don'ts

### Do:
- **Do** route every color, font, radius, and shadow through a CSS variable in `tailwind/theme.css`. Raw hex lives only there (plus the documented `public/offline.html` exception).
- **Do** reach for a `Ui::*` ViewComponent first; only write inline markup when nothing fits, then document the new component in the same PR.
- **Do** give every interactive element a `0 4px 0` depth shadow and the full 3D Motion Contract (press, spring, reduced-motion fallback).
- **Do** keep type at Nunito 700 minimum, 800 for headings/buttons/numbers.
- **Do** use 2px borders everywhere; selected states swap the border *color*, not its thickness.
- **Do** assign accents by meaning: gold = points, lilac = people, coral = streaks, sky = info, red = danger.
- **Do** keep kid copy playful and parent copy concise, and honor `prefers-reduced-motion` on every transition.

### Don't:
- **Don't** reintroduce the retired Berry Pop / Soft Candy era: no Fraunces, no lilac `#A78BFA` as primary, no soft blurry shadows.
- **Don't** soften the 3D stack. Depth shadows are `0 4px 0`, hard and flat, never `rgba(...) 0 4px 12px`.
- **Don't** use `background-clip: text` gradient text, decorative glassmorphism, or blur on any functional element (blur is for `Ui::BgShapes` only).
- **Don't** use a `border-left`/`border-right` greater than 1px as a colored accent stripe. Use a full 2px border or a tint background.
- **Don't** drop below `font-weight: 700`, and never introduce a second typeface.
- **Don't** use border-radius greater than 20px outside avatars and modals, and never nest a depth card inside another.
- **Don't** use emoji for functional icons (buttons, status, nav); use `Ui::Icon`. Emoji are allowed only as decorative Academy narrative content.
- **Don't** let a screen read like a generic SaaS dashboard. If it could pass for a B2B analytics tool, rework it until it feels like the Encouraging Arcade.

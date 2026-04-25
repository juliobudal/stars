# Per-Kid Color Theming — Design Spec

**Date:** 2026-04-25
**Status:** Approved (brainstorm)
**Scope:** Reflect each kid's chosen color across kid layout and every UI element bound to that kid (avatars, kid cards, approval rows, activity rows) in both kid and parent interfaces.

## Goal

Today `Profile.color` is captured by the form and stored, but the value is never read by the UI. Make the chosen color drive the visual theme:

- **Kid interface** — when a kid is signed in, every page (`layouts/kid`) themes to that kid's color.
- **Parent interface** — kid-bound widgets (kid cards, avatars, approval queue rows, activity rows) tint to the kid they represent.

Points/star (`--star`) currency stays gold everywhere — universal, not per-kid.

## Decisions Locked During Brainstorm

| Q | Decision |
|---|----------|
| Scope | Kid layout + kid avatar/cards everywhere (kid + parent UI). |
| Theme depth | Override `--primary` family + `--bg-soft`. `--bg-deep`/`--bg-mid` stay neutral. |
| Per-kid tint mechanism | Scoped `data-palette="<color>"` wrapper around each kid-bound component. |
| Default fallback | `Profile.color` blank → `"primary"` (global lilac). No backfill migration. |
| Star/coin color | Stay gold. Currency reads same across all palettes. |

## Architecture

### Mechanism

CSS already supports `[data-palette="<name>"]` overrides (see `aurora`/`galaxy` in `app/assets/stylesheets/tailwind/theme.css`). Reuse the same pattern: each color value defined for `Profile.color` gets a matching CSS scope. Any element wrapped in `data-palette="<color>"` re-binds the listed CSS variables for its subtree.

Two scoping levels:

1. **Layout-level** — `layouts/kid.html.erb` body emits `data-palette="<current kid color>"`. Whole kid app themes.
2. **Component-level** — each kid-bound ViewComponent wraps its root with `data-palette="<profile color>"`. Component themes regardless of where it is rendered (parent dashboard, settings, anywhere).

Both levels rely on identical CSS overrides — no separate code path.

### Color Palette Inventory

`Profile.color` enum already validates `%w[peach rose mint sky lilac coral primary]`. CSS palette names mirror these exactly.

`primary` is a no-op palette — uses default theme (lilac). Used as fallback when `Profile.color` blank.

### Bug to Fix as Part of This Work

`--c-coral: #EC4899` in `theme.css` is a duplicate of `--c-rose: #EC4899`. Coral and rose render identically. Pick distinct coral hex (proposal: `#FB7185`) and add `--c-coral-soft`, `--c-coral-dark` siblings consistent with other colors.

## Implementation Surface

### CSS — `app/assets/stylesheets/tailwind/theme.css`

Add 6 palette overrides, one per color (no override for `primary` — it is the default):

```css
[data-palette="peach"] {
  --primary: var(--c-peach);
  --primary-2: var(--c-peach-dark);
  --primary-soft: var(--c-peach-soft);
  --primary-glow: var(--c-peach);
  --bg-soft: var(--c-peach-soft);
}
```

Repeat for `rose`, `mint`, `sky`, `lilac`, `coral`. (`peach` and `coral` need `-dark` variables added — currently only `peach-depth` exists; add `--c-peach-dark`, `--c-coral-dark` siblings to match the rose/mint/sky/lilac pattern.)

`--bg-deep`, `--bg-mid`, `--star`, `--star-2` left untouched.

### Helper — `app/helpers/palette_helper.rb`

```ruby
module PaletteHelper
  def palette_for(profile)
    profile&.color.presence || "primary"
  end
end
```

Mounted in `ApplicationHelper` (or auto-included via Rails default helper loading).

### Layout — `app/views/layouts/kid.html.erb`

Replace hardcoded `data-palette="sky"` on `<body>` with `data-palette="<%= palette_for(current_profile) %>"`. Verify exact helper name during implementation (likely `current_profile` from `Authenticatable` concern).

`layouts/parent.html.erb` stays `data-palette="sky"` — parent shell is global, only kid-bound widgets inside it tint per kid.

### Components — wrap root with `data-palette`

Each component below reads its bound profile and emits `data-palette` on its outermost rendered element. Convention: use `palette_for(@profile)` (or `@kid`/`@responsible`/etc — whatever local var the component already exposes).

| Component path | Bound to | Notes |
|----------------|----------|-------|
| `app/components/ui/kid_management_card/component.*` | `@kid` | Card root. |
| `app/components/ui/kid_progress_card/component.*` | `@kid` | Card root. |
| `app/components/ui/kid_initial_chip/component.*` | `@profile` | Chip root. |
| `app/components/ui/approval_row/component.*` | row's profile (via task → profile) | Row root. |
| `app/components/ui/activity_row/component.*` | log's profile | Row root. |
| `app/components/ui/profile_card/component.*` | `@profile` | Card root. |

`kid_avatar` and `smiley_avatar` are intentionally NOT wrapped — both already encode the kid's color through inline styles / inline SVG fills computed from `Profile.color`, so the avatar visuals are already per-kid. Wrapping them in `data-palette` would only affect descendants that consume `--primary`, but neither component renders any such descendant. The composite components above carry the wrap and tint everything around the avatar.

### Tests

- **Helper spec** — `palette_for(profile)` returns color when set, `"primary"` when blank or `profile` nil.
- **Component specs** — render `KidAvatar`, `KidManagementCard`, `ApprovalRow`, `ActivityRow` with profiles of different colors; assert root element carries `data-palette="<color>"`.
- **System spec** — kid with color `"peach"` signs in via PIN; assert `<body data-palette="peach">` on dashboard. Parent signs in; assert kid card on parent dashboard wraps with `data-palette` matching that kid's color.
- **Visual smoke** — manually verify each palette in browser (kid layout + parent dashboard with mixed-color kids).

## Out of Scope

- Adding new color choices or changing the existing 6.
- Color rotation / auto-assign logic on profile creation.
- Dark mode behavior.
- Per-page palette overrides inside the kid app.
- Transition/animation between palettes when switching kids.
- Theming the parent shell itself (sidebar, parent nav) per kid.

## Risks / Open Notes

- Coral/rose collision is a pre-existing data quality issue surfaced by this work — fix is bundled because the feature would otherwise ship with two visually-identical palettes.
- `current_profile` helper exact name to be confirmed during implementation; layout change is trivial if name differs.
- All `primary-*` consumers across the codebase (buttons, focus rings, links) automatically follow the override — visual regression scan recommended after impl.

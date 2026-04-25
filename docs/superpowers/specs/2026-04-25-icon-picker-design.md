# Icon Picker — Design

**Date:** 2026-04-25
**Status:** Approved (pending user review of this spec)
**Surface:** `parent/global_tasks/_form.html.erb`, `parent/rewards/_form.html.erb`

## Problem

Current mission and reward forms expose only ~12 hardcoded icon options via radio button grid. Parents cannot pick from the broader Hugeicons catalog (~4000+ glyphs) and cannot search. An earlier session sketched a picker (memory: `2026-04-25 03:55`) but the work was never committed.

## Goals

- Let parents pick from full Hugeicons catalog with search.
- Default to a small curated set per form context (mission vs reward) so the common case stays one click.
- Standardize storage on raw Hugeicons slugs so the database has a single source of truth.

## Non-goals

- Custom uploaded SVGs.
- Per-family icon favorites or recents.
- Color picker for the icon preview (stays category-driven).
- Bulk reassignment UI.

## Architecture

### New ViewComponent: `Ui::IconPicker::Component`

Args:
- `field_name:` — form field name (e.g. `"global_task[icon]"`).
- `value:` — current slug (raw Hugeicons slug, e.g. `"bed-single-01"`).
- `context:` — `:mission`, `:reward`, or `:any`. Drives Sugeridos tab default subset.
- `color:` — preview tile tint (CSS variable string, e.g. `"var(--primary)"`).
- `id:` — DOM id used to associate the trigger with form labels.

Renders:
- Hidden input bound to `field_name`, value = `value`.
- Clickable preview button styled like existing `Ui::IconTile` showing the current icon.
- A `Ui::Modal` with the picker content (see Modal anatomy below).

### New Stimulus controller: `icon_picker_controller.js`

Targets: `hiddenInput`, `previewIcon`, `modal`, `searchInput`, `curatedGrid`, `catalogGrid`, `tabCurated`, `tabCatalog`, `loadMoreBtn`, `confirmBtn`.

Behavior:
- Lazy-loads `/hugeicons-manifest.json` on first modal open.
- Caches manifest on `window.__hugeiconsManifest` to avoid repeat fetches across multiple pickers on the same page.
- Substring fuzzy search across `name` and `tags`. No external dependency.
- Catalog tab paginates: 60 tiles per page, "Carregar mais" button. No infinite scroll.
- Search query length ≥ 2 auto-flips to Todos tab and applies filter to manifest.
- Tile click toggles a pending selection (visual only).
- Confirm writes pending selection to hidden input, updates preview tile, closes modal, dispatches `change` event on hidden input.
- Cancel, ESC, backdrop click → discard pending selection, close.

### Manifest

File: `app/assets/builds/hugeicons-manifest.json`

Shape:
```json
[
  { "slug": "bed-single-01", "name": "bed single 01", "tags": ["bed", "sleep", "bedroom"] }
]
```

Build:
- `lib/tasks/icons.rake` defines `rake icons:sync`.
- Reads `db/seeds/hugeicons_seed.json` (committed seed). Post-processes into manifest.
- MCP `mcp__hugeicons__list_icons` is invoked manually inside a Claude Code session to (re)generate the seed; the rake task does not call MCP.
- Initial seed is generated during implementation and committed.

### Data model migration

`db/migrate/<ts>_convert_icon_keys_to_hugeicons_slugs.rb`:
- Rewrites `global_tasks.icon` and `rewards.icon` from curated keys (e.g. `"bed"`) to raw Hugeicons slugs (e.g. `"bed-single-01"`).
- Lookup table is inlined in the migration (snapshot of current `Ui::Icon::Component::HUGEICONS_MAP`) to decouple from runtime code.
- Skips rows where `icon` is blank or already contains `-` (treated as raw slug).
- `down` is a no-op (alias inversion is lossy).

### `Ui::Icon::Component`

Unchanged. The existing fallback (`HUGEICONS_MAP[name] || name`) lets post-migration raw slugs pass through. Code-level shorthand calls in views (`render Ui::Icon::Component.new("trash")`) keep working through the alias map.

### Forms

`app/views/parent/global_tasks/_form.html.erb`:
- Replace the `icon_options` array and the radio grid with `<%= render Ui::IconPicker::Component.new(field_name: "global_task[icon]", value: global_task.icon, context: :mission, color: "var(--c-#{cat_data[:color]})") %>`.
- Remove the standalone `Ui::IconTile` preview row above the picker. The preview tile lives inside `Ui::IconPicker::Component` (no duplicate preview).

`app/views/parent/rewards/_form.html.erb`:
- Same swap with `context: :reward`.

## Modal anatomy

```
┌─────────────────────────────────────┐
│ Escolher ícone               [×]    │
├─────────────────────────────────────┤
│ [🔍 Buscar...                    ]  │
├─────────────────────────────────────┤
│  [ Sugeridos ]  [ Todos ]            │
├─────────────────────────────────────┤
│                                     │
│  ▢ ▢ ▢ ▢ ▢ ▢ ▢                     │
│  ▢ ▢ ▢ ▢ ▢ ▢ ▢                     │
│  ▢ ▢ ▢ ▢ ▢ ▢ ▢                     │
│                                     │
│  [ Carregar mais (60 de 4127) ]     │
├─────────────────────────────────────┤
│           [ Cancelar ] [ Confirmar ]│
└─────────────────────────────────────┘
```

Tab semantics:
- **Sugeridos** is default when `context != :any`. Mission context → `missions` group from `HUGEICONS_MAP`. Reward context → `shop` group. ~10–15 tiles, no pagination.
- **Todos** is the full manifest. Pagination via Carregar mais. Search auto-flips to this tab when query length ≥ 2.

Tile state:
- Default: 44×44, white background, `border-2 border-hairline`, rounded-xl.
- Hover: `border-primary`.
- Selected (matches hidden input value): `bg-primary-soft border-primary`.

Layout:
- Grid: 7 columns desktop, 5 columns mobile.

## Testing

- `spec/components/ui/icon_picker/component_spec.rb` — renders hidden input, preview tile, and modal markup; selected slug applies the selected tile state.
- `spec/system/parent/icon_picker_spec.rb` — open modal from mission new form, type "bed" in search, click a tile, confirm, save form, assert persisted slug on `GlobalTask.icon`.
- `spec/migrations/convert_icon_keys_to_hugeicons_slugs_spec.rb` — fixture rows with curated keys are migrated to slugs; re-running migration is idempotent.
- No Stimulus unit tests (test runner not configured in repo); behavior covered by the system spec.

## Rollout sequence

1. Generate seed + manifest, add `rake icons:sync`. Commit.
2. Add `Ui::IconPicker::Component` + Stimulus controller + component spec. Commit.
3. Wire forms (`global_tasks/_form`, `rewards/_form`). Commit.
4. Add migration + migration spec. Commit.
5. Run full RSpec suite + manual smoke (mission edit, reward edit, search "estrela", confirm).

## Open questions resolved during brainstorming

- Q1 catalog source → C (curated tab + full catalog tab).
- Q2 storage format → A (always raw `hgi-*` slug; migrate existing data).
- Q3 picker surface → B (modal with tabs).
- Q4 catalog backend → A (static JSON manifest, client-side search).
- Q5 curated grouping → C (context-filtered: `:mission` / `:reward` / `:any`).

## Out of scope (explicit, for plan-phase reference)

- Custom uploaded SVGs.
- Per-family icon favorites / recents.
- Bulk icon reassignment.
- Color picker.
- Refactor of `Ui::Icon::Component` HUGEICONS_MAP (kept as code-level alias only).

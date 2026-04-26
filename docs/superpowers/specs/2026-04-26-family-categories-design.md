# Family-Scoped Custom Categories + Kid Shop Filter Wiring

**Date:** 2026-04-26
**Status:** Design — pending plan
**Scope:** Replace `Reward.category` enum with a family-scoped `Category` model. Add parent CRUD UI for managing categories. Wire kid shop category tabs to actually filter rewards.

---

## Motivation

Two related problems:

1. **Kid shop tabs are dead clicks.** `app/views/kid/rewards/index.html.erb` renders `Ui::CategoryTabs` with hardcoded labels (Telinha, Docinhos, Passeios, Brinquedos, Experiências). Each tab targets an empty stub panel — no filtering happens. Reward.category enum exists but is never used to drive the UI.
2. **Categories are global, not family-customizable.** The fixed enum (`tela / doce / passeio / brinquedo / experiencia / outro`) cannot adapt to a family's actual reward landscape. Parents cannot rename, reorder, recolor, add, or remove categories.

Goal: ship custom per-family categories AND fix the kid shop filter in one coherent change.

## Non-Goals

- Position drag-reorder UI (column reserved, manual ordering deferred)
- i18n of seed defaults (Brazilian Portuguese baked in)
- Soft-delete / archive (full delete only, blocked when rewards attached)
- Per-kid category visibility (categories are global per family)
- Custom hex color input (palette of 8 token colors only)
- Backfill of existing rewards (dev-only project — `db:reset` is acceptable)

## Architecture

### Data model

New `Category` table:

```
categories
  id            bigint primary key
  family_id     bigint NOT NULL  (FK → families, indexed)
  name          string  NOT NULL
  icon          string  NOT NULL  (Lucide/Phosphor key)
  color         string  NOT NULL  (palette token key, e.g. "sky", "rose")
  position      integer NOT NULL  default 0
  created_at, updated_at

  unique index (family_id, name)
  index (family_id, position)
```

`Reward` schema change:
- Drop `category` enum integer column
- Add `category_id` bigint NOT NULL, FK → categories, indexed

Associations:
- `Family has_many :categories, dependent: :destroy`
- `Category belongs_to :family`
- `Category has_many :rewards, dependent: :restrict_with_error`
- `Reward belongs_to :category`

### Default seed on family creation

`Categories::SeedDefaultsService.call(family)` creates 6 defaults in a transaction:

| name           | icon       | color     |
|----------------|------------|-----------|
| Telinha        | tv         | sky       |
| Docinhos       | candy      | rose      |
| Passeios       | tree-pine  | mint      |
| Brinquedos     | gift       | amber     |
| Experiências   | sparkles   | lilac     |
| Outro          | package    | surface-2 |

(Icon keys subject to confirmation against current `Ui::IconPicker` registry.)

Service is idempotent: skips if family already has any categories. Wired via `after_create` on `Family` (or into existing family creation service if one exists in the codebase — to verify during planning).

### Routes + Controllers

```
resources :categories, only: %i[index new create edit update destroy], controller: "categories"
# nested under parent namespace
```

`Parent::CategoriesController`:
- `before_action :require_parent!` (existing concern)
- All queries scoped `Category.where(family_id: current_profile.family_id)`
- `destroy` rescues `ActiveRecord::DeleteRestrictionError`, sets flash error: `"Reatribua os prêmios antes de excluir esta categoria."`
- `category_params`: `:name, :icon, :color`
- Cross-family access returns 404 (scope-then-find)

Reward form: replace enum select with family-scoped category dropdown ordered by `position, created_at`.

### Service Objects

- `Categories::SeedDefaultsService` — idempotent default seed. Wraps in `ActiveRecord::Base.transaction`. Returns `OpenStruct(success?:, error:)` per project convention.
- `Categories::DestroyService` — optional helper wrapping `restrict_with_error` semantic; controller may suffice. Decision deferred to plan phase.

No points / ActivityLog impact.

### UI tokens

`Ui::Tokens` changes:
- Drop `REWARD_CATEGORIES` constant
- Drop `reward_category_for(key)`
- Add `CATEGORY_COLOR_PALETTE` — 8 entries `{ key:, label:, swatch_var:, tint_var: }` covering sky / rose / mint / amber / lilac / violet / peach / surface-2

Components reading tints (`RewardTile`, `FeaturedRewardCard`) read from `reward.category.color` → palette map.

### Views + Components

**Parent sidebar** (`app/views/shared/_parent_nav.html.erb`): add "Categorias" item between "Prêmios" and "Aprovações". Use `tag` icon or similar.

**`/parent/categories` (index)**:
- `Ui::TopBar` with "Nova categoria" CTA in right slot
- 1-col list of `Ui::CategoryRow::Component` (NEW): icon disc tinted with category color, name, `N prêmios` count, Edit/Delete actions
- Empty state if zero (rare — only if user deleted everything)

**`/parent/categories/new` + `edit`** form:
- Name text field
- `Ui::IconPicker::Component.new(context: :reward)` — reuse existing picker
- Color picker: radio group of 8 swatches from `CATEGORY_COLOR_PALETTE`
- Save / Cancel buttons matching existing parent form pattern

**Reward form** (`app/views/parent/rewards/_form.html.erb`):
- Swap `Ui::Select` enum options for category dropdown sourced from family categories

**Kid shop** (`app/views/kid/rewards/index.html.erb`):
- Compute `@categories_with_rewards = Category.where(family_id:).joins(:rewards).distinct.order(:position, :created_at)` in controller
- Build tab items from `@categories_with_rewards`, prepended with `{ id: "all", label: "Tudo" }`
- Switch `Ui::CategoryTabs` controller from `tabs` → `filter-tabs`
- Replace stub-panel pattern with single grid; tag each `RewardTile` wrapper:
  ```erb
  <div data-filter-tabs-target="item" data-panels="all <%= reward.category_id %>">
  ```
- Drop empty stub panel divs
- Tab count badges populated from `@rewards.group_by(&:category_id).transform_values(&:size)`
- Empty categories (zero rewards) are hidden — they never become a tab

### Migration order

1. `create_table :categories` with all columns + indexes
2. `add_reference :rewards, :category, foreign_key: true` (nullable initially)
3. Dev-only: `Reward.delete_all` or `db:reset` (no production data)
4. Re-seed sample family + categories + rewards via `db/seeds.rb` update
5. `change_column_null :rewards, :category_id, false`
6. `remove_column :rewards, :category`

`db:seeds.rb` updates: ensure seed family receives default categories; sample rewards reference seeded categories by name lookup.

### Tests (RSpec)

**Models:**
- `Category` validates presence of name/icon/color
- `Category` validates name uniqueness scoped to family
- `Category` `dependent: :restrict_with_error` blocks destroy when rewards exist
- `Family.create` triggers `SeedDefaultsService` (6 categories created, correct names + icons + colors)
- `Reward.category_id` is required (NOT NULL constraint surfaces validation)

**Services:**
- `Categories::SeedDefaultsService` idempotent (calling twice creates only one set)
- Wrapped in transaction (failure mid-seed rolls back all)

**Requests / controllers:**
- `Parent::CategoriesController` CRUD happy paths
- `destroy` blocked when rewards attached → flash error, category persists
- Non-parent role denied (403 / redirect)
- Cross-family access returns 404 (parent in family A cannot edit category in family B)

**Views / system:**
- Reward form lists family-scoped categories only
- Kid shop hides categories with zero rewards
- Kid shop tabs filter visible reward tiles via `filter-tabs` controller
- `RewardTile` tint reflects `category.color` palette mapping

## Risks / Open Questions

- **Family creation hook location** — codebase may already have a creation service; plan phase confirms whether to use `after_create` callback or extend existing service. Resolved during planning.
- **`Ui::IconPicker` icon registry coverage** — default seed icon keys (tv, candy, tree-pine, etc.) must exist in `CONTEXT_GROUPS[:reward]`. Verify during planning; substitute keys if missing.
- **Color palette token coverage** — `surface-2` may not be visually distinct as a category color. Plan phase may swap for `peach-soft` or similar.
- **Sample data** — `db/seeds.rb` likely references reward categories by enum value. Update seeds in same migration step.

## Acceptance criteria

1. Parent can navigate to `/parent/categories`, see seeded defaults, create a new category, edit one, and delete one with no attached rewards.
2. Parent attempting to delete a category with attached rewards sees flash error and category persists.
3. Reward form's category dropdown lists only the current family's categories.
4. Kid shop tabs reflect only categories that have ≥1 reward in the current family.
5. Clicking a tab filters reward tiles to that category without page reload.
6. Reward tile tint matches its category's selected color.
7. New family creation seeds 6 default categories.
8. Full RSpec suite green; rubocop clean; brakeman clean.

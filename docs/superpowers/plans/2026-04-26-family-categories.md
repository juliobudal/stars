# Family-Scoped Custom Categories Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `Reward.category` enum with a family-scoped `Category` model, add parent CRUD UI for managing categories, and wire the kid shop tabs to actually filter rewards.

**Architecture:** New `Category` model (family-scoped) with `name + icon + color + position` columns. `Reward.category_id` FK replaces enum. New family creation seeds 6 default categories via service called from `after_create` callback. Parent gets `/parent/categories` CRUD section. Kid shop swaps `tabs` controller for `filter-tabs` to filter the visible reward grid by `category_id`. Empty-of-rewards categories are hidden from the kid shop.

**Tech Stack:** Rails 8.1, PostgreSQL, RSpec, FactoryBot, ViewComponent, Stimulus.

**Spec:** `docs/superpowers/specs/2026-04-26-family-categories-design.md`

---

## File Structure

**New files:**
- `db/migrate/<ts>_create_categories.rb` — schema
- `db/migrate/<ts>_add_category_to_rewards.rb` — FK column
- `db/migrate/<ts>_remove_category_enum_from_rewards.rb` — drop enum
- `app/models/category.rb` — model + validations
- `app/services/categories/seed_defaults_service.rb` — default seeder
- `app/controllers/parent/categories_controller.rb` — CRUD
- `app/views/parent/categories/index.html.erb`
- `app/views/parent/categories/new.html.erb`
- `app/views/parent/categories/edit.html.erb`
- `app/views/parent/categories/_form.html.erb`
- `app/components/ui/category_row/component.rb` — list row
- `app/components/ui/category_row/component.html.erb`
- `app/components/ui/color_swatch_picker/component.rb` — radio palette
- `app/components/ui/color_swatch_picker/component.html.erb`
- `spec/factories/categories.rb`
- `spec/models/category_spec.rb`
- `spec/services/categories/seed_defaults_service_spec.rb`
- `spec/requests/parent/categories_spec.rb`
- `spec/system/parent/categories_management_spec.rb`
- `spec/system/kid/shop_filter_spec.rb`

**Modified files:**
- `config/routes.rb` — add resource
- `app/models/family.rb` — `has_many :categories`, `after_create :seed_default_categories`
- `app/models/reward.rb` — drop enum, add `belongs_to :category`
- `app/components/ui/tokens.rb` — add `CATEGORY_COLOR_PALETTE`, drop `REWARD_CATEGORIES` + `reward_category_for`
- `app/views/shared/_parent_nav.html.erb` — add "Categorias" nav item
- `app/views/parent/rewards/_form.html.erb` — replace enum select with category dropdown
- `app/controllers/parent/rewards_controller.rb` — load `@categories` for form, permit `:category_id`
- `app/views/parent/rewards/index.html.erb` — switch chip source to `@categories`
- `app/controllers/kid/rewards_controller.rb` — load `@categories_with_rewards`
- `app/views/kid/rewards/index.html.erb` — switch to `filter-tabs`, single grid, dynamic categories
- `app/components/ui/reward_tile/component.html.erb` — tint from `reward.category.color`
- `app/components/ui/featured_reward_card/component.rb` (or html.erb) — tint from `reward.category.color`
- `db/seeds.rb` — replace enum keys with category lookups
- `spec/factories/rewards.rb` — pull category from family

---

## Task 1: Migration — create `categories` table

**Files:**
- Create: `db/migrate/<ts>_create_categories.rb`

- [ ] **Step 1: Generate the migration**

Run:
```bash
bin/rails generate migration CreateCategories
```

- [ ] **Step 2: Replace the migration body**

```ruby
class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :family, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.string :icon, null: false
      t.string :color, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :categories, [:family_id, :name], unique: true
    add_index :categories, [:family_id, :position]
  end
end
```

- [ ] **Step 3: Run the migration**

Run:
```bash
bin/rails db:migrate
```
Expected: `categories` table created. No errors.

- [ ] **Step 4: Commit**

```bash
git add db/migrate db/schema.rb
git commit -m "db: add categories table (family-scoped name/icon/color/position)"
```

---

## Task 2: `Category` model + factory

**Files:**
- Create: `app/models/category.rb`
- Create: `spec/factories/categories.rb`
- Create: `spec/models/category_spec.rb`

- [ ] **Step 1: Write the failing model spec**

```ruby
# spec/models/category_spec.rb
require "rails_helper"

RSpec.describe Category, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:family) }
    it { is_expected.to have_many(:rewards).dependent(:restrict_with_error) }
  end

  describe "validations" do
    subject { build(:category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:icon) }
    it { is_expected.to validate_presence_of(:color) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:family_id).case_insensitive }
  end

  describe "ordering" do
    it "orders by position then created_at via .ordered scope" do
      family = create(:family)
      a = create(:category, family: family, name: "A", position: 2)
      b = create(:category, family: family, name: "B", position: 1)
      expect(family.categories.ordered).to eq([b, a])
    end
  end
end
```

- [ ] **Step 2: Write the factory**

```ruby
# spec/factories/categories.rb
FactoryBot.define do
  factory :category do
    family
    sequence(:name) { |n| "Categoria #{n}" }
    icon { "bookmark-01" }
    color { "lilac" }
    position { 0 }
  end
end
```

- [ ] **Step 3: Run the spec to confirm failure**

Run:
```bash
bundle exec rspec spec/models/category_spec.rb
```
Expected: FAIL — `uninitialized constant Category`.

- [ ] **Step 4: Create the model**

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  belongs_to :family
  has_many :rewards, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :family_id, case_sensitive: false }
  validates :icon, presence: true
  validates :color, presence: true

  scope :ordered, -> { order(:position, :created_at) }
end
```

- [ ] **Step 5: Add association to `Family`**

In `app/models/family.rb`, add inside the class body, near existing `has_many` declarations:

```ruby
  has_many :categories, dependent: :destroy
```

- [ ] **Step 6: Run the spec to confirm pass**

Run:
```bash
bundle exec rspec spec/models/category_spec.rb
```
Expected: PASS, all examples green.

- [ ] **Step 7: Commit**

```bash
git add app/models/category.rb app/models/family.rb spec/factories/categories.rb spec/models/category_spec.rb
git commit -m "model(category): family-scoped category with name/icon/color/position"
```

---

## Task 3: `Categories::SeedDefaultsService` + `Family` after_create hook

**Files:**
- Create: `app/services/categories/seed_defaults_service.rb`
- Create: `spec/services/categories/seed_defaults_service_spec.rb`
- Modify: `app/models/family.rb`
- Modify: `spec/models/family_spec.rb`

- [ ] **Step 1: Write the failing service spec**

```ruby
# spec/services/categories/seed_defaults_service_spec.rb
require "rails_helper"

RSpec.describe Categories::SeedDefaultsService do
  let(:family) { create(:family) }

  it "creates 6 default categories with correct names" do
    family.categories.delete_all
    described_class.call(family)
    names = family.categories.reload.pluck(:name)
    expect(names).to match_array(%w[Telinha Docinhos Passeios Brinquedos Experiências Outro])
  end

  it "assigns icon and color to each default" do
    family.categories.delete_all
    described_class.call(family)
    family.categories.reload.each do |c|
      expect(c.icon).to be_present
      expect(c.color).to be_present
    end
  end

  it "is idempotent — second call creates no extra rows" do
    described_class.call(family)
    expect { described_class.call(family) }.not_to change { family.categories.count }
  end

  it "rolls back all inserts when one default is invalid" do
    allow(family.categories).to receive(:create!).and_wrap_original do |orig, *args, &block|
      raise ActiveRecord::RecordInvalid.new(Category.new) if family.categories.count == 2
      orig.call(*args, &block)
    end
    family.categories.delete_all
    expect { described_class.call(family) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(family.categories.reload).to be_empty
  end
end
```

- [ ] **Step 2: Run the spec to confirm failure**

Run:
```bash
bundle exec rspec spec/services/categories/seed_defaults_service_spec.rb
```
Expected: FAIL — `uninitialized constant Categories::SeedDefaultsService`.

- [ ] **Step 3: Create the service**

```ruby
# app/services/categories/seed_defaults_service.rb
require "ostruct"

module Categories
  class SeedDefaultsService
    DEFAULTS = [
      { name: "Telinha",      icon: "game-controller-01", color: "sky"   },
      { name: "Docinhos",     icon: "ice-cream-01",        color: "rose"  },
      { name: "Passeios",     icon: "ferris-wheel",        color: "mint"  },
      { name: "Brinquedos",   icon: "cube",                color: "amber" },
      { name: "Experiências", icon: "gift",                color: "lilac" },
      { name: "Outro",        icon: "bookmark-01",         color: "peach" }
    ].freeze

    def initialize(family)
      @family = family
    end

    def self.call(family)
      new(family).call
    end

    def call
      return OpenStruct.new(success?: true, error: nil) if @family.categories.exists?

      ActiveRecord::Base.transaction do
        DEFAULTS.each_with_index do |attrs, index|
          @family.categories.create!(attrs.merge(position: index))
        end
      end

      OpenStruct.new(success?: true, error: nil)
    end
  end
end
```

- [ ] **Step 4: Run the spec to confirm pass**

Run:
```bash
bundle exec rspec spec/services/categories/seed_defaults_service_spec.rb
```
Expected: PASS.

- [ ] **Step 5: Wire `after_create` callback on `Family`**

Edit `app/models/family.rb` and add inside the class body:

```ruby
  after_create :seed_default_categories

  private

  def seed_default_categories
    Categories::SeedDefaultsService.call(self)
  end
```

(If a `private` block already exists, place `seed_default_categories` there and the callback line in the public area above it.)

- [ ] **Step 6: Add Family-side spec for the callback**

Append to `spec/models/family_spec.rb` inside the top-level `describe Family`:

```ruby
  describe "after_create" do
    it "seeds 6 default categories" do
      family = create(:family)
      expect(family.categories.pluck(:name)).to match_array(
        %w[Telinha Docinhos Passeios Brinquedos Experiências Outro]
      )
    end
  end
```

- [ ] **Step 7: Run both specs to confirm pass**

Run:
```bash
bundle exec rspec spec/services/categories/seed_defaults_service_spec.rb spec/models/family_spec.rb
```
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add app/services/categories app/models/family.rb spec/services/categories spec/models/family_spec.rb
git commit -m "service(categories): seed 6 defaults on family create"
```

---

## Task 4: Migration — `rewards.category_id` FK and drop enum

**Files:**
- Create: `db/migrate/<ts>_add_category_to_rewards.rb`
- Create: `db/migrate/<ts>_remove_category_enum_from_rewards.rb`

- [ ] **Step 1: Generate add-FK migration**

Run:
```bash
bin/rails generate migration AddCategoryToRewards
```

Replace body:

```ruby
class AddCategoryToRewards < ActiveRecord::Migration[8.1]
  def change
    add_reference :rewards, :category, null: true, foreign_key: true, index: true
  end
end
```

- [ ] **Step 2: Run migration**

Run:
```bash
bin/rails db:migrate
```
Expected: column added, nullable.

- [ ] **Step 3: Wipe existing reward rows (dev only)**

Run:
```bash
bin/rails runner 'Reward.delete_all'
```
Expected: no error. Acceptable per spec (dev-only project, no backfill).

- [ ] **Step 4: Generate drop-enum migration**

Run:
```bash
bin/rails generate migration RemoveCategoryEnumFromRewards
```

Replace body:

```ruby
class RemoveCategoryEnumFromRewards < ActiveRecord::Migration[8.1]
  def up
    change_column_null :rewards, :category_id, false
    remove_column :rewards, :category
  end

  def down
    add_column :rewards, :category, :integer, default: 5, null: false
    change_column_null :rewards, :category_id, true
  end
end
```

- [ ] **Step 5: Run migration**

Run:
```bash
bin/rails db:migrate
```
Expected: enum column removed, FK now NOT NULL.

- [ ] **Step 6: Commit**

```bash
git add db/migrate db/schema.rb
git commit -m "db(rewards): replace category enum with category_id FK"
```

---

## Task 5: Update `Reward` model + factory

**Files:**
- Modify: `app/models/reward.rb`
- Modify: `spec/factories/rewards.rb`
- Modify: `spec/models/reward_spec.rb`

- [ ] **Step 1: Update reward spec to drop enum expectations and add category belongs_to**

Replace `spec/models/reward_spec.rb` content with:

```ruby
require "rails_helper"

RSpec.describe Reward, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:family) }
    it { is_expected.to belong_to(:category) }
  end

  describe "validations" do
    subject { build(:reward) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_numericality_of(:cost).is_greater_than(0) }
  end

  describe "category restriction on delete" do
    it "blocks category delete when reward is attached" do
      family = create(:family)
      category = family.categories.first
      create(:reward, family: family, category: category)
      expect { category.destroy }.not_to change { Category.count }
      expect(category.errors[:base]).to include(/Cannot delete record because dependent rewards exist/i)
    end
  end
end
```

- [ ] **Step 2: Run spec to confirm failure**

Run:
```bash
bundle exec rspec spec/models/reward_spec.rb
```
Expected: FAIL on category belongs_to and on factory not assigning a category.

- [ ] **Step 3: Update the Reward model**

Replace the contents of `app/models/reward.rb`:

```ruby
class Reward < ApplicationRecord
  belongs_to :family
  belongs_to :category

  validates :title, presence: true
  validates :cost, numericality: { greater_than: 0 }

  validate :category_belongs_to_same_family

  private

  def category_belongs_to_same_family
    return if category.nil? || family_id.nil?
    errors.add(:category, "must belong to the same family") if category.family_id != family_id
  end
end
```

- [ ] **Step 4: Update the reward factory**

Replace `spec/factories/rewards.rb` content with:

```ruby
FactoryBot.define do
  factory :reward do
    family
    title { Faker::Commerce.product_name }
    cost { 50 }
    icon { nil }
    category { family.categories.first || association(:category, family: family) }
  end
end
```

- [ ] **Step 5: Run spec to confirm pass**

Run:
```bash
bundle exec rspec spec/models/reward_spec.rb
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add app/models/reward.rb spec/models/reward_spec.rb spec/factories/rewards.rb
git commit -m "model(reward): belongs_to category, restrict_with_error on parent"
```

---

## Task 6: `Ui::Tokens` palette + drop reward enum helper

**Files:**
- Modify: `app/components/ui/tokens.rb`

- [ ] **Step 1: Find usages of `REWARD_CATEGORIES` and `reward_category_for` to confirm scope**

Run:
```bash
grep -rn "REWARD_CATEGORIES\|reward_category_for" app/ spec/
```
Expected output: matches in `app/components/ui/tokens.rb`, `app/views/parent/rewards/_form.html.erb`, `app/views/parent/rewards/index.html.erb`, and any reward-tile components. Note all matches — they will be replaced in Tasks 9, 11, 12, 13.

- [ ] **Step 2: Replace the Tokens module**

Replace `app/components/ui/tokens.rb` content with:

```ruby
# frozen_string_literal: true

module Ui
  module Tokens
    MISSION_CATEGORIES = {
      "casa"   => { label: "Casa",   icon: "home",    tint: "mint"  },
      "escola" => { label: "Escola", icon: "book",    tint: "lilac" },
      "rotina" => { label: "Rotina", icon: "brush",   tint: "rose"  },
      "saude"  => { label: "Saúde",  icon: "muscle",  tint: "star"  },
      "geral"  => { label: "Geral",  icon: "sparkle", tint: "sky"   },
      "outro"  => { label: "Outro",  icon: "sparkle", tint: "sky"   }
    }.freeze

    FREQUENCIES = {
      "daily"   => { label: "Todo dia",  tint: "mint"  },
      "weekly"  => { label: "Semanal",   tint: "sky"   },
      "monthly" => { label: "Mensal",    tint: "lilac" },
      "once"    => { label: "Única vez", tint: "rose"  }
    }.freeze

    CATEGORY_COLOR_PALETTE = {
      "sky"   => { label: "Céu",     soft_var: "var(--c-sky-soft)",   fg_var: "var(--c-sky)"   },
      "rose"  => { label: "Rosa",    soft_var: "var(--c-rose-soft)",  fg_var: "var(--c-rose)"  },
      "mint"  => { label: "Menta",   soft_var: "var(--c-mint-soft)",  fg_var: "var(--c-mint)"  },
      "amber" => { label: "Âmbar",   soft_var: "var(--c-amber-soft)", fg_var: "var(--c-amber)" },
      "lilac" => { label: "Lilás",   soft_var: "var(--c-lilac-soft)", fg_var: "var(--c-lilac)" },
      "peach" => { label: "Pêssego", soft_var: "var(--c-peach-soft)", fg_var: "var(--c-peach)" },
      "violet"=> { label: "Violeta", soft_var: "var(--c-violet-soft)",fg_var: "var(--c-violet)"},
      "star"  => { label: "Dourado", soft_var: "var(--c-star-soft)",  fg_var: "var(--c-star)"  }
    }.freeze

    def self.category_for(key)
      MISSION_CATEGORIES.fetch(key.to_s, MISSION_CATEGORIES["geral"])
    end

    def self.frequency_for(key)
      FREQUENCIES.fetch(key.to_s, FREQUENCIES["daily"])
    end

    def self.color_palette_entry(key)
      CATEGORY_COLOR_PALETTE.fetch(key.to_s, CATEGORY_COLOR_PALETTE["lilac"])
    end

    def self.tint_soft(name)
      name.to_s == "primary" ? "var(--primary-soft)" : "var(--c-#{name}-soft)"
    end

    def self.tint_fg(name)
      name.to_s == "primary" ? "var(--primary)" : "var(--c-#{name})"
    end
  end
end
```

- [ ] **Step 3: Commit**

```bash
git add app/components/ui/tokens.rb
git commit -m "tokens: add CATEGORY_COLOR_PALETTE, drop REWARD_CATEGORIES enum helper"
```

Note: leaving `_form.html.erb` and `index.html.erb` references temporarily broken — fixed in Tasks 11–12. Specs touching these views will be skipped or red until then; this is OK since we run the full suite green only at the end.

---

## Task 7: Routes + `Parent::CategoriesController`

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/parent/categories_controller.rb`
- Create: `spec/requests/parent/categories_spec.rb`

- [ ] **Step 1: Add route**

In `config/routes.rb`, locate the `namespace :parent do` block and add inside:

```ruby
    resources :categories
```

Confirm placement next to `resources :rewards`.

- [ ] **Step 2: Write the failing request spec**

```ruby
# spec/requests/parent/categories_spec.rb
require "rails_helper"

RSpec.describe "Parent::Categories", type: :request do
  let(:family) { create(:family) }
  let(:parent) { create(:profile, :parent, family: family) }

  before { sign_in_as(parent) } # rely on existing helper used elsewhere; if absent, use existing pattern from spec/requests/parent/rewards_spec.rb

  describe "GET /parent/categories" do
    it "lists current family's categories" do
      get parent_categories_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Telinha")
    end
  end

  describe "POST /parent/categories" do
    it "creates a category" do
      expect {
        post parent_categories_path, params: {
          category: { name: "Música", icon: "bookmark-01", color: "violet" }
        }
      }.to change { family.categories.count }.by(1)
      expect(response).to redirect_to(parent_categories_path)
    end
  end

  describe "PATCH /parent/categories/:id" do
    it "updates the category" do
      cat = family.categories.first
      patch parent_category_path(cat), params: { category: { name: "Tela & Jogos", icon: cat.icon, color: cat.color } }
      expect(cat.reload.name).to eq("Tela & Jogos")
    end
  end

  describe "DELETE /parent/categories/:id" do
    it "destroys an empty category" do
      cat = create(:category, family: family, name: "Vazia")
      expect {
        delete parent_category_path(cat)
      }.to change { family.categories.count }.by(-1)
    end

    it "blocks delete when rewards are attached" do
      cat = family.categories.first
      create(:reward, family: family, category: cat)
      expect {
        delete parent_category_path(cat)
      }.not_to change { family.categories.count }
      expect(flash[:alert]).to match(/reatribua/i)
    end

    it "returns 404 for cross-family access" do
      other = create(:category, family: create(:family))
      delete parent_category_path(other)
      expect(response).to have_http_status(:not_found)
    end
  end
end
```

(If `sign_in_as` is unavailable, copy the auth setup from `spec/requests/parent/rewards_spec.rb` verbatim.)

- [ ] **Step 3: Run spec to confirm failure**

Run:
```bash
bundle exec rspec spec/requests/parent/categories_spec.rb
```
Expected: FAIL — `uninitialized constant Parent::CategoriesController` or routing error.

- [ ] **Step 4: Create the controller**

```ruby
# app/controllers/parent/categories_controller.rb
class Parent::CategoriesController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  before_action :set_category, only: [:edit, :update, :destroy]

  layout "parent"

  def index
    @categories = scope.ordered
  end

  def new
    @category = scope.new
  end

  def create
    @category = scope.new(category_params)
    if @category.save
      redirect_to parent_categories_path, notice: "Categoria criada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to parent_categories_path, notice: "Categoria atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.destroy
      redirect_to parent_categories_path, notice: "Categoria removida."
    else
      redirect_to parent_categories_path,
                  alert: "Reatribua os prêmios antes de excluir esta categoria."
    end
  end

  private

  def scope
    Category.where(family_id: current_profile.family_id)
  end

  def set_category
    @category = scope.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :icon, :color)
  end
end
```

- [ ] **Step 5: Run spec to confirm pass**

Run:
```bash
bundle exec rspec spec/requests/parent/categories_spec.rb
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add config/routes.rb app/controllers/parent/categories_controller.rb spec/requests/parent/categories_spec.rb
git commit -m "feat(parent): categories CRUD controller + routes + request specs"
```

---

## Task 8: `Ui::ColorSwatchPicker` ViewComponent

**Files:**
- Create: `app/components/ui/color_swatch_picker/component.rb`
- Create: `app/components/ui/color_swatch_picker/component.html.erb`

- [ ] **Step 1: Create the component class**

```ruby
# app/components/ui/color_swatch_picker/component.rb
# frozen_string_literal: true

module Ui
  module ColorSwatchPicker
    class Component < ApplicationComponent
      def initialize(field_name:, value: nil, id: nil)
        @field_name = field_name
        @value = (value.presence || Ui::Tokens::CATEGORY_COLOR_PALETTE.keys.first).to_s
        @id = id || "color_swatch_picker_#{SecureRandom.hex(4)}"
        super()
      end

      attr_reader :field_name, :value, :id

      def palette
        Ui::Tokens::CATEGORY_COLOR_PALETTE
      end
    end
  end
end
```

- [ ] **Step 2: Create the template**

```erb
<%# app/components/ui/color_swatch_picker/component.html.erb %>
<div id="<%= id %>" class="flex flex-wrap gap-2.5">
  <% palette.each do |key, meta| %>
    <% checked = key == value %>
    <label class="relative cursor-pointer">
      <input type="radio"
             name="<%= field_name %>"
             value="<%= key %>"
             class="peer sr-only"
             <%= "checked" if checked %>>
      <span class="block w-10 h-10 rounded-full border-2 border-hairline peer-checked:border-foreground peer-checked:scale-110 transition-transform"
            style="background: <%= meta[:soft_var] %>;"
            title="<%= meta[:label] %>">
      </span>
    </label>
  <% end %>
</div>
```

- [ ] **Step 3: Commit**

```bash
git add app/components/ui/color_swatch_picker
git commit -m "feat(ui): ColorSwatchPicker component for category color selection"
```

---

## Task 9: `Ui::CategoryRow` ViewComponent

**Files:**
- Create: `app/components/ui/category_row/component.rb`
- Create: `app/components/ui/category_row/component.html.erb`

- [ ] **Step 1: Create the component class**

```ruby
# app/components/ui/category_row/component.rb
# frozen_string_literal: true

module Ui
  module CategoryRow
    class Component < ApplicationComponent
      def initialize(category:, reward_count:)
        @category = category
        @reward_count = reward_count.to_i
        super()
      end

      attr_reader :category, :reward_count

      def palette
        Ui::Tokens.color_palette_entry(category.color)
      end
    end
  end
end
```

- [ ] **Step 2: Create the template**

```erb
<%# app/components/ui/category_row/component.html.erb %>
<div class="flex items-center justify-between bg-white border-2 border-hairline rounded-2xl px-4 py-3 shadow-sm">
  <div class="flex items-center gap-3">
    <div class="w-11 h-11 rounded-xl flex items-center justify-center"
         style="background: <%= palette[:soft_var] %>;">
      <%= render Ui::Icon::Component.new(category.icon, size: 22, color: palette[:fg_var]) %>
    </div>
    <div class="flex flex-col">
      <span class="font-display font-extrabold text-[16px] tracking-[-0.02em] text-foreground"><%= category.name %></span>
      <span class="text-[13px] font-semibold text-muted-foreground"><%= reward_count %> <%= reward_count == 1 ? "prêmio" : "prêmios" %></span>
    </div>
  </div>
  <div class="flex items-center gap-2">
    <%= link_to edit_parent_category_path(category),
          class: "text-[13px] font-extrabold text-primary px-3 py-2 rounded-lg hover:bg-primary-soft" do %>
      Editar
    <% end %>
    <%= button_to parent_category_path(category),
          method: :delete,
          form_class: "inline",
          class: "text-[13px] font-extrabold text-danger px-3 py-2 rounded-lg hover:bg-danger-soft border-0 bg-transparent",
          data: { turbo_confirm: "Excluir #{category.name}? Categorias com prêmios não podem ser removidas." } do %>
      Excluir
    <% end %>
  </div>
</div>
```

- [ ] **Step 3: Commit**

```bash
git add app/components/ui/category_row
git commit -m "feat(ui): CategoryRow component for parent category list"
```

---

## Task 10: Parent category views (index/new/edit/_form)

**Files:**
- Create: `app/views/parent/categories/index.html.erb`
- Create: `app/views/parent/categories/new.html.erb`
- Create: `app/views/parent/categories/edit.html.erb`
- Create: `app/views/parent/categories/_form.html.erb`

- [ ] **Step 1: Create index view**

```erb
<%# app/views/parent/categories/index.html.erb %>
<% content_for :container_class, "lg:max-w-3xl lg:mx-auto" %>
<%= render Ui::TopBar::Component.new(
  title: "Categorias",
  subtitle: "Organize seus prêmios em grupos"
) do |bar| %>
  <% bar.with_right_slot do %>
    <%= render Ui::Btn::Component.new(variant: "primary", size: "sm", url: new_parent_category_path) do %>
      <%= render Ui::Icon::Component.new("plus", size: 16, color: "white") %> Nova categoria
    <% end %>
  <% end %>
<% end %>

<% reward_counts = Reward.where(family_id: current_profile.family_id).group(:category_id).count %>

<% if @categories.any? %>
  <div class="flex flex-col gap-2.5 mt-2">
    <% @categories.each do |category| %>
      <%= render Ui::CategoryRow::Component.new(category: category, reward_count: reward_counts[category.id].to_i) %>
    <% end %>
  </div>
<% else %>
  <%= render Ui::Empty::Component.new(
    icon: "bookmark-01",
    title: "Nenhuma categoria",
    subtitle: "Crie categorias para agrupar seus prêmios.",
    color: "lilac"
  ) %>
<% end %>
```

- [ ] **Step 2: Create new view**

```erb
<%# app/views/parent/categories/new.html.erb %>
<% content_for :container_class, "lg:max-w-2xl lg:mx-auto" %>
<%= render Ui::TopBar::Component.new(title: "Nova categoria", back_url: parent_categories_path) %>
<%= render "form", category: @category %>
```

- [ ] **Step 3: Create edit view**

```erb
<%# app/views/parent/categories/edit.html.erb %>
<% content_for :container_class, "lg:max-w-2xl lg:mx-auto" %>
<%= render Ui::TopBar::Component.new(title: "Editar categoria", back_url: parent_categories_path) %>
<%= render "form", category: @category %>
```

- [ ] **Step 4: Create _form partial**

```erb
<%# app/views/parent/categories/_form.html.erb %>
<%= form_with(model: [:parent, category], class: "block") do |f| %>
  <% if category.errors.any? %>
    <%= render Ui::Card::Component.new(variant: "flat", class: "bg-danger-soft text-danger p-4 mb-4") do %>
      <%= render Ui::Heading::Component.new(size: :h3) do %>Ops! Algo deu errado:<% end %>
      <ul class="text-[14px] font-semibold list-disc ml-5">
        <% category.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    <% end %>
  <% end %>

  <div class="flex flex-col gap-5">
    <div class="flex flex-col gap-2">
      <%= f.label :name, "Nome", class: "font-display font-extrabold text-[15px] text-foreground tracking-tight" %>
      <%= f.text_field :name,
            class: "w-full px-5 py-4 bg-white border-2 border-hairline rounded-2xl font-semibold text-[17px] text-foreground placeholder:text-muted-foreground focus:border-primary focus:ring-0 transition-all shadow-sm",
            placeholder: "Ex: Música" %>
    </div>

    <div class="flex flex-col gap-2">
      <label class="font-display font-extrabold text-[15px] text-foreground tracking-tight">Ícone</label>
      <%= render Ui::IconPicker::Component.new(
            field_name: "category[icon]",
            value: category.icon.presence || "bookmark-01",
            context: :reward,
            color: "var(--primary)",
            id: "category_icon_picker"
          ) %>
    </div>

    <div class="flex flex-col gap-2">
      <label class="font-display font-extrabold text-[15px] text-foreground tracking-tight">Cor</label>
      <%= render Ui::ColorSwatchPicker::Component.new(
            field_name: "category[color]",
            value: category.color.presence || "lilac"
          ) %>
    </div>

    <div class="flex flex-row mt-4 gap-2.5 justify-end">
      <%= render Ui::Btn::Component.new(variant: "secondary", url: parent_categories_path) do %>Voltar<% end %>
      <%= render Ui::Btn::Component.new(variant: "primary", type: "submit") do %>Salvar<% end %>
    </div>
  </div>
<% end %>
```

- [ ] **Step 5: Smoke-check views render**

Run:
```bash
bundle exec rspec spec/requests/parent/categories_spec.rb
```
Expected: PASS (already added in Task 7; views now render concretely instead of via missing-template error if previously hidden).

- [ ] **Step 6: Commit**

```bash
git add app/views/parent/categories
git commit -m "feat(parent): categories index/new/edit views"
```

---

## Task 11: Add "Categorias" to parent sidebar

**Files:**
- Modify: `app/views/shared/_parent_nav.html.erb`

- [ ] **Step 1: Insert sidebar entry**

In `app/views/shared/_parent_nav.html.erb`, locate the `items = [` array (around line 38) and insert after the "Prêmios" line:

```ruby
        { icon: "bookmark-01", path: parent_categories_path, label: "Categorias" },
```

The full block should now read:

```ruby
      items = [
        { icon: "house", path: parent_root_path, label: "Início" },
        { icon: "users", path: parent_profiles_path, label: "Crianças" },
        { icon: "list-checks", path: parent_global_tasks_path, label: "Missões" },
        { icon: "bag", path: parent_rewards_path, label: "Prêmios" },
        { icon: "bookmark-01", path: parent_categories_path, label: "Categorias" },
        { icon: "clock", path: parent_approvals_path, label: "Aprovações", badge: pending_count > 0 ? pending_count : nil },
        { icon: "gear", path: parent_settings_path, label: "Configurações" }
      ]
```

- [ ] **Step 2: Visual smoke check (optional, manual)**

Start dev server: `bin/dev`. Visit `/parent` while signed in as a parent. Confirm "Categorias" appears between "Prêmios" and "Aprovações". Skip if dev server unavailable.

- [ ] **Step 3: Commit**

```bash
git add app/views/shared/_parent_nav.html.erb
git commit -m "feat(parent-nav): add Categorias sidebar item"
```

---

## Task 12: Reward form — switch enum select to category dropdown

**Files:**
- Modify: `app/controllers/parent/rewards_controller.rb`
- Modify: `app/views/parent/rewards/_form.html.erb`
- Modify: `spec/requests/parent/rewards_spec.rb`

- [ ] **Step 1: Update controller to expose categories and permit category_id**

Replace the body of `app/controllers/parent/rewards_controller.rb` with:

```ruby
class Parent::RewardsController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  before_action :set_categories, only: [:new, :create, :edit, :update]
  before_action :set_reward, only: [:edit, :update, :destroy]

  layout "parent"

  def index
    @rewards = Reward.where(family_id: current_profile.family_id).includes(:category).order(cost: :asc)
    @categories = Category.where(family_id: current_profile.family_id).ordered
  end

  def new
    @reward = Reward.new(family_id: current_profile.family_id)
  end

  def create
    @reward = Reward.new(reward_params.merge(family_id: current_profile.family_id))
    if @reward.save
      redirect_to parent_rewards_path, notice: "Recompensa criada com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @reward.update(reward_params)
      redirect_to parent_rewards_path, notice: "Recompensa atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @reward.destroy
    redirect_to parent_rewards_path, notice: "Recompensa removida."
  end

  private

  def set_categories
    @categories = Category.where(family_id: current_profile.family_id).ordered
  end

  def set_reward
    @reward = Reward.where(family_id: current_profile.family_id).find(params[:id])
  end

  def reward_params
    params.require(:reward).permit(:title, :cost, :icon, :category_id)
  end
end
```

- [ ] **Step 2: Replace category select in reward form**

In `app/views/parent/rewards/_form.html.erb`, locate the existing block:

```erb
      <div class="flex flex-col gap-2">
        <%= f.label :category, "Categoria", ... %>
        <%= render Ui::Select::Component.new(
              name: "reward[category]",
              id: "reward_category",
              options: Reward.categories.keys.map { |k| [Ui::Tokens.reward_category_for(k)[:label].capitalize, k] },
              selected: reward.category,
              size: :lg
            ) %>
      </div>
```

Replace with:

```erb
      <div class="flex flex-col gap-2">
        <%= f.label :category_id, "Categoria", class: "font-display font-extrabold text-[15px] text-foreground tracking-tight" %>
        <%= render Ui::Select::Component.new(
              name: "reward[category_id]",
              id: "reward_category_id",
              options: @categories.map { |c| [c.name, c.id] },
              selected: reward.category_id,
              size: :lg
            ) %>
      </div>
```

- [ ] **Step 3: Update reward request spec to use category_id**

In `spec/requests/parent/rewards_spec.rb`, locate any test using `category: "tela"` (or similar enum string) and replace with `category_id: family.categories.first.id`. Run:

```bash
grep -n "category:" spec/requests/parent/rewards_spec.rb
```

For each match in a `params:` block, swap to `category_id` referencing a real category from the test family.

- [ ] **Step 4: Run reward request specs**

Run:
```bash
bundle exec rspec spec/requests/parent/rewards_spec.rb
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/parent/rewards_controller.rb app/views/parent/rewards/_form.html.erb spec/requests/parent/rewards_spec.rb
git commit -m "feat(parent-rewards): use category_id FK in form + controller"
```

---

## Task 13: Parent rewards index — switch chip source to dynamic categories

**Files:**
- Modify: `app/views/parent/rewards/index.html.erb`

- [ ] **Step 1: Replace the chip-building block**

Locate the existing block:

```erb
    <%
      chip_items = [{ id: "all", label: "Todos" }]
      Ui::Tokens::REWARD_CATEGORIES.each do |key, meta|
        chip_items << { id: key, label: meta[:label].capitalize }
      end
    %>
```

Replace with:

```erb
    <%
      chip_items = [{ id: "all", label: "Todos" }]
      @categories.each do |category|
        chip_items << { id: category.id.to_s, label: category.name }
      end
    %>
```

- [ ] **Step 2: Update the panels attribute on each reward wrapper**

Locate:

```erb
        <% @rewards.each do |reward| %>
          <div data-filter-tabs-target="item" data-panels="all <%= reward.category %>">
```

Replace with:

```erb
        <% @rewards.each do |reward| %>
          <div data-filter-tabs-target="item" data-panels="all <%= reward.category_id %>">
```

- [ ] **Step 3: Smoke-check parent reward index renders**

Run:
```bash
bundle exec rspec spec/requests/parent/rewards_spec.rb
```
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add app/views/parent/rewards/index.html.erb
git commit -m "feat(parent-rewards): dynamic chip filter from family categories"
```

---

## Task 14: Update reward components to tint from `category.color`

**Files:**
- Modify: `app/components/ui/reward_tile/component.rb` (if it computes tint internally) or its template
- Modify: `app/components/ui/featured_reward_card/component.*` similarly
- Modify: `app/components/ui/reward_catalog_card/component.*` similarly

- [ ] **Step 1: Survey current tint sourcing**

Run:
```bash
grep -rn "tint\|category" app/components/ui/reward_tile app/components/ui/featured_reward_card app/components/ui/reward_catalog_card
```

Note where `tint` is currently passed in. The `RewardTile` component receives `tint:` as a constructor arg from a hardcoded array in `kid/rewards/index.html.erb` — that array is replaced in Task 15 to read from `reward.category.color`.

- [ ] **Step 2: Add tint helper to reward components that need it**

For `app/components/ui/featured_reward_card/component.rb`, add (or replace existing tint method) inside the class:

```ruby
def tint
  return "var(--c-lilac-soft)" if reward.category.nil?
  Ui::Tokens.color_palette_entry(reward.category.color)[:soft_var]
end
```

For `app/components/ui/reward_catalog_card/component.rb`, add the same `tint` method.

For `RewardTile`, the constructor already accepts `tint:`. Leave as-is — caller (Task 15) provides the right value.

- [ ] **Step 3: Update template tint references**

In `featured_reward_card/component.html.erb` and `reward_catalog_card/component.html.erb`, replace any hardcoded `var(--c-lilac-soft)` with `<%= tint %>` (or equivalent inline-style binding). Use exact existing template style.

If a template already uses `tint`, no change needed — verify with:
```bash
grep -n "tint" app/components/ui/featured_reward_card/component.html.erb app/components/ui/reward_catalog_card/component.html.erb
```

- [ ] **Step 4: Commit**

```bash
git add app/components/ui/featured_reward_card app/components/ui/reward_catalog_card
git commit -m "feat(ui): reward cards tint from category.color palette"
```

---

## Task 15: Kid shop — wire `filter-tabs`, dynamic categories, hide empty

**Files:**
- Modify: `app/controllers/kid/rewards_controller.rb`
- Modify: `app/views/kid/rewards/index.html.erb`

- [ ] **Step 1: Update kid rewards controller**

Replace `index` body in `app/controllers/kid/rewards_controller.rb`:

```ruby
  def index
    family_id = current_profile.family_id
    @rewards = Reward.where(family_id: family_id).includes(:category)
    @featured = @rewards.order(cost: :desc).first
    @redeemed_rewards = current_profile.redemptions.includes(:reward).order(created_at: :desc)
    @categories_with_rewards = Category
      .where(family_id: family_id)
      .joins(:rewards)
      .distinct
      .ordered
    @reward_counts = @rewards.group(:category_id).count
  end
```

- [ ] **Step 2: Rewrite the kid shop view**

Replace `app/views/kid/rewards/index.html.erb` content with:

```erb
<%
  featured = @featured || @rewards&.first
%>
<div class="screen screen-enter-right with-nav">
  <%= render Ui::BgShapes::Component.new(variant: "warm") %>
  <%= render Ui::Celebration::Component.new %>

  <%= render Ui::TopBar::Component.new(
    title: "Lojinha",
    subtitle: "Troque suas estrelinhas por recompensas",
    back_url: kid_root_path
  ) do |bar| %>
    <% bar.with_right_slot do %>
      <%= render Ui::BalanceChip::Component.new(value: current_profile.points, profile: current_profile, id: "profile_points_#{current_profile.id}") %>
    <% end %>
  <% end %>

  <% if featured %>
    <%= render Ui::FeaturedRewardCard::Component.new(
      reward: featured,
      balance: current_profile.points,
      modal_id: "modal_#{dom_id(featured)}"
    ) %>
  <% end %>

  <%# Section Header %>
  <div class="flex items-baseline justify-between mb-5 mt-5 relative z-10">
    <%= render Ui::Heading::Component.new(size: :h3) do %>O que você quer hoje?<% end %>
    <span class="text-[12px] font-bold text-muted-foreground"><%= @rewards.size %> prêmios</span>
  </div>

  <% if @rewards.any? %>
    <div data-controller="filter-tabs" class="mb-4 z-2 relative">
      <%
        tab_items = [{ id: "all", label: "Tudo", count: @rewards.size }]
        @categories_with_rewards.each do |cat|
          tab_items << { id: cat.id.to_s, label: cat.name, count: @reward_counts[cat.id].to_i }
        end
      %>
      <%= render Ui::CategoryTabs::Component.new(items: tab_items, active: "all", controller: "filter-tabs") %>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-3 mt-4">
        <% @rewards.each_with_index do |reward, i| %>
          <% tint = Ui::Tokens.color_palette_entry(reward.category&.color || "lilac")[:soft_var] %>
          <div data-filter-tabs-target="item" data-panels="all <%= reward.category_id %>">
            <%= render Ui::RewardTile::Component.new(
              reward: reward,
              balance: current_profile.points,
              tint: tint,
              index: i,
              modal_id: "modal_#{dom_id(reward)}"
            ) %>
          </div>
        <% end %>
      </div>
    </div>
  <% else %>
    <%= render Ui::Empty::Component.new(
      icon: "bag",
      title: "A lojinha está vazia",
      subtitle: "Peça para um responsável adicionar recompensas!",
      color: "rose"
    ) %>
  <% end %>

  <% if @redeemed_rewards.any? %>
    <div class="mt-8 mb-6 z-2 relative">
      <div class="font-display text-[20px] leading-tight font-extrabold tracking-[-0.02em] text-foreground mb-3">Meus prêmios</div>
      <div class="flex flex-col gap-2.5">
        <% @redeemed_rewards.each do |redemption| %>
          <%= render Ui::RedemptionRow::Component.new(redemption: redemption) %>
        <% end %>
      </div>
    </div>
  <% end %>

  <%# Reward Modals (one per reward) %>
  <% @rewards.each do |reward| %>
    <% reward_icon = reward.respond_to?(:icon) ? reward.icon.presence : nil %>
    <%= render Ui::Modal::Component.new(id: "modal_#{dom_id(reward)}", title: "Resgatar Recompensa") do %>
      <div class="flex flex-col items-center justify-center text-center gap-3.5">
        <%= render Ui::LogoMark::Component.new(size: 48) %>
        <div class="flex items-center justify-center w-[100px] h-[100px] rounded-lg bg-lilac-soft mx-auto">
          <%= render Ui::Icon::Component.new(reward_icon || "gift", size: 56, color: "var(--c-violet-dark)") %>
        </div>
        <h3 class="font-display text-[26px] leading-tight font-extrabold tracking-[-0.02em] text-foreground"><%= reward.title %></h3>
        <div class="flex items-center justify-center gap-2.5">
          <%= render Ui::Badge::Component.new(variant: "star", class: "text-[16px] py-2 px-3.5") do %>
            <%= render Ui::StarValue::Component.new(value: reward.cost, size: :md, color: :gold) %>
          <% end %>
        </div>

        <div class="bg-surface-2 rounded-card p-3.5 w-full">
          <div class="flex items-center justify-between font-display font-extrabold">
            <span>Saldo atual</span>
            <%= render Ui::StarValue::Component.new(value: current_profile.points, size: :sm, color: :gold) %>
          </div>
          <div class="flex items-center justify-between text-danger font-display font-extrabold mt-1">
            <span>−</span>
            <%= render Ui::StarValue::Component.new(value: reward.cost, size: :sm, color: :gold, class: "text-danger") %>
          </div>
          <div class="h-[2px] bg-[rgba(26,42,74,0.1)] my-2"></div>
          <div class="flex items-center justify-between text-primary font-display font-extrabold">
            <span>Depois</span>
            <%= render Ui::StarValue::Component.new(value: [current_profile.points - reward.cost, 0].max, size: :lg, color: :gold, class: "text-primary") %>
          </div>
        </div>

        <div class="flex items-center justify-center gap-3 mt-1.5 w-full">
          <%= render Ui::Btn::Component.new(variant: "secondary", data: { action: "click->modal#close" }) do %>Cancelar<% end %>
          <%= button_to redeem_kid_reward_path(reward), method: :post, class: "btn btn-primary btn-lg" do %>
            <%= render Ui::Icon::Component.new("gift", size: 20) %> Resgatar!
          <% end %>
        </div>
      </div>
    <% end %>
  <% end %>
</div>
```

- [ ] **Step 3: Verify `Ui::CategoryTabs` works under `filter-tabs` controller**

Read `app/components/ui/category_tabs/component.html.erb`. The `data-action` attribute uses the `controller` prop interpolation: `click-><%= controller %>#show`. With `controller: "filter-tabs"` the action becomes `click->filter-tabs#show`, matching the JS controller's `show` method. The `data-<controller>-id-param="<id>"` attribute renders as `data-filter-tabs-id-param="all"`. The `filter_tabs_controller.js` reads `event.currentTarget.dataset.filterTabsIdParam` — matches.

No code change needed. Note: `filter_tabs_controller.js` currently toggles class `bg-white text-primary shadow-sm` on tabs but our `cat-tab` styling uses `cat-tab--active`. Confirm with:
```bash
grep -n "cat-tab--active\|cat-tab" app/assets/controllers/filter_tabs_controller.js app/components/ui/category_tabs
```

If filter-tabs JS doesn't toggle `cat-tab--active`, patch the controller. Apply this edit to `app/assets/controllers/filter_tabs_controller.js` `show` method:

Locate:
```js
    this.tabTargets.forEach(t => {
      const isActive = t === event.currentTarget
      t.classList.toggle("active", isActive)
      t.classList.toggle("bg-white", isActive)
      t.classList.toggle("text-primary", isActive)
      t.classList.toggle("shadow-sm", isActive)
      t.classList.toggle("text-muted-foreground", !isActive)
      t.setAttribute("aria-selected", isActive)
    })
```

Replace with:
```js
    this.tabTargets.forEach(t => {
      const isActive = t === event.currentTarget
      t.classList.toggle("active", isActive)
      if (t.classList.contains("cat-tab")) {
        t.classList.toggle("cat-tab--active", isActive)
      } else {
        t.classList.toggle("bg-white", isActive)
        t.classList.toggle("text-primary", isActive)
        t.classList.toggle("shadow-sm", isActive)
        t.classList.toggle("text-muted-foreground", !isActive)
      }
      t.setAttribute("aria-selected", isActive)
    })
```

Apply same `cat-tab--active` handling in the `connect()` initial activation if needed. Inspect:
```bash
sed -n '1,30p' app/assets/controllers/filter_tabs_controller.js
```

- [ ] **Step 4: Commit**

```bash
git add app/controllers/kid/rewards_controller.rb app/views/kid/rewards/index.html.erb app/assets/controllers/filter_tabs_controller.js
git commit -m "feat(kid-shop): wire filter-tabs to category_id, hide empty categories"
```

---

## Task 16: Update `db/seeds.rb` to use category lookups

**Files:**
- Modify: `db/seeds.rb`

- [ ] **Step 1: Locate and replace the rewards seed block**

Find the block (around the `Creating Rewards...` puts):

```ruby
puts "Creating Rewards..."
Reward.create!(family: family, title: "Sorvete de chocolate", cost: 80, icon: "iceCream", category: :doce)
Reward.create!(family: family, title: "1h de Video Game", cost: 150, icon: "gamepad", category: :tela)
Reward.create!(family: family, title: "Passeio ao parque", cost: 250, icon: "ferris", category: :passeio)
Reward.create!(family: family, title: "LEGO novo", cost: 600, icon: "blocks", category: :brinquedo)
Reward.create!(family: family, title: "Escolher filme", cost: 50, icon: "film", category: :experiencia)
```

Replace with:

```ruby
puts "Creating Rewards..."
cats = family.categories.index_by(&:name)
Reward.create!(family: family, title: "Sorvete de chocolate", cost: 80, icon: "ice-cream-01",      category: cats.fetch("Docinhos"))
Reward.create!(family: family, title: "1h de Video Game",     cost: 150, icon: "game-controller-01", category: cats.fetch("Telinha"))
Reward.create!(family: family, title: "Passeio ao parque",    cost: 250, icon: "ferris-wheel",       category: cats.fetch("Passeios"))
Reward.create!(family: family, title: "LEGO novo",            cost: 600, icon: "cube",               category: cats.fetch("Brinquedos"))
Reward.create!(family: family, title: "Escolher filme",       cost: 50,  icon: "film-01",            category: cats.fetch("Experiências"))
```

(Family creation already triggers default category seed via `after_create`.)

- [ ] **Step 2: Reset and seed the database**

Run:
```bash
bin/rails db:reset
```
Expected: schema drops/recreates, seeds run, no errors. Confirm `Reward.count == 5` and `Category.count == 6` via:
```bash
bin/rails runner 'puts "rewards=#{Reward.count} categories=#{Category.count}"'
```

- [ ] **Step 3: Commit**

```bash
git add db/seeds.rb
git commit -m "seed: rewards reference seeded categories by name"
```

---

## Task 17: System spec — parent categories management

**Files:**
- Create: `spec/system/parent/categories_management_spec.rb`

- [ ] **Step 1: Write the system spec**

```ruby
# spec/system/parent/categories_management_spec.rb
require "rails_helper"

RSpec.describe "Parent categories management", type: :system, js: false do
  let(:family) { create(:family) }
  let(:parent) { create(:profile, :parent, family: family) }

  before do
    # Use the same auth helper pattern used by other parent system specs.
    # If the test suite uses `sign_in_as(parent)`, call it here. Otherwise
    # set `family_id` cookie and `session[:profile_id]` per existing pattern.
    sign_in_as(parent)
  end

  it "lists default categories on the management page" do
    visit parent_categories_path
    expect(page).to have_content("Telinha")
    expect(page).to have_content("Docinhos")
    expect(page).to have_content("Brinquedos")
  end

  it "creates a new category" do
    visit new_parent_category_path
    fill_in "Nome", with: "Música"
    # Icon picker default value is fine — leave first icon selected
    # Color swatch picker — first swatch is preselected
    click_button "Salvar"
    expect(page).to have_current_path(parent_categories_path)
    expect(page).to have_content("Música")
  end

  it "blocks deleting a category with rewards" do
    cat = family.categories.first
    create(:reward, family: family, category: cat)
    visit parent_categories_path
    # Find the row containing the category name and click its Excluir button.
    # `accept_confirm` accepts the turbo-confirm modal.
    accept_confirm do
      within("div", text: cat.name) do
        click_button "Excluir"
      end
    end
    expect(page).to have_content(/reatribua/i)
    expect(family.categories.reload).to include(cat)
  end
end
```

- [ ] **Step 2: Run the spec**

Run:
```bash
bundle exec rspec spec/system/parent/categories_management_spec.rb
```
Expected: PASS. If `sign_in_as` helper is named differently in this codebase, swap it for the helper used by `spec/system/parent/*_spec.rb`. Inspect:
```bash
grep -l "type: :system" spec/system/parent | head -1 | xargs grep -A 3 "before do"
```

- [ ] **Step 3: Commit**

```bash
git add spec/system/parent/categories_management_spec.rb
git commit -m "test(system): parent categories management end-to-end"
```

---

## Task 18: System spec — kid shop tab filter

**Files:**
- Create: `spec/system/kid/shop_filter_spec.rb`

- [ ] **Step 1: Write the system spec**

```ruby
# spec/system/kid/shop_filter_spec.rb
require "rails_helper"

RSpec.describe "Kid shop category filter", type: :system, js: true do
  let(:family) { create(:family) }
  let(:kid) { create(:profile, :child, family: family, points: 500) }

  let!(:cat_a) { family.categories.find_by(name: "Telinha") }
  let!(:cat_b) { family.categories.find_by(name: "Docinhos") }
  let!(:reward_a) { create(:reward, family: family, category: cat_a, title: "Vídeo Game", cost: 100) }
  let!(:reward_b) { create(:reward, family: family, category: cat_b, title: "Sorvete", cost: 50) }

  before do
    # Delete unused defaults (categories without rewards) — they should be hidden anyway,
    # but we leave them to verify the hide-empty rule.
    sign_in_as(kid)
  end

  it "shows only category tabs that have rewards" do
    visit kid_rewards_path
    expect(page).to have_content("Telinha")
    expect(page).to have_content("Docinhos")
    expect(page).not_to have_content("Brinquedos") # default with no rewards
    expect(page).not_to have_content("Outro")      # default with no rewards
  end

  it "filters reward tiles when a tab is clicked" do
    visit kid_rewards_path
    expect(page).to have_content("Vídeo Game")
    expect(page).to have_content("Sorvete")

    click_button "Docinhos"
    expect(page).to have_content("Sorvete")
    expect(page).not_to have_content("Vídeo Game")

    click_button "Tudo"
    expect(page).to have_content("Vídeo Game")
    expect(page).to have_content("Sorvete")
  end
end
```

- [ ] **Step 2: Run the spec**

Run:
```bash
bundle exec rspec spec/system/kid/shop_filter_spec.rb
```
Expected: PASS. If `js: true` requires Capybara driver setup not currently configured, fall back to checking `data-panels` attributes via Rack-test. Replace the second example with:

```ruby
  it "tags each reward tile with its category id for filtering" do
    visit kid_rewards_path
    expect(page).to have_css("[data-filter-tabs-target='item'][data-panels~='#{cat_a.id}']")
    expect(page).to have_css("[data-filter-tabs-target='item'][data-panels~='#{cat_b.id}']")
  end
```

(Drop `js: true` if using Rack-test fallback.)

- [ ] **Step 3: Commit**

```bash
git add spec/system/kid/shop_filter_spec.rb
git commit -m "test(system): kid shop hides empty categories + filters by tab"
```

---

## Task 19: Full suite + lint final pass

- [ ] **Step 1: Run the full RSpec suite**

Run:
```bash
bundle exec rspec
```
Expected: all green. Investigate any failures — likely candidates: leftover `Reward.categories` references in fixtures or specs, factory chains not yet updated.

- [ ] **Step 2: Run rubocop**

Run:
```bash
bin/rubocop
```
Expected: no offenses. Run `bin/rubocop -A` for autofix if needed, then re-commit.

- [ ] **Step 3: Run brakeman**

Run:
```bash
bin/brakeman -q
```
Expected: no new warnings.

- [ ] **Step 4: Final commit (only if rubocop or other tooling produced changes)**

```bash
git add -A
git commit -m "chore: rubocop autocorrect post-categories migration"
```

---

## Self-Review

**Spec coverage** (each requirement → task):

- New `Category` model with `name + icon + color + position` → Tasks 1, 2
- Family-scoped, `dependent: :restrict_with_error` on rewards → Tasks 1, 2, 5
- Drop `Reward.category` enum, add `category_id` FK NOT NULL → Tasks 4, 5
- Default seed of 6 categories on `Family.create` → Task 3
- Idempotent seed service → Task 3
- `Parent::CategoriesController` CRUD with destroy block → Task 7
- Cross-family access returns 404 → Task 7 (request spec asserts)
- `Ui::Tokens` palette + drop reward enum helper → Task 6
- Parent sidebar "Categorias" item → Task 11
- Reward form switches enum select → category dropdown → Task 12
- Parent rewards index dynamic chips → Task 13
- Reward components tint from `category.color` → Task 14
- Kid shop wires `filter-tabs`, dynamic tabs from family categories → Task 15
- Kid shop hides empty categories → Task 15 (controller scopes via `joins(:rewards).distinct`)
- Migration order safe (add nullable, wipe, NOT NULL, drop enum) → Task 4
- `db/seeds.rb` updated → Task 16
- Tests at all layers (model, service, request, system) → Tasks 2, 3, 5, 7, 17, 18
- Full suite + rubocop + brakeman green → Task 19

All spec acceptance criteria are covered.

**Placeholder scan:** No "TBD" / "TODO" / "implement later" present. Each step shows full code or exact commands. Conditional fallbacks (e.g., `sign_in_as` helper variants in Tasks 7/17/18) provide explicit alternates rather than waving at "use the right helper."

**Type consistency:** `Category#name`, `Category#icon`, `Category#color`, `Category#position` used consistently across model spec, factory, service defaults, controller params, form, and views. `Reward#category_id` and `Reward#category` association used consistently. `CATEGORY_COLOR_PALETTE` keys (`sky/rose/mint/amber/lilac/peach/violet/star`) match seed defaults (`sky/rose/mint/amber/lilac/peach`) — palette is a superset, intentional.

No issues found.

# Icon Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hardcoded 12-icon radio grid in mission and reward forms with a searchable modal picker backed by a static Hugeicons manifest, and migrate stored icon values from curated aliases to raw `hgi-*` slugs.

**Architecture:** New `Ui::IconPicker::Component` ViewComponent renders a hidden input + preview tile + sync modal (`Ui::Modal::Component`) with two tabs (Sugeridos / Todos) and a search box. New `icon_picker_controller.js` Stimulus controller fetches `/hugeicons-manifest.json` lazily, runs substring search client-side, paginates the catalog tab. A migration rewrites existing `global_tasks.icon` and `rewards.icon` values from curated keys to raw Hugeicons slugs. `Ui::Icon::Component` is unchanged (the `HUGEICONS_MAP` stays as a code-level alias for view shorthand).

**Tech Stack:** Rails 8.1, ViewComponent 4.7, Stimulus, Tailwind 4, RSpec + Capybara, Hugeicons CSS font (already self-hosted via `d541705`).

**Spec:** `docs/superpowers/specs/2026-04-25-icon-picker-design.md`

---

## File Map

**Create:**
- `public/hugeicons-manifest.json` — built artifact, committed.
- `lib/icons/hugeicons_seed.json` — raw MCP `list_icons` output, committed seed.
- `lib/tasks/icons.rake` — `rake icons:sync` rebuilds the manifest from the seed.
- `app/components/ui/icon_picker/component.rb`
- `app/components/ui/icon_picker/component.html.erb`
- `app/components/ui/icon_picker/component.yml`
- `app/assets/controllers/icon_picker_controller.js`
- `spec/components/ui/icon_picker/component_spec.rb`
- `spec/system/parent/icon_picker_spec.rb`
- `db/migrate/<ts>_convert_icon_keys_to_hugeicons_slugs.rb`
- `spec/migrations/convert_icon_keys_to_hugeicons_slugs_spec.rb`

**Modify:**
- `app/views/parent/global_tasks/_form.html.erb` — replace icon radio grid with picker.
- `app/views/parent/rewards/_form.html.erb` — replace icon radio grid with picker.

**Untouched:**
- `app/components/ui/icon/component.rb` — `HUGEICONS_MAP` stays for code-level shorthand.

---

## Task 1: Generate Hugeicons seed and manifest

**Files:**
- Create: `lib/icons/hugeicons_seed.json`
- Create: `public/hugeicons-manifest.json`
- Create: `lib/tasks/icons.rake`

- [ ] **Step 1: Generate the seed via MCP**

Inside the Claude Code session, call `mcp__hugeicons__list_icons` once. Take the full result (array of icon descriptors with `name`, optional `category`, optional `tags`). Persist it as JSON to `lib/icons/hugeicons_seed.json` exactly as returned (no transformation).

If the MCP result lacks tags for some entries, that's fine — the rake task handles fallback. The seed is the raw cache; the manifest is the post-processed shape.

- [ ] **Step 2: Write the rake task**

Create `lib/tasks/icons.rake`:

```ruby
namespace :icons do
  desc "Build public/hugeicons-manifest.json from lib/icons/hugeicons_seed.json"
  task :sync do
    seed_path = Rails.root.join("lib/icons/hugeicons_seed.json")
    out_path  = Rails.root.join("public/hugeicons-manifest.json")

    raise "Seed missing at #{seed_path}. Re-run mcp__hugeicons__list_icons in a Claude Code session and persist the result." unless seed_path.exist?

    seed = JSON.parse(seed_path.read)

    manifest = seed.map do |entry|
      slug = entry["slug"] || entry["name"].to_s.parameterize
      name = entry["name"].to_s.tr("-_", "  ").strip
      tags = Array(entry["tags"]).map(&:to_s)
      tags = slug.split("-").reject(&:empty?) if tags.empty?
      { slug: slug, name: name, tags: tags }
    end

    out_path.write(JSON.pretty_generate(manifest))
    puts "Wrote #{manifest.size} icons to #{out_path.relative_path_from(Rails.root)}"
  end
end
```

- [ ] **Step 3: Run the rake task and verify the manifest**

Run: `bin/rails icons:sync`
Expected: `Wrote N icons to public/hugeicons-manifest.json` where N is the number of icons returned by MCP (~4000+).

Verify shape:
```bash
ruby -rjson -e 'arr = JSON.parse(File.read("public/hugeicons-manifest.json")); puts arr.size; pp arr.first(2)'
```
Expected: prints `N`, then two hashes each with `slug`, `name`, `tags` keys.

- [ ] **Step 4: Commit**

```bash
git add lib/icons/hugeicons_seed.json public/hugeicons-manifest.json lib/tasks/icons.rake
git commit -m "feat(icons): add Hugeicons manifest + sync rake task"
```

---

## Task 2: `Ui::IconPicker::Component` — failing spec

**Files:**
- Create: `spec/components/ui/icon_picker/component_spec.rb`

- [ ] **Step 1: Write the failing spec**

```ruby
require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::IconPicker::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:default_args) do
    { field_name: "global_task[icon]", value: "bed-single-01", context: :mission, color: "var(--c-blue)", id: "icon_picker_demo" }
  end

  it "renders a hidden input with the given name and value" do
    render_inline(described_class.new(**default_args))
    expect(page).to have_css("input[type='hidden'][name='global_task[icon]'][value='bed-single-01']", visible: :hidden)
  end

  it "renders a preview button wired to the picker controller" do
    render_inline(described_class.new(**default_args))
    expect(page).to have_css("button[data-action*='icon-picker#open']")
    expect(page).to have_css("[data-icon-picker-target='previewIcon']")
  end

  it "renders a modal with the given id" do
    render_inline(described_class.new(**default_args))
    expect(page.native.to_html).to include('id="icon_picker_demo_modal"')
  end

  it "exposes the context to the controller via a data attribute" do
    render_inline(described_class.new(**default_args))
    expect(page).to have_css("[data-icon-picker-context-value='mission']")
  end

  it "renders a search input and the two tab buttons" do
    render_inline(described_class.new(**default_args))
    expect(page).to have_css("[data-icon-picker-target='searchInput']")
    expect(page).to have_css("[data-icon-picker-target='tabCurated']", text: /Sugeridos/i)
    expect(page).to have_css("[data-icon-picker-target='tabCatalog']", text: /Todos/i)
  end

  it "renders Confirmar and Cancelar action buttons" do
    render_inline(described_class.new(**default_args))
    html = page.native.to_html
    expect(html).to match(/Confirmar/)
    expect(html).to match(/Cancelar/)
  end
end
```

- [ ] **Step 2: Run the spec and verify it fails**

Run: `bundle exec rspec spec/components/ui/icon_picker/component_spec.rb`
Expected: load error or `NameError: uninitialized constant Ui::IconPicker`.

---

## Task 3: `Ui::IconPicker::Component` — implementation

**Files:**
- Create: `app/components/ui/icon_picker/component.rb`
- Create: `app/components/ui/icon_picker/component.html.erb`
- Create: `app/components/ui/icon_picker/component.yml`

- [ ] **Step 1: Write the Ruby component**

Create `app/components/ui/icon_picker/component.rb`:

```ruby
class Ui::IconPicker::Component < ApplicationComponent
  CONTEXT_GROUPS = {
    mission: %w[bed-single-01 dental-care book-01 dish-01 book-open-01 bone-01 bone-02 music-note-01 sun-01 home-01 mortarboard-01 dumbbell-01 target-01],
    reward:  %w[ice-cream-01 game-controller-01 ferris-wheel cube pizza-01 film-01 moon-01 bookmark-01 gift favourite],
    any:     []
  }.freeze

  def initialize(field_name:, value: nil, context: :any, color: "var(--primary)", id:)
    @field_name = field_name
    @value = value.presence
    @context = context.to_sym
    @color = color
    @id = id
    raise ArgumentError, "id is required" if @id.blank?
    raise ArgumentError, "unknown context #{@context}" unless CONTEXT_GROUPS.key?(@context)
  end

  attr_reader :field_name, :value, :context, :color, :id

  def modal_id
    "#{@id}_modal"
  end

  def curated_slugs
    slugs = CONTEXT_GROUPS[@context]
    slugs = CONTEXT_GROUPS.values.flatten.uniq if slugs.empty?
    slugs
  end

  def display_value
    @value || curated_slugs.first || "target-01"
  end
end
```

- [ ] **Step 2: Write the template**

Create `app/components/ui/icon_picker/component.html.erb`:

```erb
<div
  data-controller="icon-picker"
  data-icon-picker-context-value="<%= context %>"
  data-icon-picker-modal-id-value="<%= modal_id %>"
  data-icon-picker-curated-value="<%= curated_slugs.to_json %>"
  data-icon-picker-color-value="<%= color %>"
  class="flex flex-col items-center gap-3"
>
  <%= hidden_field_tag field_name, value, data: { icon_picker_target: "hiddenInput" } %>

  <button
    type="button"
    data-action="click->icon-picker#open"
    class="flex items-center justify-center bg-white border-2 border-hairline rounded-2xl p-3 hover:border-primary transition-all"
    aria-label="Escolher ícone"
  >
    <span data-icon-picker-target="previewIcon" style="display:inline-flex;">
      <%= render Ui::IconTile::Component.new(icon: display_value, color: "primary", size: 80) %>
    </span>
  </button>

  <span class="text-[12px] text-muted-foreground font-semibold">Toque para escolher um ícone</span>

  <%= render Ui::Modal::Component.new(title: "Escolher ícone", id: modal_id, size: "lg") do %>
    <%= render Ui::Modal::BodyComponent.new do %>
      <div class="flex flex-col gap-4">
        <input
          type="search"
          placeholder="Buscar ícones…"
          data-icon-picker-target="searchInput"
          data-action="input->icon-picker#search"
          class="w-full px-5 py-3 bg-white border-2 border-hairline rounded-2xl font-semibold text-[15px] text-foreground placeholder:text-muted-foreground focus:border-primary focus:ring-0 transition-all"
        />

        <div class="row gap-2">
          <button type="button"
            data-icon-picker-target="tabCurated"
            data-action="click->icon-picker#showCurated"
            class="px-4 py-2 rounded-full font-bold text-[13px] bg-primary-soft text-primary">
            Sugeridos
          </button>
          <button type="button"
            data-icon-picker-target="tabCatalog"
            data-action="click->icon-picker#showCatalog"
            class="px-4 py-2 rounded-full font-bold text-[13px] bg-surface-muted text-muted-foreground">
            Todos
          </button>
        </div>

        <div data-icon-picker-target="curatedGrid"
             class="grid grid-cols-5 sm:grid-cols-7 gap-2"></div>

        <div data-icon-picker-target="catalogGrid"
             class="grid grid-cols-5 sm:grid-cols-7 gap-2 hidden"></div>

        <button type="button"
          data-icon-picker-target="loadMoreBtn"
          data-action="click->icon-picker#loadMore"
          class="hidden mx-auto px-4 py-2 rounded-full font-bold text-[13px] bg-surface-muted text-foreground hover:bg-primary-soft hover:text-primary transition-all">
          Carregar mais
        </button>
      </div>
    <% end %>

    <%= render Ui::Modal::FooterComponent.new(justify: :end) do %>
      <%= render Ui::Btn::Component.new(variant: "secondary", data: { action: "click->icon-picker#cancel" }) do %>Cancelar<% end %>
      <%= render Ui::Btn::Component.new(variant: "primary",   data: { action: "click->icon-picker#confirm" }) do %>Confirmar<% end %>
    <% end %>
  <% end %>
</div>
```

- [ ] **Step 3: Write the metadata yml**

Create `app/components/ui/icon_picker/component.yml`:

```yaml
name: IconPicker
description: Searchable picker for Hugeicons. Renders preview tile + modal with curated and catalog tabs.

props:
  - name: field_name
    type: String
    description: Form field name for the hidden input (e.g. "global_task[icon]").
  - name: value
    type: String
    default: "nil"
    description: Current Hugeicons slug (raw, e.g. "bed-single-01").
  - name: context
    type: Symbol
    default: ":any"
    values: [":mission", ":reward", ":any"]
    description: Drives the curated tab subset.
  - name: color
    type: String
    default: '"var(--primary)"'
    description: CSS color used for the preview tile tint.
  - name: id
    type: String
    description: DOM id prefix. Modal id becomes "#{id}_modal".
```

- [ ] **Step 4: Run the spec and verify it passes**

Run: `bundle exec rspec spec/components/ui/icon_picker/component_spec.rb`
Expected: 6 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/components/ui/icon_picker spec/components/ui/icon_picker
git commit -m "feat(ui): add Ui::IconPicker component"
```

---

## Task 4: `icon_picker_controller.js` Stimulus controller

**Files:**
- Create: `app/assets/controllers/icon_picker_controller.js`

- [ ] **Step 1: Write the controller**

Create `app/assets/controllers/icon_picker_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

const PAGE_SIZE = 60
let manifestPromise = null

function loadManifest() {
  if (window.__hugeiconsManifest) return Promise.resolve(window.__hugeiconsManifest)
  if (manifestPromise) return manifestPromise
  manifestPromise = fetch("/hugeicons-manifest.json", { credentials: "same-origin" })
    .then(r => r.json())
    .then(data => { window.__hugeiconsManifest = data; return data })
  return manifestPromise
}

export default class extends Controller {
  static targets = [
    "hiddenInput", "previewIcon",
    "searchInput", "tabCurated", "tabCatalog",
    "curatedGrid", "catalogGrid", "loadMoreBtn"
  ]
  static values = {
    context: String,
    modalId: String,
    curated: Array,
    color: String
  }

  connect() {
    this.pendingValue = this.hiddenInputTarget.value || null
    this.activeTab = "curated"
    this.catalogPage = 0
    this.filteredCatalog = []
    this.renderCurated()
  }

  open(event) {
    event.preventDefault()
    const modal = document.getElementById(this.modalIdValue)
    if (!modal) return
    modal.style.display = "flex"
    this.pendingValue = this.hiddenInputTarget.value || null
    this.searchInputTarget.value = ""
    this.activeTab = "curated"
    this.applyTabUI()
    this.renderCurated()
    loadManifest()
  }

  close() {
    const modal = document.getElementById(this.modalIdValue)
    if (modal) modal.style.display = "none"
  }

  cancel(event) {
    event.preventDefault()
    this.close()
  }

  confirm(event) {
    event.preventDefault()
    if (!this.pendingValue) { this.close(); return }
    this.hiddenInputTarget.value = this.pendingValue
    this.hiddenInputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.updatePreview(this.pendingValue)
    this.close()
  }

  showCurated(event) {
    event?.preventDefault()
    this.activeTab = "curated"
    this.applyTabUI()
    this.renderCurated()
  }

  showCatalog(event) {
    event?.preventDefault()
    this.activeTab = "catalog"
    this.applyTabUI()
    this.catalogPage = 0
    loadManifest().then(manifest => {
      this.filteredCatalog = manifest
      this.renderCatalogPage()
    })
  }

  search() {
    const q = this.searchInputTarget.value.trim().toLowerCase()
    if (q.length < 2) {
      if (this.activeTab === "catalog") {
        loadManifest().then(manifest => {
          this.filteredCatalog = manifest
          this.catalogPage = 0
          this.renderCatalogPage()
        })
      }
      return
    }
    this.activeTab = "catalog"
    this.applyTabUI()
    loadManifest().then(manifest => {
      this.filteredCatalog = manifest.filter(entry => {
        if (entry.name && entry.name.toLowerCase().includes(q)) return true
        if (entry.slug && entry.slug.toLowerCase().includes(q)) return true
        return Array.isArray(entry.tags) && entry.tags.some(t => t.toLowerCase().includes(q))
      })
      this.catalogPage = 0
      this.renderCatalogPage()
    })
  }

  loadMore(event) {
    event?.preventDefault()
    this.catalogPage += 1
    this.renderCatalogPage({ append: true })
  }

  renderCurated() {
    this.curatedGridTarget.classList.remove("hidden")
    this.catalogGridTarget.classList.add("hidden")
    this.loadMoreBtnTarget.classList.add("hidden")
    this.curatedGridTarget.innerHTML = ""
    for (const slug of this.curatedValue) {
      this.curatedGridTarget.appendChild(this.tileEl(slug))
    }
  }

  renderCatalogPage({ append = false } = {}) {
    this.catalogGridTarget.classList.remove("hidden")
    this.curatedGridTarget.classList.add("hidden")
    if (!append) this.catalogGridTarget.innerHTML = ""
    const start = this.catalogPage * PAGE_SIZE
    const end = start + PAGE_SIZE
    const slice = this.filteredCatalog.slice(start, end)
    for (const entry of slice) {
      this.catalogGridTarget.appendChild(this.tileEl(entry.slug))
    }
    const total = this.filteredCatalog.length
    const shown = Math.min(end, total)
    if (shown < total) {
      this.loadMoreBtnTarget.classList.remove("hidden")
      this.loadMoreBtnTarget.textContent = `Carregar mais (${shown} de ${total})`
    } else {
      this.loadMoreBtnTarget.classList.add("hidden")
    }
  }

  tileEl(slug) {
    const btn = document.createElement("button")
    btn.type = "button"
    btn.dataset.slug = slug
    btn.className = this.tileClasses(slug)
    btn.setAttribute("aria-label", slug)
    btn.addEventListener("click", (e) => {
      e.preventDefault()
      this.pendingValue = slug
      this.refreshTileSelection()
    })

    const i = document.createElement("i")
    i.className = `hgi-stroke hgi-${slug}`
    i.style.cssText = "font-size:24px; line-height:1; color: var(--primary); display:inline-flex; align-items:center; justify-content:center; width:24px; height:24px;"
    i.setAttribute("aria-hidden", "true")
    btn.appendChild(i)
    return btn
  }

  tileClasses(slug) {
    const selected = (slug === this.pendingValue)
    return [
      "flex items-center justify-center w-11 h-11 rounded-xl border-2 transition-all bg-white",
      selected ? "border-primary bg-primary-soft" : "border-[rgba(26,42,74,0.1)] hover:border-primary"
    ].join(" ")
  }

  refreshTileSelection() {
    const grids = [this.curatedGridTarget, this.catalogGridTarget]
    for (const grid of grids) {
      for (const el of grid.querySelectorAll("button[data-slug]")) {
        el.className = this.tileClasses(el.dataset.slug)
      }
    }
  }

  updatePreview(slug) {
    const i = this.previewIconTarget.querySelector("i.hgi-stroke, i.hgi-bulk")
    if (!i) return
    i.className = i.className
      .split(" ")
      .filter(c => !c.startsWith("hgi-") || c === "hgi-stroke" || c === "hgi-bulk")
      .concat(`hgi-${slug}`)
      .join(" ")
  }

  applyTabUI() {
    const active = "bg-primary-soft text-primary"
    const idle   = "bg-surface-muted text-muted-foreground"
    const setBtn = (el, on) => {
      el.classList.remove(...active.split(" "), ...idle.split(" "))
      el.classList.add(...(on ? active : idle).split(" "))
    }
    setBtn(this.tabCuratedTarget, this.activeTab === "curated")
    setBtn(this.tabCatalogTarget, this.activeTab === "catalog")
  }
}
```

- [ ] **Step 2: Verify auto-registration is in place**

Open `app/assets/controllers/index.js` (already exists). Confirm it uses `stimulus-vite-helpers` to auto-register every `*_controller.js` in this directory. No edit needed — placing the file is enough.

Run: `grep -n "stimulus-vite-helpers\|registerControllers" app/assets/controllers/index.js`
Expected: a line referencing `stimulus-vite-helpers`.

- [ ] **Step 3: Boot the dev server and smoke-test the controller registration**

Run: `bin/dev` (background OK).

In a browser, open any parent page (e.g. `/parent/global_tasks/new`). Open devtools console and run: `Stimulus.controllers.map(c => c.identifier)` — expect `"icon-picker"` to be present (along with the other controllers). Stop here if it isn't; debug Vite resolution before proceeding.

- [ ] **Step 4: Commit**

```bash
git add app/assets/controllers/icon_picker_controller.js
git commit -m "feat(ui): add icon_picker Stimulus controller"
```

---

## Task 5: Wire `parent/global_tasks/_form.html.erb`

**Files:**
- Modify: `app/views/parent/global_tasks/_form.html.erb`

- [ ] **Step 1: Replace the icon block**

Read the file. Replace lines 16, 19–21, and 59–71 (the `icon_options` array, the `Ui::IconTile` preview row, and the `Ícone` radio grid block) with a single picker call. The exact replacement:

Remove this `icon_options` line (currently inside the variable block near the top):
```erb
icon_options = %w[bed brush book dish bookOpen bear paw music sun home graduationCap muscle]
```

Remove this preview row:
```erb
<div class="flex items-center justify-center mb-4">
  <%= render Ui::IconTile::Component.new(icon: global_task.icon.presence || "target", color: cat_data[:color], size: 80) %>
</div>
```

Remove this entire `Ícone` section:
```erb
<div class="mb-6 flex flex-col gap-2">
  <label class="font-display font-extrabold text-[15px] text-foreground tracking-tight">Ícone</label>
  <div class="row flex-wrap gap-1.5">
    <% icon_options.each do |ic| %>
      <label class="cursor-pointer">
        <%= f.radio_button :icon, ic, class: "peer sr-only" %>
        <div class="peer-checked:bg-primary-soft peer-checked:border-primary border-2 border-[rgba(26,42,74,0.1)] p-2 rounded-xl transition-all flex items-center justify-center w-11 h-11 bg-white">
          <%= render Ui::Icon::Component.new(ic, size: 24, color: "var(--primary)") %>
        </div>
      </label>
    <% end %>
  </div>
</div>
```

Insert this single picker block where the preview row used to live (right after the variable block, before the `Título` field):
```erb
<div class="mb-4 flex flex-col items-center gap-2">
  <%= render Ui::IconPicker::Component.new(
        field_name: "global_task[icon]",
        value: global_task.icon,
        context: :mission,
        color: "var(--c-#{cat_data[:color]})",
        id: "global_task_icon_picker"
      ) %>
</div>
```

- [ ] **Step 2: Manual smoke test**

With `bin/dev` running, open `/parent/global_tasks/new`. Verify: preview tile renders with default icon, clicking it opens the modal, "Sugeridos" tab shows ~13 mission-context tiles, typing "estrela" in search flips to "Todos" tab and filters, clicking a tile + "Confirmar" closes the modal and updates the preview, submitting the form persists the chosen slug. Use Postgres console or Rails console to confirm: `GlobalTask.last.icon` returns a raw slug string.

- [ ] **Step 3: Commit**

```bash
git add app/views/parent/global_tasks/_form.html.erb
git commit -m "feat(parent): use icon picker on mission form"
```

---

## Task 6: Wire `parent/rewards/_form.html.erb`

**Files:**
- Modify: `app/views/parent/rewards/_form.html.erb`

- [ ] **Step 1: Replace the icon block**

Read the file. The structure mirrors Task 5: there is an `icon_options` line, a `Ui::Icon::Component` preview, and an `Ícone` radio grid. Apply the same replacement strategy.

Remove the `icon_options = %w[iceCream gamepad ferris blocks pizza film moon bookSolid gift heart]` array.

Remove the preview block that contains `Ui::Icon::Component.new(reward.icon.presence || "gift", size: 58, color: "white")`.

Remove the `<% icon_options.each do |ic| %>` radio grid.

Insert the picker:
```erb
<div class="mb-4 flex flex-col items-center gap-2">
  <%= render Ui::IconPicker::Component.new(
        field_name: "reward[icon]",
        value: reward.icon,
        context: :reward,
        color: "var(--primary)",
        id: "reward_icon_picker"
      ) %>
</div>
```

- [ ] **Step 2: Manual smoke test**

With `bin/dev` running, open `/parent/rewards/new`. Verify: picker preview renders, modal opens, "Sugeridos" tab shows the reward-context tiles, search works, confirm persists. Confirm `Reward.last.icon` is a raw slug.

- [ ] **Step 3: Commit**

```bash
git add app/views/parent/rewards/_form.html.erb
git commit -m "feat(parent): use icon picker on reward form"
```

---

## Task 7: Migration — convert curated keys to raw slugs

**Files:**
- Create: `db/migrate/<ts>_convert_icon_keys_to_hugeicons_slugs.rb`
- Create: `spec/migrations/convert_icon_keys_to_hugeicons_slugs_spec.rb`

- [ ] **Step 1: Generate the migration skeleton**

Run: `bin/rails g migration ConvertIconKeysToHugeiconsSlugs`
Expected: file at `db/migrate/<timestamp>_convert_icon_keys_to_hugeicons_slugs.rb`.

- [ ] **Step 2: Write the migration body**

Replace the generated file's contents with:

```ruby
class ConvertIconKeysToHugeiconsSlugs < ActiveRecord::Migration[8.1]
  ALIASES = {
    "bed" => "bed-single-01", "brush" => "dental-care", "book" => "book-01",
    "dish" => "dish-01", "bookOpen" => "book-open-01", "bear" => "bone-01",
    "paw" => "bone-02", "music" => "music-note-01", "sun" => "sun-01",
    "home" => "home-01", "graduationCap" => "mortarboard-01", "muscle" => "dumbbell-01",
    "iceCream" => "ice-cream-01", "gamepad" => "game-controller-01",
    "ferris" => "ferris-wheel", "blocks" => "cube", "pizza" => "pizza-01",
    "film" => "film-01", "moon" => "moon-01", "bookSolid" => "bookmark-01",
    "gift" => "gift", "heart" => "favourite", "target" => "target-01",
    "star" => "star"
  }.freeze

  def up
    [GlobalTask, Reward].each do |klass|
      klass.reset_column_information
      klass.where.not(icon: [nil, ""]).find_each do |row|
        next if row.icon.include?("-") # already raw
        slug = ALIASES[row.icon]
        next unless slug
        klass.where(id: row.id).update_all(icon: slug)
      end
    end
  end

  def down
    # no-op — alias inversion is lossy
  end
end
```

- [ ] **Step 3: Write the migration spec**

Create `spec/migrations/convert_icon_keys_to_hugeicons_slugs_spec.rb`:

```ruby
require "rails_helper"

migration_dir = Rails.root.join("db/migrate")
migration_path = Dir.glob(migration_dir.join("*_convert_icon_keys_to_hugeicons_slugs.rb")).first
require migration_path

RSpec.describe ConvertIconKeysToHugeiconsSlugs do
  let(:family) { Family.create!(email: "m@example.com", password: "secret123") }

  it "rewrites curated keys to raw slugs on global_tasks" do
    task = GlobalTask.create!(family: family, title: "T", icon: "bed", points: 1, frequency: "daily")
    described_class.new.up
    expect(task.reload.icon).to eq("bed-single-01")
  end

  it "rewrites curated keys to raw slugs on rewards" do
    reward = Reward.create!(family: family, title: "R", icon: "iceCream", points: 5)
    described_class.new.up
    expect(reward.reload.icon).to eq("ice-cream-01")
  end

  it "leaves raw slugs untouched" do
    task = GlobalTask.create!(family: family, title: "T", icon: "bed-single-01", points: 1, frequency: "daily")
    described_class.new.up
    expect(task.reload.icon).to eq("bed-single-01")
  end

  it "is idempotent on re-run" do
    task = GlobalTask.create!(family: family, title: "T", icon: "bed", points: 1, frequency: "daily")
    described_class.new.up
    described_class.new.up
    expect(task.reload.icon).to eq("bed-single-01")
  end

  it "leaves unknown keys untouched" do
    task = GlobalTask.create!(family: family, title: "T", icon: "wat", points: 1, frequency: "daily")
    described_class.new.up
    expect(task.reload.icon).to eq("wat")
  end
end
```

> Note: required factory attributes for `GlobalTask` and `Reward` may differ slightly. Open the model + an existing factory (`spec/factories/global_tasks.rb`, `spec/factories/rewards.rb`) and adjust the `create!` calls to match. Do not add fields that don't exist; do add any required fields you find. Keep the spec assertions identical.

- [ ] **Step 4: Run the migration spec**

Run: `bundle exec rspec spec/migrations/convert_icon_keys_to_hugeicons_slugs_spec.rb`
Expected: 5 examples, 0 failures. If the create calls fail with validation errors, fix the call signatures based on the model + factories you read, then re-run.

- [ ] **Step 5: Apply the migration to the dev database**

Run: `bin/rails db:migrate`
Expected: migration runs cleanly, no exceptions. If existing seed data had curated keys, verify with: `bin/rails runner 'puts GlobalTask.distinct.pluck(:icon).inspect; puts Reward.distinct.pluck(:icon).inspect'`. Output should contain only raw slugs (or values that were never curated keys).

- [ ] **Step 6: Commit**

```bash
git add db/migrate db/schema.rb spec/migrations
git commit -m "feat(db): migrate icon columns to raw Hugeicons slugs"
```

---

## Task 8: System spec — full picker flow

**Files:**
- Create: `spec/system/parent/icon_picker_spec.rb`

- [ ] **Step 1: Write the system spec**

Create `spec/system/parent/icon_picker_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Icon picker", type: :system, js: true do
  include AuthSystemHelpers if defined?(AuthSystemHelpers)

  let!(:family) { Family.create!(email: "m@example.com", password: "secret123") }
  let!(:parent) { Profile.create!(family: family, name: "Pai", role: :parent, pin: "1234") }

  before do
    sign_in_as(parent) # provided by spec/support helpers in the repo (mirror existing parent system specs)
  end

  it "lets a parent pick a mission icon from the modal and persists the slug" do
    visit new_parent_global_task_path

    within("[data-controller='icon-picker']") do
      find("button[aria-label='Escolher ícone']").click
    end

    expect(page).to have_css("[data-icon-picker-target='searchInput']", visible: true)

    find("[data-icon-picker-target='catalogGrid']", visible: false) # ensure DOM exists
    find("[data-icon-picker-target='tabCatalog']").click

    find("[data-icon-picker-target='searchInput']").set("bed")

    find("[data-icon-picker-target='catalogGrid'] button[data-slug='bed-single-01']", wait: 5).click

    click_button "Confirmar"

    fill_in "Título", with: "Arrumar a cama"
    fill_in "Estrelinhas", with: 5
    click_button "Salvar Missão"

    expect(GlobalTask.last.icon).to eq("bed-single-01")
  end
end
```

> Note: `sign_in_as` is the repo's existing system-spec helper for the family + PIN auth flow (`spec/support/auth_system_helpers.rb`). If the helper has a different name, mirror the `before` block from another parent system spec (e.g. `spec/system/parent/global_tasks_spec.rb`) verbatim.

- [ ] **Step 2: Run the spec**

Run: `bundle exec rspec spec/system/parent/icon_picker_spec.rb`
Expected: 1 example, 0 failures. If the helper name is different, fix the `before` block by mirroring an existing parent system spec.

- [ ] **Step 3: Commit**

```bash
git add spec/system/parent/icon_picker_spec.rb
git commit -m "test(ui): system spec for icon picker flow"
```

---

## Task 9: Full suite + finalization

- [ ] **Step 1: Run the full RSpec suite**

Run: `bundle exec rspec`
Expected: all examples pass. Fix any regressions before proceeding.

- [ ] **Step 2: Run Rubocop**

Run: `bin/rubocop -a`
Expected: clean exit. Re-stage any auto-corrected files.

- [ ] **Step 3: Manual smoke test**

With `bin/dev` running, exercise: mission new + edit, reward new + edit. Verify search, pagination ("Carregar mais"), confirm/cancel both work. Reload the form after save and confirm the preview tile shows the persisted slug.

- [ ] **Step 4: Final commit (if any auto-fixes were re-staged)**

```bash
git status
git commit -m "chore: rubocop autocorrect for icon picker"   # only if there are staged changes
```

---

## Self-Review Notes (already applied)

- Spec coverage: every spec section maps to a task (manifest → Task 1, component + spec → Tasks 2–3, controller → Task 4, forms → Tasks 5–6, migration + spec → Task 7, system spec → Task 8).
- Placeholder scan: no TBDs. Where the plan can't fully predict (factory signatures in Task 7, helper name in Task 8), it gives an explicit fallback procedure (read existing factory / mirror existing system spec).
- Type consistency: target names, value names, and slug strings are consistent across the controller, the template, and the spec.
- Spec ↔ plan: storage policy (raw slugs), curated subsets per context, modal anatomy, and out-of-scope items all match the design doc.

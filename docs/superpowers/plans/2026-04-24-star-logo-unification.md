# Star Logo Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify all logo/brand-mark usages to a single star SVG (lucide star path) that renders in `--star` (gold) during day (06:00–19:59) and `--primary` (lilac) at night, replacing the moon-star variant and the animated star mascot on the profile selection page.

**Architecture:** `Ui::LogoMark::Component` already encapsulates the time-aware star render logic. The fix is removing the moon-star branch from its template. All other locations either already use `LogoMark` (parent nav) or are switched to use it (sessions page). Kid nav and parent mission list footer get new `LogoMark` placements.

**Tech Stack:** Rails 8.1 · ViewComponent 4.7 · ERB · CSS custom properties (`--star`, `--primary`) · RSpec + ViewComponent::TestHelpers

---

## Files

| Action | Path |
|--------|------|
| Modify | `app/components/ui/logo_mark/component.html.erb` |
| Modify | `spec/components/ui/logo_mark/component_spec.rb` |
| Modify | `app/views/sessions/index.html.erb` |
| Modify | `app/views/shared/_kid_nav.html.erb` |
| Modify | `app/views/parent/global_tasks/index.html.erb` |

---

### Task 1: Fix LogoMark template — star for both day and night

**Context:** Current template shows a moon-star SVG path at night. User wants the same star path in both periods, only the `stroke` color differs (`--star` day / `--primary` night — already correct in the Ruby component).

**Files:**
- Modify: `app/components/ui/logo_mark/component.html.erb`
- Modify: `spec/components/ui/logo_mark/component_spec.rb`

- [ ] **Step 1: Update the spec — night now expects the star path, not moon-star**

Replace the two night-path assertions in `spec/components/ui/logo_mark/component_spec.rb`:

```ruby
# BEFORE (remove these):
it "renders moon-star SVG path at night (22h)" do
  travel_to Time.zone.local(2024, 1, 1, 22, 0, 0) do
    render_inline(described_class.new)
    expect(page).to have_css("svg path[d*='M20.985 12.486']")
  end
end

# … later in boundary tests (hours 5 and 20):
it "is night at hour 5 (before DAY_START)" do
  travel_to Time.zone.local(2024, 1, 1, 5, 0, 0) do
    render_inline(described_class.new)
    expect(page).to have_css("svg path[d*='M20.985 12.486']")
  end
end

it "is night at hour 20 (DAY_END boundary)" do
  travel_to Time.zone.local(2024, 1, 1, 20, 0, 0) do
    render_inline(described_class.new)
    expect(page).to have_css("svg path[d*='M20.985 12.486']")
  end
end
```

Replace with:

```ruby
it "renders star SVG path at night (22h)" do
  travel_to Time.zone.local(2024, 1, 1, 22, 0, 0) do
    render_inline(described_class.new)
    expect(page).to have_css("svg path[d*='M11.525 2.295']")
  end
end

it "is night at hour 5 (before DAY_START)" do
  travel_to Time.zone.local(2024, 1, 1, 5, 0, 0) do
    render_inline(described_class.new)
    expect(page).to have_css("svg path[d*='M11.525 2.295']")
  end
end

it "is night at hour 20 (DAY_END boundary)" do
  travel_to Time.zone.local(2024, 1, 1, 20, 0, 0) do
    render_inline(described_class.new)
    expect(page).to have_css("svg path[d*='M11.525 2.295']")
  end
end
```

- [ ] **Step 2: Run tests — expect failures (moon-star branch still exists)**

```bash
bundle exec rspec spec/components/ui/logo_mark/component_spec.rb
```

Expected: 3 failures (`M20.985 12.486` path no longer expected, tests now look for star).

- [ ] **Step 3: Update LogoMark template to always render star**

Full replacement for `app/components/ui/logo_mark/component.html.erb`:

```erb
<%# lucide-rails 0.7.4 — star (day: --star / night: --primary) %>
<svg xmlns="http://www.w3.org/2000/svg"
     width="<%= size %>" height="<%= size %>"
     viewBox="0 0 24 24"
     fill="none"
     stroke="<%= stroke_color %>"
     stroke-width="2"
     stroke-linecap="round"
     stroke-linejoin="round"
     aria-hidden="true">
  <path d="M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z"/>
</svg>
```

- [ ] **Step 4: Run tests — expect all pass**

```bash
bundle exec rspec spec/components/ui/logo_mark/component_spec.rb
```

Expected: 9 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/components/ui/logo_mark/component.html.erb spec/components/ui/logo_mark/component_spec.rb
git commit -m "feat(logo): unified star icon for day and night — remove moon-star variant"
```

---

### Task 2: Sessions page — replace star mascot with LogoMark

**Context:** `sessions/index.html.erb` line 5 renders `shared/star_mascot` (an animated face-star) as the brand mark. Replace with `Ui::LogoMark::Component` for visual consistency.

**Files:**
- Modify: `app/views/sessions/index.html.erb`

- [ ] **Step 1: Replace star_mascot with LogoMark**

In `app/views/sessions/index.html.erb`, change line 5:

```erb
<%# BEFORE %>
<%= render "shared/star_mascot", size: 44 %>

<%# AFTER %>
<%= render Ui::LogoMark::Component.new(size: 56) %>
```

- [ ] **Step 2: Verify visually (no automated test needed for this swap)**

Start the server (`bin/dev`) and open the profile selection page at `http://localhost:3000`. Confirm:
- Star icon renders (day = gold, night = lilac) at 56px
- No mascot face visible
- Layout not broken

- [ ] **Step 3: Commit**

```bash
git add app/views/sessions/index.html.erb
git commit -m "feat(logo): replace star mascot with LogoMark on profile selection page"
```

---

### Task 3: Kid nav — add LogoMark brand section to sidebar

**Context:** `_kid_nav.html.erb` has zero branding (just nav items). Parent nav has a `.brand-mark` section with LogoMark. Add a minimal brand mark (star only, no label) at the top of the kid's `side-nav` for visual consistency.

**Files:**
- Modify: `app/views/shared/_kid_nav.html.erb`

- [ ] **Step 1: Add brand mark to side-nav**

In `app/views/shared/_kid_nav.html.erb`, add at the top of `<nav class="side-nav">` (before the loop):

```erb
<nav class="side-nav">
  <div class="brand-mark" style="display: flex; justify-content: center; padding: var(--space-4) 0 var(--space-3);">
    <%= render Ui::LogoMark::Component.new(size: 24) %>
  </div>
  <% nav_items.each do |item| %>
```

The full updated file should look like:

```erb
<%
  nav_items = [
    { icon: "target", path: kid_root_path,          label: "Jornada" },
    { icon: "bag",    path: kid_rewards_path,       label: "Lojinha" },
    { icon: "book",   path: kid_wallet_index_path,  label: "Diário"  },
  ]
%>

<nav class="side-nav">
  <div class="brand-mark" style="display: flex; justify-content: center; padding: var(--space-4) 0 var(--space-3);">
    <%= render Ui::LogoMark::Component.new(size: 24) %>
  </div>
  <% nav_items.each do |item| %>
    <% active = current_page?(item[:path]) %>
    <%= link_to item[:path], class: "nav-item #{active ? 'active' : ''}", title: item[:label] do %>
      <%= render Ui::Icon::Component.new(item[:icon], size: 22) %>
      <span class="nav-label"><%= item[:label] %></span>
    <% end %>
  <% end %>
  <div class="side-nav-spacer"></div>
  <%= button_to sessions_path, method: :delete, class: "nav-item", title: "Sair" do %>
    <%= render Ui::Icon::Component.new("logout", size: 22) %>
    <span class="nav-label">Sair</span>
  <% end %>
</nav>

<div class="bottom-nav">
  <% nav_items.each do |item| %>
    <% active = current_page?(item[:path]) %>
    <%= link_to item[:path], class: "nav-item #{active ? 'active' : ''}", title: item[:label] do %>
      <%= render Ui::Icon::Component.new(item[:icon], size: 22) %>
      <span class="nav-label"><%= item[:label] %></span>
    <% end %>
  <% end %>
  <%= button_to sessions_path, method: :delete, class: "nav-item", title: "Sair" do %>
    <%= render Ui::Icon::Component.new("logout", size: 22) %>
    <span class="nav-label">Sair</span>
  <% end %>
</div>
```

- [ ] **Step 2: Verify visually**

Open `http://localhost:3000` on a kid profile. On tablet/desktop width (>= 768px) where sidebar is visible, confirm:
- Star icon appears at top of sidebar in gold (day) or lilac (night)
- Nav items and layout unchanged

- [ ] **Step 3: Commit**

```bash
git add app/views/shared/_kid_nav.html.erb
git commit -m "feat(logo): add LogoMark brand mark to kid sidebar nav"
```

---

### Task 4: Parent mission list — add brand footer

**Context:** `parent/global_tasks/index.html.erb` shows a list of missions. After the card there is no branding. Add a small centered LogoMark + "LittleStars" footer below the card to anchor the page.

**Files:**
- Modify: `app/views/parent/global_tasks/index.html.erb`

- [ ] **Step 1: Add brand footer after the mission card**

In `app/views/parent/global_tasks/index.html.erb`, add after the closing `</div>` of the `.card` at line 53 (before the `<style>` block):

```erb
  <%# Brand footer %>
  <div style="display: flex; align-items: center; justify-content: center; gap: 8px; padding: 24px 0 8px; opacity: 0.35;">
    <%= render Ui::LogoMark::Component.new(size: 16) %>
    <span style="font-size: 11px; font-weight: 800; letter-spacing: .12em; color: var(--text-muted); text-transform: uppercase;">LittleStars</span>
  </div>
```

- [ ] **Step 2: Verify visually**

Open `http://localhost:3000` → parent login → Missões page. Confirm:
- Small star icon + "LITTLESTARS" text appears below mission list
- 35% opacity keeps it subtle
- No layout shift on empty state

- [ ] **Step 3: Commit**

```bash
git add app/views/parent/global_tasks/index.html.erb
git commit -m "feat(logo): add subtle brand footer to parent mission list"
```

---

## Verification

```bash
# Full suite — 0 regressions expected
bundle exec rspec spec/components/ui/logo_mark/component_spec.rb

# Run the wider suite to catch view regressions
bundle exec rspec spec/

# Visual check
bin/dev
# → http://localhost:3000  (profile picker — star logo)
# → log in as parent → sidebar (star logo in brand-mark)
# → Missões page → brand footer
# → log in as kid → sidebar star visible (desktop/tablet)
```

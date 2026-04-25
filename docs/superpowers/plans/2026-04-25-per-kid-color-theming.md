# Per-Kid Color Theming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make each kid's stored color (`Profile.color`) drive the visual palette of the kid layout and every kid-bound ViewComponent (kid cards, approval rows, activity rows, profile cards, initial chips) across both kid and parent interfaces.

**Architecture:** Reuse the existing `[data-palette="<name>"]` CSS scoping pattern already in `theme.css` (used by `aurora`/`galaxy`). Add one CSS override block per `Profile.color` value that re-binds `--primary` family + `--bg-soft`. A small helper resolves a profile to a palette name (`primary` fallback). The kid layout body and each kid-bound ViewComponent root carry `data-palette="<color>"` so the override cascades through the subtree.

**Tech Stack:** Rails 8.1, ViewComponent 4.7, Tailwind 4 (via Vite), RSpec + Capybara.

**Spec:** `docs/superpowers/specs/2026-04-25-per-kid-color-theming-design.md`

---

## File Structure

**Create:**
- `app/helpers/palette_helper.rb` — single helper `palette_for(profile)`.
- `spec/helpers/palette_helper_spec.rb` — helper unit spec.
- `spec/system/kid_palette_spec.rb` — system spec for kid layout body palette.
- `spec/system/parent_kid_card_palette_spec.rb` — system spec for parent dashboard kid card palette.

**Modify:**
- `app/assets/stylesheets/tailwind/theme.css` — fix coral hex collision, add `--c-peach-dark` + `--c-coral-dark`, add 6 `[data-palette="<color>"]` blocks.
- `app/views/layouts/kid.html.erb` — body uses `palette_for(current_profile)`.
- `app/components/ui/kid_management_card/component.html.erb` — wrap root in `data-palette`.
- `app/components/ui/kid_progress_card/component.html.erb` — wrap root in `data-palette`.
- `app/components/ui/approval_row/component.html.erb` — wrap root in `data-palette`.
- `app/components/ui/activity_row/component.html.erb` — wrap root in `data-palette`.
- `app/components/ui/profile_card/component.html.erb` — wrap root in `data-palette`.
- `app/components/ui/kid_initial_chip/component.html.erb` — wrap root in `data-palette`.

**Add component spec files (none currently exist for these — TDD-style):**
- `spec/components/ui/kid_management_card/component_spec.rb`
- `spec/components/ui/kid_progress_card/component_spec.rb`
- `spec/components/ui/approval_row/component_spec.rb`
- `spec/components/ui/activity_row/component_spec.rb`
- `spec/components/ui/profile_card/component_spec.rb`
- `spec/components/ui/kid_initial_chip/component_spec.rb`

**Out of scope (per spec):**
- `kid_avatar` and `smiley_avatar` are NOT wrapped — their inline-styled SVG/border already encodes the kid's color.
- No data migration. Blank `Profile.color` falls back to `primary` (default theme).

---

## Task 1: Baseline & Branch

**Files:** none modified.

- [ ] **Step 1: Verify clean working tree**

Run: `git status`
Expected: only the in-progress brainstorm spec/plan files (or fully clean). No staged unrelated changes.

- [ ] **Step 2: Run baseline test suite to confirm green starting point**

Run inside the `web` container: `bundle exec rspec --fail-fast`
Expected: 0 failures. If any pre-existing failures appear, stop and surface them — do not start work on a red baseline.

- [ ] **Step 3: Confirm Profile.color values are exactly the expected set**

Run: `grep -n "validates :color" app/models/profile.rb`
Expected output line:
```
validates :color, inclusion: { in: %w[peach rose mint sky lilac coral primary], allow_blank: true }
```
If the validation set differs, stop and surface — the CSS palette names in Task 3 must match this list 1-to-1.

---

## Task 2: Fix coral hex collision + add missing `-dark` variants

**Files:**
- Modify: `app/assets/stylesheets/tailwind/theme.css` (color tokens block, currently lines ~26-48)

**Why first:** The palette overrides in Task 3 reference `--c-peach-dark` and `--c-coral-dark`, neither of which currently exist. `--c-coral` is a duplicate of `--c-rose` and would render identically. Both must land before the overrides.

- [ ] **Step 1: Locate the color tokens block**

Run: `grep -n "c-coral\|c-peach" app/assets/stylesheets/tailwind/theme.css`
Expected: lines around 26-48 listing `--c-peach`, `--c-peach-soft`, `--c-peach-depth`, `--c-coral`, `--c-coral-soft`, `--c-coral-depth`. No `-dark` variants present for peach or coral.

- [ ] **Step 2: Replace the coral hex and add coral-dark**

Find this exact line:
```css
  --c-coral: #EC4899;
```
Replace with:
```css
  --c-coral: #FF7F50;
  --c-coral-dark: #D9531E;
```

Find this exact line:
```css
  --c-coral-soft: #FCE7F3;
```
Replace with:
```css
  --c-coral-soft: #FFE5D9;
```

- [ ] **Step 3: Add peach-dark sibling**

Find this exact line:
```css
  --c-peach-soft: #FCE7F3;
```
Replace with:
```css
  --c-peach-soft: #FCE7F3;
  --c-peach-dark: #BE185D;
```

- [ ] **Step 4: Verify all palette values now have -dark variants**

Run: `grep -n "c-\(peach\|rose\|mint\|sky\|lilac\|coral\)-dark" app/assets/stylesheets/tailwind/theme.css`
Expected: 6 matches — one `-dark` per palette name.

- [ ] **Step 5: Commit**

```bash
git add app/assets/stylesheets/tailwind/theme.css
git commit -m "fix(theme): distinct coral hex + add peach-dark/coral-dark tokens

Coral previously aliased to rose hex (#EC4899) and rendered
identically. Set coral to a true coral hue (#FF7F50) and add
the missing -dark variants needed by the per-kid palette overrides."
```

---

## Task 3: Add per-color CSS palette overrides

**Files:**
- Modify: `app/assets/stylesheets/tailwind/theme.css` (insert after the existing `[data-palette="galaxy"]` block, currently around line 157)

- [ ] **Step 1: Confirm insertion point**

Run: `grep -n 'data-palette="galaxy"' app/assets/stylesheets/tailwind/theme.css`
Expected: one match (currently around line 149). The new blocks go immediately after the closing `}` of that rule, before the next `@theme` block.

- [ ] **Step 2: Insert the 6 palette override blocks**

After the closing `}` of `[data-palette="galaxy"] { ... }` and before `@theme {`, insert exactly:

```css
/* ─── Per-kid palettes (driven by Profile.color) ─── */
[data-palette="peach"] {
  --primary: var(--c-peach);
  --primary-2: var(--c-peach-dark);
  --primary-soft: var(--c-peach-soft);
  --primary-glow: var(--c-peach);
  --bg-soft: var(--c-peach-soft);
}

[data-palette="rose"] {
  --primary: var(--c-rose);
  --primary-2: var(--c-rose-dark);
  --primary-soft: var(--c-rose-soft);
  --primary-glow: var(--c-rose);
  --bg-soft: var(--c-rose-soft);
}

[data-palette="mint"] {
  --primary: var(--c-mint);
  --primary-2: var(--c-mint-dark);
  --primary-soft: var(--c-mint-soft);
  --primary-glow: var(--c-mint);
  --bg-soft: var(--c-mint-soft);
}

[data-palette="sky"] {
  --primary: var(--c-sky);
  --primary-2: var(--c-sky-dark);
  --primary-soft: var(--c-sky-soft);
  --primary-glow: var(--c-sky);
  --bg-soft: var(--c-sky-soft);
}

[data-palette="lilac"] {
  --primary: var(--c-lilac);
  --primary-2: var(--c-lilac-dark);
  --primary-soft: var(--c-lilac-soft);
  --primary-glow: var(--c-lilac);
  --bg-soft: var(--c-lilac-soft);
}

[data-palette="coral"] {
  --primary: var(--c-coral);
  --primary-2: var(--c-coral-dark);
  --primary-soft: var(--c-coral-soft);
  --primary-glow: var(--c-coral);
  --bg-soft: var(--c-coral-soft);
}
```

`primary` is intentionally absent — `[data-palette="primary"]` is a no-op (uses defaults).

- [ ] **Step 3: Verify all 6 blocks present**

Run: `grep -nE 'data-palette="(peach|rose|mint|sky|lilac|coral)"' app/assets/stylesheets/tailwind/theme.css`
Expected: 6 matches.

- [ ] **Step 4: Commit**

```bash
git add app/assets/stylesheets/tailwind/theme.css
git commit -m "feat(theme): add per-kid data-palette overrides

Six new CSS scopes (peach, rose, mint, sky, lilac, coral) override
--primary family and --bg-soft. Reuses the existing aurora/galaxy
override mechanism. Anything wrapped in data-palette=<color>
recolors its subtree."
```

---

## Task 4: PaletteHelper (TDD)

**Files:**
- Create: `app/helpers/palette_helper.rb`
- Test: `spec/helpers/palette_helper_spec.rb`

- [ ] **Step 1: Write the failing helper spec**

Create `spec/helpers/palette_helper_spec.rb` with:

```ruby
require "rails_helper"

RSpec.describe PaletteHelper, type: :helper do
  describe "#palette_for" do
    it "returns the profile's color when present" do
      profile = build_stubbed(:profile, color: "mint")
      expect(helper.palette_for(profile)).to eq("mint")
    end

    it "returns 'primary' when profile color is blank" do
      profile = build_stubbed(:profile, color: "")
      expect(helper.palette_for(profile)).to eq("primary")
    end

    it "returns 'primary' when profile color is nil" do
      profile = build_stubbed(:profile, color: nil)
      expect(helper.palette_for(profile)).to eq("primary")
    end

    it "returns 'primary' when profile is nil" do
      expect(helper.palette_for(nil)).to eq("primary")
    end
  end
end
```

- [ ] **Step 2: Run the spec — confirm it fails**

Run: `bundle exec rspec spec/helpers/palette_helper_spec.rb`
Expected: FAIL — `uninitialized constant PaletteHelper` (or `NoMethodError: palette_for`).

- [ ] **Step 3: Implement the helper**

Create `app/helpers/palette_helper.rb`:

```ruby
module PaletteHelper
  def palette_for(profile)
    profile&.color.presence || "primary"
  end
end
```

- [ ] **Step 4: Run the spec — confirm green**

Run: `bundle exec rspec spec/helpers/palette_helper_spec.rb`
Expected: 4 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/helpers/palette_helper.rb spec/helpers/palette_helper_spec.rb
git commit -m "feat(helper): PaletteHelper#palette_for resolves profile to palette name

Returns the kid's stored color, or 'primary' when blank/nil/missing.
Used by the kid layout and kid-bound ViewComponents to set
data-palette on their root element."
```

---

## Task 5: Apply palette to kid layout

**Files:**
- Modify: `app/views/layouts/kid.html.erb` (line 9)

- [ ] **Step 1: Replace the hardcoded body palette**

Find this exact line in `app/views/layouts/kid.html.erb`:

```erb
  <body class="min-h-screen bg-bg-deep overflow-x-hidden" data-palette="sky">
```

Replace with:

```erb
  <body class="min-h-screen bg-bg-deep overflow-x-hidden" data-palette="<%= palette_for(current_profile) %>">
```

- [ ] **Step 2: Manual smoke check via boot**

Run: `bin/dev` (or skip if already running). In another terminal: `curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/kid` (replace path with whatever route requires no auth, or skip — the system spec in Task 12 will validate the rendered HTML).

If `bin/dev` is not running, skip — Task 12's system spec is the real check.

- [ ] **Step 3: Commit**

```bash
git add app/views/layouts/kid.html.erb
git commit -m "feat(layout): kid layout palette follows current_profile.color

Body data-palette now reflects the signed-in kid's chosen color
instead of a hardcoded 'sky'. Falls back to 'primary' (no-op) when
the kid has no color set."
```

---

## Task 6: KidManagementCard wrap (TDD)

**Files:**
- Modify: `app/components/ui/kid_management_card/component.html.erb` (line 1)
- Test: `spec/components/ui/kid_management_card/component_spec.rb`

- [ ] **Step 1: Write the failing component spec**

Create `spec/components/ui/kid_management_card/component_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Ui::KidManagementCard::Component, type: :component do
  it "wraps root in data-palette matching kid color" do
    kid = build_stubbed(:profile, color: "mint", role: :child, name: "Theo", points: 0)
    render_inline(described_class.new(kid: kid))

    expect(page).to have_css('[data-palette="mint"]', count: 1)
  end

  it "uses 'primary' palette when kid color is blank" do
    kid = build_stubbed(:profile, color: nil, role: :child, name: "Anon", points: 0)
    render_inline(described_class.new(kid: kid))

    expect(page).to have_css('[data-palette="primary"]', count: 1)
  end
end
```

If the component's `initialize` needs more than `kid:` (e.g. `level:`, `balance:`, `missions_count:`), inspect `app/components/ui/kid_management_card/component.rb` and pass the minimum required defaults so the render succeeds. Keep the assertions identical.

- [ ] **Step 2: Run the spec — confirm it fails**

Run: `bundle exec rspec spec/components/ui/kid_management_card/component_spec.rb`
Expected: FAIL — `expected to find css "[data-palette=\"mint\"]" 1 time, but there were no matches`.

- [ ] **Step 3: Wrap the component root in data-palette**

In `app/components/ui/kid_management_card/component.html.erb`, find this exact opening line:

```erb
<div class="bg-surface rounded-md shadow-card overflow-hidden relative">
```

Replace with:

```erb
<div data-palette="<%= helpers.palette_for(kid) %>" class="bg-surface rounded-md shadow-card overflow-hidden relative">
```

(The component already exposes `kid` via its initializer / accessor — confirm by reading `component.rb`. If `kid` isn't a public reader, add `attr_reader :kid` in the Ruby file.)

- [ ] **Step 4: Run the spec — confirm green**

Run: `bundle exec rspec spec/components/ui/kid_management_card/component_spec.rb`
Expected: 2 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/components/ui/kid_management_card spec/components/ui/kid_management_card
git commit -m "feat(ui): KidManagementCard root carries data-palette of bound kid"
```

---

## Task 7: KidProgressCard wrap (TDD)

**Files:**
- Modify: `app/components/ui/kid_progress_card/component.html.erb` (line 1)
- Test: `spec/components/ui/kid_progress_card/component_spec.rb`

- [ ] **Step 1: Write the failing component spec**

Create `spec/components/ui/kid_progress_card/component_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Ui::KidProgressCard::Component, type: :component do
  it "wraps root in data-palette matching kid color" do
    kid = build_stubbed(:profile, color: "rose", role: :child, name: "Zoe", points: 12)
    render_inline(described_class.new(kid: kid, awaiting_count: 0, missions_count: 0))

    expect(page).to have_css('[data-palette="rose"]', count: 1)
  end

  it "uses 'primary' palette when kid color is blank" do
    kid = build_stubbed(:profile, color: nil, role: :child, name: "Anon", points: 0)
    render_inline(described_class.new(kid: kid, awaiting_count: 0, missions_count: 0))

    expect(page).to have_css('[data-palette="primary"]', count: 1)
  end
end
```

- [ ] **Step 2: Run the spec — confirm it fails**

Run: `bundle exec rspec spec/components/ui/kid_progress_card/component_spec.rb`
Expected: FAIL — no `[data-palette="rose"]` match.

- [ ] **Step 3: Wrap the component root in data-palette**

In `app/components/ui/kid_progress_card/component.html.erb`, the root is the rendered `Ui::Card::Component`. Wrap it in a `<div data-palette>`:

Find this exact opening line:

```erb
<%= render Ui::Card::Component.new(padding: "none", class: "overflow-hidden") do %>
```

Replace with:

```erb
<div data-palette="<%= helpers.palette_for(kid) %>">
  <%= render Ui::Card::Component.new(padding: "none", class: "overflow-hidden") do %>
```

Find the corresponding `<% end %>` at the bottom of the file (currently the last line) and append a closing `</div>`:

```erb
  <% end %>
</div>
```

- [ ] **Step 4: Run the spec — confirm green**

Run: `bundle exec rspec spec/components/ui/kid_progress_card/component_spec.rb`
Expected: 2 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/components/ui/kid_progress_card spec/components/ui/kid_progress_card
git commit -m "feat(ui): KidProgressCard root carries data-palette of bound kid"
```

---

## Task 8: ApprovalRow wrap (TDD)

**Files:**
- Modify: `app/components/ui/approval_row/component.html.erb` (line 1)
- Test: `spec/components/ui/approval_row/component_spec.rb`

- [ ] **Step 1: Write the failing component spec**

Create `spec/components/ui/approval_row/component_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Ui::ApprovalRow::Component, type: :component do
  let(:kid) { build_stubbed(:profile, color: "lilac", role: :child, name: "Lila", points: 0) }

  it "wraps root in data-palette matching kid color" do
    render_inline(described_class.new(
      kid: kid,
      title: "Brush teeth",
      meta: "today",
      points: 5,
      approve_url: "/x",
      reject_url: "/y"
    ))

    expect(page).to have_css('[data-palette="lilac"]', count: 1)
  end

  it "uses 'primary' palette when kid color is blank" do
    blank_kid = build_stubbed(:profile, color: nil, role: :child, name: "Anon", points: 0)
    render_inline(described_class.new(
      kid: blank_kid,
      title: "Brush teeth",
      meta: "today",
      points: 5,
      approve_url: "/x",
      reject_url: "/y"
    ))

    expect(page).to have_css('[data-palette="primary"]', count: 1)
  end
end
```

- [ ] **Step 2: Run the spec — confirm it fails**

Run: `bundle exec rspec spec/components/ui/approval_row/component_spec.rb`
Expected: FAIL — no `[data-palette="lilac"]` match.

- [ ] **Step 3: Add data-palette to root**

In `app/components/ui/approval_row/component.html.erb`, find this exact opening line:

```erb
<div<%= " id=\"#{dom_id}\"".html_safe if dom_id %> class="bg-surface rounded-card shadow-card border-none p-[14px]">
```

Replace with:

```erb
<div<%= " id=\"#{dom_id}\"".html_safe if dom_id %> data-palette="<%= helpers.palette_for(kid) %>" class="bg-surface rounded-card shadow-card border-none p-[14px]">
```

- [ ] **Step 4: Run the spec — confirm green**

Run: `bundle exec rspec spec/components/ui/approval_row/component_spec.rb`
Expected: 2 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/components/ui/approval_row spec/components/ui/approval_row
git commit -m "feat(ui): ApprovalRow root carries data-palette of bound kid"
```

---

## Task 9: ActivityRow wrap (TDD)

**Files:**
- Modify: `app/components/ui/activity_row/component.html.erb` (line 1)
- Test: `spec/components/ui/activity_row/component_spec.rb`

- [ ] **Step 1: Write the failing component spec**

Create `spec/components/ui/activity_row/component_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Ui::ActivityRow::Component, type: :component do
  let(:kid) { build_stubbed(:profile, color: "peach", role: :child, name: "Zoe", points: 0) }

  it "wraps root in data-palette matching kid color" do
    render_inline(described_class.new(
      kid: kid,
      description: "Earned a star",
      timestamp: Time.current,
      amount: 5,
      direction: "earn"
    ))

    expect(page).to have_css('[data-palette="peach"]', count: 1)
  end

  it "uses 'primary' palette when kid color is blank" do
    blank_kid = build_stubbed(:profile, color: nil, role: :child, name: "Anon", points: 0)
    render_inline(described_class.new(
      kid: blank_kid,
      description: "Earned a star",
      timestamp: Time.current,
      amount: 5,
      direction: "earn"
    ))

    expect(page).to have_css('[data-palette="primary"]', count: 1)
  end
end
```

- [ ] **Step 2: Run the spec — confirm it fails**

Run: `bundle exec rspec spec/components/ui/activity_row/component_spec.rb`
Expected: FAIL — no `[data-palette="peach"]` match.

- [ ] **Step 3: Add data-palette to root**

In `app/components/ui/activity_row/component.html.erb`, find this exact opening line:

```erb
<div class="flex items-center gap-3.5 py-3.5 <%= with_divider ? 'border-b border-[var(--hairline)]' : '' %>">
```

Replace with:

```erb
<div data-palette="<%= helpers.palette_for(kid) %>" class="flex items-center gap-3.5 py-3.5 <%= with_divider ? 'border-b border-[var(--hairline)]' : '' %>">
```

- [ ] **Step 4: Run the spec — confirm green**

Run: `bundle exec rspec spec/components/ui/activity_row/component_spec.rb`
Expected: 2 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/components/ui/activity_row spec/components/ui/activity_row
git commit -m "feat(ui): ActivityRow root carries data-palette of bound kid"
```

---

## Task 10: ProfileCard wrap (TDD)

**Files:**
- Modify: `app/components/ui/profile_card/component.html.erb` (line 1)
- Test: `spec/components/ui/profile_card/component_spec.rb`

- [ ] **Step 1: Write the failing component spec**

Create `spec/components/ui/profile_card/component_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Ui::ProfileCard::Component, type: :component do
  it "wraps root in data-palette matching profile color" do
    profile = build_stubbed(:profile, color: "sky", role: :child, name: "Theo", points: 0)
    render_inline(described_class.new(profile: profile, url: "/x"))

    expect(page).to have_css('[data-palette="sky"]', count: 1)
  end

  it "uses 'primary' palette when profile color is blank" do
    profile = build_stubbed(:profile, color: nil, role: :child, name: "Anon", points: 0)
    render_inline(described_class.new(profile: profile, url: "/x"))

    expect(page).to have_css('[data-palette="primary"]', count: 1)
  end
end
```

- [ ] **Step 2: Run the spec — confirm it fails**

Run: `bundle exec rspec spec/components/ui/profile_card/component_spec.rb`
Expected: FAIL — no `[data-palette="sky"]` match.

- [ ] **Step 3: Wrap form_with output in data-palette**

`profile_card/component.html.erb` renders a `form_with` as the root. Wrap it:

Find this exact opening line:

```erb
<%= helpers.form_with url: @url, method: :post do |f| %>
```

Replace with:

```erb
<div data-palette="<%= helpers.palette_for(@profile) %>">
  <%= helpers.form_with url: @url, method: :post do |f| %>
```

Find the closing `<% end %>` at the bottom of the file and append the wrapper closer:

```erb
  <% end %>
</div>
```

- [ ] **Step 4: Run the spec — confirm green**

Run: `bundle exec rspec spec/components/ui/profile_card/component_spec.rb`
Expected: 2 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/components/ui/profile_card spec/components/ui/profile_card
git commit -m "feat(ui): ProfileCard root carries data-palette of bound profile"
```

---

## Task 11: KidInitialChip wrap (TDD)

**Files:**
- Modify: `app/components/ui/kid_initial_chip/component.html.erb` (line 1)
- Test: `spec/components/ui/kid_initial_chip/component_spec.rb`

- [ ] **Step 1: Write the failing component spec**

Create `spec/components/ui/kid_initial_chip/component_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Ui::KidInitialChip::Component, type: :component do
  it "wraps root in data-palette matching profile color" do
    profile = build_stubbed(:profile, color: "coral", role: :child, name: "Lila", points: 0)
    render_inline(described_class.new(profile: profile))

    expect(page).to have_css('[data-palette="coral"]', count: 1)
  end

  it "uses 'primary' palette when profile color is blank" do
    profile = build_stubbed(:profile, color: nil, role: :child, name: "Anon", points: 0)
    render_inline(described_class.new(profile: profile))

    expect(page).to have_css('[data-palette="primary"]', count: 1)
  end
end
```

- [ ] **Step 2: Run the spec — confirm it fails**

Run: `bundle exec rspec spec/components/ui/kid_initial_chip/component_spec.rb`
Expected: FAIL — no `[data-palette="coral"]` match.

- [ ] **Step 3: Add data-palette to root span**

In `app/components/ui/kid_initial_chip/component.html.erb`, find this exact opening:

```erb
<span title="<%= profile&.name %>"
      class="flex items-center justify-center"
```

Replace with:

```erb
<span title="<%= profile&.name %>"
      data-palette="<%= helpers.palette_for(profile) %>"
      class="flex items-center justify-center"
```

- [ ] **Step 4: Run the spec — confirm green**

Run: `bundle exec rspec spec/components/ui/kid_initial_chip/component_spec.rb`
Expected: 2 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/components/ui/kid_initial_chip spec/components/ui/kid_initial_chip
git commit -m "feat(ui): KidInitialChip root carries data-palette of bound profile"
```

---

## Task 12: System spec — kid layout reflects kid color

**Files:**
- Test: `spec/system/kid_palette_spec.rb`

**Why a system spec, not request:** body palette only applies after PIN-based profile session is established; easier to drive end-to-end.

- [ ] **Step 1: Inspect existing kid sign-in spec for patterns**

Run: `ls spec/system/ | head -30 && grep -l "PIN\|profile_session\|sign.*kid" spec/system/*.rb 2>/dev/null | head -5`
Expected: existing system specs that sign in a kid via PIN. Reuse their helpers/factories. If a `sign_in_as` helper already exists in `spec/support/`, prefer it.

- [ ] **Step 2: Write the failing system spec**

Create `spec/system/kid_palette_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Kid layout palette", type: :system do
  it "renders body with data-palette matching the signed-in kid's color" do
    family = create(:family)
    kid = create(:profile, family: family, role: :child, color: "mint",
                           name: "Theo", pin: "1234", points: 0)
    parent = create(:profile, family: family, role: :parent,
                              email: "p@example.com", pin: "9999")

    visit root_path
    # Adapt the next 3 lines to the project's PIN sign-in flow:
    click_on kid.name
    fill_in "PIN", with: "1234"
    click_on "Entrar"

    expect(page).to have_css('body[data-palette="mint"]')
  end

  it "falls back to 'primary' when the kid has no color set" do
    family = create(:family)
    kid = create(:profile, family: family, role: :child, color: nil,
                           name: "Anon", pin: "1234", points: 0)
    parent = create(:profile, family: family, role: :parent,
                              email: "p@example.com", pin: "9999")

    visit root_path
    click_on kid.name
    fill_in "PIN", with: "1234"
    click_on "Entrar"

    expect(page).to have_css('body[data-palette="primary"]')
  end
end
```

If any field/button label differs in the actual UI, mirror what the existing kid sign-in system spec uses. The assertion lines (`have_css 'body[data-palette=...]'`) are the load-bearing checks — do not change them.

- [ ] **Step 3: Run the spec — confirm it fails on the assertion (not on sign-in)**

Run: `bundle exec rspec spec/system/kid_palette_spec.rb`
Expected: FAIL with a `have_css 'body[data-palette="mint"]'` mismatch (current body would carry palette as set by Task 5 — if Task 5 was correctly applied, this should already pass; if so, that confirms the layer works end-to-end and the spec graduates from red to green without a code change). If the failure is a sign-in flow mismatch, fix the spec's sign-in steps to match the project's actual flow before proceeding.

- [ ] **Step 4: Run again — confirm green**

Run: `bundle exec rspec spec/system/kid_palette_spec.rb`
Expected: 2 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add spec/system/kid_palette_spec.rb
git commit -m "test(system): kid layout body data-palette tracks kid color"
```

---

## Task 13: System spec — parent dashboard kid card palette

**Files:**
- Test: `spec/system/parent_kid_card_palette_spec.rb`

- [ ] **Step 1: Inspect parent dashboard for which component renders kid cards**

Run: `grep -rln "KidManagementCard\|KidProgressCard" app/views/parent`
Expected: at least one view (likely `app/views/parent/dashboard/index.html.erb` or `app/views/parent/profiles/index.html.erb`). Note which component is used so the assertion targets the right palette wrapper.

- [ ] **Step 2: Write the failing system spec**

Create `spec/system/parent_kid_card_palette_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Parent dashboard kid card palette", type: :system do
  it "renders each kid's card wrapped in their data-palette" do
    family = create(:family)
    parent = create(:profile, family: family, role: :parent,
                              email: "p@example.com", pin: "9999",
                              name: "Mom")
    create(:profile, family: family, role: :child, name: "Theo",
                     color: "mint", pin: "1111", points: 0)
    create(:profile, family: family, role: :child, name: "Zoe",
                     color: "rose", pin: "2222", points: 0)

    visit root_path
    # Adapt to project's parent sign-in flow:
    click_on "Mom"
    fill_in "PIN", with: "9999"
    click_on "Entrar"

    # Visit whatever route lists kids — adjust if not /parent
    visit parent_root_path

    expect(page).to have_css('[data-palette="mint"]')
    expect(page).to have_css('[data-palette="rose"]')
  end
end
```

- [ ] **Step 3: Run the spec — confirm it fails or passes correctly**

Run: `bundle exec rspec spec/system/parent_kid_card_palette_spec.rb`
Expected: PASS if Tasks 6/7 wrapped the actual card used on the parent dashboard. If FAIL, check which component is actually rendered on that page (Step 1) and adjust the corresponding ERB wrap (Task 6 or Task 7) so its root sits in the rendered HTML.

- [ ] **Step 4: Commit**

```bash
git add spec/system/parent_kid_card_palette_spec.rb
git commit -m "test(system): parent dashboard kid cards wrap in per-kid data-palette"
```

---

## Task 14: Full suite + visual smoke

**Files:** none modified.

- [ ] **Step 1: Run full RSpec suite**

Run: `bundle exec rspec`
Expected: 0 failures. Pre-existing test count + 14 new examples (4 helper + 12 component + 3 system).

- [ ] **Step 2: Run rubocop**

Run: `bin/rubocop -a`
Expected: no offenses (or auto-corrected). Re-run plain `bin/rubocop` if anything was corrected — must end clean.

- [ ] **Step 3: Manual visual smoke (browser)**

Start `bin/dev` if not running. In a browser, sign in as a kid with each color in turn (peach, rose, mint, sky, lilac, coral). Verify:
- Kid dashboard primary buttons take the chosen color.
- Soft backgrounds tint to a matching pastel.
- Star/coin icons stay gold (semantic check).

Then sign in as a parent with at least 2 kids of distinct colors. Verify:
- Each kid card on the parent dashboard takes its kid's color.
- Approval queue rows tint to the submitting kid's color.
- Activity log entries tint to the kid's color.

If any element looks wrong, identify whether (a) the wrapping component is missing the `data-palette` (re-open the matching task), (b) the element uses a CSS variable not yet covered by the override (extend Task 3), or (c) the element uses a hardcoded color that bypasses the theme entirely (out of scope for this plan — log as follow-up).

- [ ] **Step 4: Commit any auto-fixes from rubocop**

If `bin/rubocop -a` made changes:

```bash
git add -A
git commit -m "chore: rubocop autocorrect for per-kid palette work"
```

Otherwise skip.

---

## Done Criteria

- All 14 tasks check-marked.
- `bundle exec rspec` green.
- `bin/rubocop` green.
- Manually verified all 6 colors render distinctly in kid layout and on parent dashboard kid cards.
- `Profile.color` blank/nil falls back to `primary` (default theme) — confirmed by spec, no visual regression vs current state for kids without a color.

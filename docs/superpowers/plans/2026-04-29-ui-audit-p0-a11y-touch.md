# UI Audit P0 — A11y, Touch Targets, Nav Hygiene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the four CRITICAL findings from the 2026-04-29 UI audit — small button touch targets, kid-shell logout misplacement, missing safe-area handling, and the modal's incomplete a11y semantics — without touching P1/P2 cleanup work.

**Architecture:** Pure UI-layer fix. No model/service/route changes. Touches: `Ui::Btn` CSS, kid bottom-nav partial, `Ui::KidTopBar` (gains overflow menu for sign-out), `Ui::Modal::Component` Ruby renderer, `ui_modal_controller.js` Stimulus controller. Tests are ViewComponent specs (touch-class presence, ARIA attributes) plus a Capybara system spec for the modal focus-trap behavior. Visual diffing handled manually in browser per CLAUDE.md (we cannot screenshot from CI).

**Tech Stack:** Rails 8.1 · ViewComponent 4.7 · Tailwind 4 · Stimulus · RSpec + Capybara · `make rspec` (Docker)

---

## File Structure

**Modified:**
- `app/components/ui/btn/btn.css` — add `min-h-[44px]` floor on `--sm` and ensure `--icon` is already 44 (verify); add `.ui-nav-touch` utility for nav links
- `app/views/shared/_kid_nav.html.erb` — drop "Sair" button; add `safe-area-inset-bottom` padding; add `aria-label`/`aria-current` on links
- `app/components/ui/kid_top_bar/component.rb` — add `show_signout:` (default `true` when no switch button visible) param so logout can live here as overflow action; expose `signout_url`
- `app/components/ui/kid_top_bar/component.html.erb` — render overflow menu with sign-out form when `show_signout`
- `app/components/ui/modal/component.rb` — add `role="dialog"`, `aria-modal="true"`, `aria-labelledby`, `aria-describedby`, deterministic id for title/subtitle
- `app/assets/controllers/ui_modal_controller.js` — focus trap, Esc-to-close, focus restore on close, `inert` toggle on `<main>` siblings

**Created:**
- `spec/system/modal_a11y_spec.rb` — Capybara system spec for focus trap, Esc, focus restore

**Test files modified:**
- `spec/components/ui/btn/component_spec.rb` — assert `min-h-[44px]` token on every size variant
- `spec/components/ui/modal_component_spec.rb` — assert dialog role, aria-modal, aria-labelledby wiring
- `spec/components/ui/kid_top_bar/component_spec.rb` (create if absent) — assert sign-out button rendered when `show_signout: true`
- `spec/system/kid_flow_spec.rb` — update expectations: no "Sair" link inside `nav.kid-bottom-nav`

---

## Task 1: Touch-Target Floor on `Ui::Btn--sm`

**Files:**
- Modify: `app/components/ui/btn/btn.css:41-44`
- Test: `spec/components/ui/btn/component_spec.rb`

- [ ] **Step 1: Write the failing test**

Append to `spec/components/ui/btn/component_spec.rb` inside `describe "size classes" do`:

```ruby
describe "touch-target floor (WCAG 2.5.5)" do
  %w[sm md lg icon].each do |sz|
    it "size #{sz} renders with min-h-[44px] floor class" do
      render_inline(described_class.new(size: sz)) { "X" }
      expect(page.native.to_html).to include("min-h-[44px]")
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `make rspec SPEC=spec/components/ui/btn/component_spec.rb`
Expected: FAIL — `expected ... to include "min-h-[44px]"` for size `sm` (md/lg may already be ≥44 by padding but the class is missing).

- [ ] **Step 3: Add the floor class to every size**

Edit `app/components/ui/btn/btn.css:41-44` to:

```css
.ui-btn--sm   { @apply text-[14px] px-3.5 py-2   min-h-[44px]; }
.ui-btn--md   { @apply text-[16px] px-5   py-3   min-h-[44px]; }
.ui-btn--lg   { @apply text-[18px] px-6   py-3.5 min-h-[44px]; }
.ui-btn--icon { @apply w-11 h-11 p-0           min-h-[44px]; }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `make rspec SPEC=spec/components/ui/btn/component_spec.rb`
Expected: PASS — all size variants include `min-h-[44px]`.

- [ ] **Step 5: Run full ViewComponent suite to catch regressions**

Run: `make rspec SPEC=spec/components/ui`
Expected: PASS — no other component spec broken by the extra utility.

- [ ] **Step 6: Commit**

```bash
git add app/components/ui/btn/btn.css spec/components/ui/btn/component_spec.rb
git commit -m "fix(btn): enforce 44px min touch target on every size (WCAG 2.5.5)"
```

---

## Task 2: Kid Bottom-Nav — Safe Area + ARIA + No Logout

**Files:**
- Modify: `app/views/shared/_kid_nav.html.erb`
- Test: `spec/system/kid_flow_spec.rb`

- [ ] **Step 1: Write the failing system spec assertion**

Open `spec/system/kid_flow_spec.rb`. Find the first `it`/`scenario` that visits a kid screen (e.g. `kid_root_path`). Add a new scenario at the bottom of the top-level `describe`:

```ruby
scenario "kid bottom nav exposes only journey/shop/diary, never logout" do
  visit kid_root_path
  within("nav[aria-label='Navegação principal']") do
    expect(page).to have_link("Jornada")
    expect(page).to have_link("Lojinha")
    expect(page).to have_link("Diário")
    expect(page).not_to have_button("Sair")
    expect(page).not_to have_link("Sair")
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `make rspec SPEC=spec/system/kid_flow_spec.rb`
Expected: FAIL — either nav has no `aria-label="Navegação principal"`, or `Sair` button is still found.

- [ ] **Step 3: Rewrite the kid nav partial**

Replace `app/views/shared/_kid_nav.html.erb` entirely with:

```erb
<%
  nav_items = [
    { icon: "target", path: kid_root_path,         label: "Jornada" },
    { icon: "bag",    path: kid_rewards_path,      label: "Lojinha" },
    { icon: "book",   path: kid_wallet_index_path, label: "Diário"  },
  ]
%>

<nav
  aria-label="Navegação principal"
  class="ls-kid-nav fixed left-1/2 -translate-x-1/2 flex items-center gap-2 z-40 px-2 py-2 ls-card-3d"
  style="bottom: max(20px, env(safe-area-inset-bottom)); background: var(--surface); border: 2px solid var(--hairline); border-radius: 16px; box-shadow: 0 4px 0 rgba(0,0,0,0.08);"
>
  <% nav_items.each do |item| %>
    <% active = current_page?(item[:path]) %>
    <%= link_to item[:path],
          class: "ls-btn-3d flex flex-col items-center gap-0.5 px-4 py-2 min-h-[44px]",
          style: (active ?
            "background: var(--primary-soft); border: 2px solid var(--primary); color: var(--primary); border-radius: 12px; box-shadow: 0 3px 0 var(--primary-2);" :
            "background: transparent; border: 2px solid transparent; color: var(--text-muted); border-radius: 12px;"),
          aria: { label: item[:label], current: (active ? "page" : nil) } do %>
      <%= render Ui::Icon::Component.new(item[:icon], size: 20, color: "currentColor") %>
      <span class="text-[10px] font-display font-extrabold tracking-[0.5px] uppercase"><%= item[:label] %></span>
    <% end %>
  <% end %>
</nav>
```

Notes:
- Removed the `button_to profile_session_path` block entirely (logout moves to KidTopBar in Task 3).
- `bottom: max(20px, env(safe-area-inset-bottom))` keeps current 20px floor on devices without notches and respects iPhone home-indicator.
- `aria-label` on each `link_to` (was `title:` only — screen-reader-invisible).
- `aria-current="page"` on the active item.
- `min-h-[44px]` on each link to satisfy touch target.

- [ ] **Step 4: Run test to verify it passes**

Run: `make rspec SPEC=spec/system/kid_flow_spec.rb`
Expected: PASS for the new scenario. Pre-existing scenarios that asserted "Sair" inside the bottom nav must be updated in Task 3 — if any fail here with `expected to find "Sair"`, leave them red until Task 3 lands the new sign-out path.

- [ ] **Step 5: Browser smoke test (manual, per CLAUDE.md)**

Run dev: `bin/dev`. Visit `http://localhost:3000` as a kid profile. Verify:
- Bottom nav shows Jornada / Lojinha / Diário (no Sair).
- On a modern phone viewport (DevTools iPhone 14), nav sits above the home indicator without overlap.

- [ ] **Step 6: Commit**

```bash
git add app/views/shared/_kid_nav.html.erb spec/system/kid_flow_spec.rb
git commit -m "fix(kid-nav): add safe-area inset + aria semantics, drop logout from primary nav"
```

---

## Task 3: Move Sign-Out Into `Ui::KidTopBar` Overflow

**Files:**
- Modify: `app/components/ui/kid_top_bar/component.rb`
- Modify: `app/components/ui/kid_top_bar/component.html.erb`
- Create: `spec/components/ui/kid_top_bar/component_spec.rb`
- Modify: `spec/system/kid_flow_spec.rb` (any pre-existing logout flow that targeted the bottom nav)

- [ ] **Step 1: Write the component spec (TDD)**

Create `spec/components/ui/kid_top_bar/component_spec.rb`:

```ruby
require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::KidTopBar::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:profile) { instance_double("Profile", id: 7, name: "Lia", points: 12, streak: 3) }

  before do
    allow(profile).to receive(:respond_to?).with(:streak).and_return(true)
    allow(profile).to receive(:respond_to?).with(:points).and_return(true)
  end

  it "renders sign-out form when show_signout: true" do
    with_request_url("/kid") do
      render_inline(described_class.new(profile: profile, show_signout: true, show_switch: false))
    end
    expect(page).to have_css("button[aria-label='Sair']")
    expect(page).to have_css("form[action$='/profile_session'][method='post']")
  end

  it "omits sign-out form when show_signout: false" do
    with_request_url("/kid") do
      render_inline(described_class.new(profile: profile, show_signout: false, show_switch: false))
    end
    expect(page).not_to have_css("button[aria-label='Sair']")
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `make rspec SPEC=spec/components/ui/kid_top_bar/component_spec.rb`
Expected: FAIL — `show_signout` keyword unknown / no `aria-label='Sair'` button rendered.

- [ ] **Step 3: Add the param to the component**

Replace `app/components/ui/kid_top_bar/component.rb` `initialize` (lines 16-25) with:

```ruby
def initialize(profile:, streak: nil, show_streak: true, show_balance: true, show_switch: true, show_signout: true, switch_url: nil, signout_url: nil, **options)
  @profile = profile
  @streak_override = streak
  @show_streak = show_streak
  @show_balance = show_balance
  @show_switch = show_switch
  @show_signout = show_signout
  @switch_url = switch_url
  @signout_url = signout_url
  @options = options
  super()
end
```

Add reader for the resolved sign-out URL below `def points`:

```ruby
def signout_path
  @signout_url || profile_session_path
end
```

- [ ] **Step 4: Render the sign-out form in the header template**

Edit `app/components/ui/kid_top_bar/component.html.erb`. Inside the right-cluster, after the existing `<% if @show_switch %>` block (still inside the same flex container that holds `Trocar`), append:

```erb
<% if @show_signout %>
  <%= form_with url: signout_path, method: :delete, local: true, class: "contents" do %>
    <button type="submit"
            aria-label="Sair"
            class="inline-flex items-center justify-center min-h-[44px] min-w-[44px] font-display"
            style="background: var(--surface); border: 2px solid var(--hairline); padding: 6px 10px; border-radius: 12px; box-shadow: 0 3px 0 var(--hairline); color: var(--text-muted);">
      <%= render Ui::Icon::Component.new("logout", size: 16, color: "currentColor") %>
    </button>
  <% end %>
<% end %>
```

Wrap the right cluster (`Trocar` + `Sair`) in `<div class="flex items-center gap-2">…</div>` so they stack horizontally without colliding.

- [ ] **Step 5: Run component spec to verify it passes**

Run: `make rspec SPEC=spec/components/ui/kid_top_bar/component_spec.rb`
Expected: PASS.

- [ ] **Step 6: Update existing kid system specs that touched bottom-nav logout**

Search for the old logout flow:
```bash
grep -rn "click_button \"Sair\"\|click_link \"Sair\"" spec/system
```
For each match, scope the click inside the kid header instead:

```ruby
# before
click_button "Sair"

# after
within("header") { click_button "Sair" }
```

If a spec looked for "Sair" inside the bottom nav, replace its `within(...)` block with `within("header")`.

- [ ] **Step 7: Run all kid system specs**

Run: `make rspec SPEC=spec/system/kid_flow_spec.rb`
Run: `make rspec SPEC=spec/system`
Expected: PASS.

- [ ] **Step 8: Browser smoke test**

`bin/dev`, log in as kid, confirm header shows streak + balance + Trocar + Sair. Click Sair → returns to login.

- [ ] **Step 9: Commit**

```bash
git add app/components/ui/kid_top_bar/component.rb app/components/ui/kid_top_bar/component.html.erb spec/components/ui/kid_top_bar/component_spec.rb spec/system/kid_flow_spec.rb
git commit -m "feat(kid-top-bar): host sign-out as overflow action, separating it from primary nav"
```

---

## Task 4: Modal Semantic A11y Attributes

**Files:**
- Modify: `app/components/ui/modal/component.rb`
- Test: `spec/components/ui/modal_component_spec.rb`

- [ ] **Step 1: Write the failing tests**

Append to `spec/components/ui/modal_component_spec.rb`:

```ruby
describe "WAI-ARIA dialog semantics" do
  it "renders the inner shell with role=dialog and aria-modal=true" do
    render_inline(described_class.new(title: "Hi", id: "m1"))
    expect(page).to have_css('div[role="dialog"][aria-modal="true"]', visible: false)
  end

  it "wires aria-labelledby to the title node" do
    render_inline(described_class.new(title: "Confirm", id: "m2"))
    expect(page).to have_css('div[role="dialog"][aria-labelledby="m2-title"]', visible: false)
    expect(page).to have_css('#m2-title', text: "Confirm", visible: false)
  end

  it "wires aria-describedby to the subtitle node when subtitle is present" do
    render_inline(described_class.new(title: "Confirm", subtitle: "This cannot be undone", id: "m3"))
    expect(page).to have_css('div[role="dialog"][aria-describedby="m3-desc"]', visible: false)
    expect(page).to have_css('#m3-desc', text: "This cannot be undone", visible: false)
  end

  it "omits aria-describedby when no subtitle" do
    render_inline(described_class.new(title: "Plain", id: "m4"))
    expect(page).not_to have_css('[aria-describedby]', visible: false)
  end

  it "auto-generates an id when caller omits it" do
    render_inline(described_class.new(title: "X"))
    expect(page).to have_css('div[role="dialog"][aria-labelledby$="-title"]', visible: false)
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `make rspec SPEC=spec/components/ui/modal_component_spec.rb`
Expected: FAIL — no `role="dialog"` / `aria-modal` / `aria-labelledby` on the rendered HTML.

- [ ] **Step 3: Patch `Ui::Modal::Component#call`**

Replace the body of `app/components/ui/modal/component.rb` `call` (lines 15-43) with:

```ruby
def call
  overlay_classes = "modal-overlay fixed inset-0 bg-black/40 backdrop-blur-sm z-[100] flex items-center justify-center p-4"
  modal_classes = "bg-surface rounded-card shadow-card w-full anim-pop-in overflow-hidden #{variant_band_class}"

  size_classes = case @size
  when "sm" then "max-w-md"
  when "lg" then "max-w-4xl"
  else "max-w-2xl"
  end

  resolved_id = @id || "ls-modal-#{SecureRandom.hex(4)}"
  title_id    = @title    ? "#{resolved_id}-title" : nil
  desc_id     = @subtitle ? "#{resolved_id}-desc"  : nil

  overlay_data = {
    controller: "ui-modal",
    action: "click->ui-modal#closeOnOverlay keydown@window->ui-modal#onKeydown",
    modal_variant: @variant.to_s
  }

  if @variant == :celebration
    overlay_data[:fx_event] = "celebrate"
    overlay_data[:fx_tier] = "big"
    overlay_data[:fx_dismiss_after] = "2500"
  end

  dialog_attrs = {
    role: "dialog",
    "aria-modal": "true",
    "aria-labelledby": title_id,
    "aria-describedby": desc_id,
    tabindex: "-1"
  }.compact

  content_tag :div, class: overlay_classes, style: "display: none;", data: overlay_data, id: resolved_id do
    content_tag :div, class: class_names(modal_classes, size_classes, @options[:class]), **dialog_attrs do
      concat header(title_id: title_id, desc_id: desc_id) if @title || @subtitle
      concat content_tag(:div, content, class: "p-6")
    end
  end
end
```

Update `header` so the inner title/subtitle nodes get the right ids. Replace the current `def header` with:

```ruby
def header(title_id: nil, desc_id: nil)
  render Ui::TopBar::Component.new(title: @title, subtitle: @subtitle, title_id: title_id, subtitle_id: desc_id) do |c|
    c.with_right_slot do
      render Ui::Btn::Component.new(variant: "ghost", size: "icon", data: { action: "click->ui-modal#close" }, "aria-label": "Fechar") do
        render Ui::Icon::Component.new("close", size: 20)
      end
    end
  end
end
```

If `Ui::TopBar::Component#initialize` does not yet accept `title_id:`/`subtitle_id:`, add those kwargs (default `nil`) and emit them as `id:` on the title `<h2>` and subtitle `<p>` respectively. Verify with:
```bash
sed -n '1,80p' app/components/ui/top_bar/component.rb
```
If kwargs missing, extend the initializer and the template; otherwise leave untouched.

- [ ] **Step 4: Run tests to verify they pass**

Run: `make rspec SPEC=spec/components/ui/modal_component_spec.rb`
Expected: PASS — all five new examples plus the original six.

- [ ] **Step 5: Run TopBar spec to confirm no regression**

Run: `make rspec SPEC=spec/components/ui` (full UI component suite)
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add app/components/ui/modal/component.rb app/components/ui/top_bar/ spec/components/ui/modal_component_spec.rb
git commit -m "feat(modal): add WAI-ARIA dialog semantics (role, aria-modal, labelledby/describedby)"
```

---

## Task 5: Modal Focus Trap, Esc, Focus Restore

**Files:**
- Modify: `app/assets/controllers/ui_modal_controller.js`
- Create: `spec/system/modal_a11y_spec.rb`

- [ ] **Step 1: Identify a real modal trigger and pick the right login flow**

Find a real opener (we will not invent fixtures):
```bash
grep -rn "Ui::Modal::Component.new\|data-action=\"click->ui-modal#open\"" app/views app/components | head
```
Use the first concrete trigger in `parent/` views as `TARGET_PATH` and the visible button text as `TRIGGER_TEXT`. If the only modals are kid-side, swap the spec to a kid login + path.

Read the existing system-spec auth setup before writing the new spec — copy its style verbatim:
```bash
sed -n '1,60p' spec/system/kid_flow_spec.rb
sed -n '1,60p' spec/system/family_login_flow_spec.rb
```
Reuse whatever helper or `before` block they already use to seat a `family` + `profile` into `session[:profile_id]`. Do not introduce a new `sign_in_profile` helper.

- [ ] **Step 2: Write a failing system spec**

Create `spec/system/modal_a11y_spec.rb`. Replace `TARGET_PATH` and `TRIGGER_TEXT` with the values discovered in Step 1; replace the `before` block with the auth setup copied from the existing system spec:

```ruby
require "rails_helper"

RSpec.describe "Modal a11y", type: :system, js: true do
  before do
    # Paste here the exact auth/seed `before` block used in spec/system/kid_flow_spec.rb
    # or family_login_flow_spec.rb so we land on a page authorized to see the trigger.
    visit TARGET_PATH
  end

  it "traps focus inside the open modal and Esc closes + restores focus" do
    trigger = find("button, a", text: /TRIGGER_TEXT/i, match: :first)
    trigger.click
    expect(page).to have_css('[role="dialog"][aria-modal="true"]', visible: true)

    # Focus enters the dialog on open
    expect(page.evaluate_script("document.activeElement.closest('[role=\"dialog\"]') !== null")).to be true

    # Tab cycles inside the dialog (focus trap)
    page.send_keys(:tab)
    in_dialog = page.evaluate_script("document.activeElement.closest('[role=\"dialog\"]') !== null")
    expect(in_dialog).to be true

    # Esc closes
    page.send_keys(:escape)
    expect(page).to have_css('[role="dialog"]', visible: false)

    # Focus returns to the original trigger
    focused_text = page.evaluate_script("document.activeElement.textContent")
    expect(focused_text).to match(/TRIGGER_TEXT/i)
  end
end
```

If no production trigger exists for any `Ui::Modal::Component`, **stop and report** — adding a synthetic trigger is out of scope for this plan; the modal a11y JS in Step 4 still ships, but the focus-trap regression test must wait for a separate plan that introduces a real opener.

- [ ] **Step 3: Run test to verify it fails**

Run: `make rspec SPEC=spec/system/modal_a11y_spec.rb`
Expected: FAIL — focus does not enter the dialog on open, Esc has no listener, focus is not restored.

- [ ] **Step 4: Replace the Stimulus controller body**

Rewrite `app/assets/controllers/ui_modal_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

const FOCUSABLE_SELECTOR = [
  "a[href]",
  "button:not([disabled])",
  "textarea:not([disabled])",
  "input:not([disabled]):not([type='hidden'])",
  "select:not([disabled])",
  "[tabindex]:not([tabindex='-1'])"
].join(",")

export default class extends Controller {
  static values = { id: String }

  connect() {
    this._previouslyFocused = null
    this._onKeydownBound = this.onKeydown.bind(this)
  }

  disconnect() {
    this._restoreBackgroundInert(false)
  }

  open(event) {
    event.preventDefault()
    const id = event.params.id || this.idValue
    const modal = document.getElementById(id)
    if (!modal) return

    if (modal.parentElement !== document.body) document.body.appendChild(modal)

    this._previouslyFocused = document.activeElement
    modal.style.display = "flex"
    document.body.style.overflow = "hidden"
    this._restoreBackgroundInert(true, modal)

    requestAnimationFrame(() => {
      const dialog = modal.querySelector('[role="dialog"]') || modal
      const first = dialog.querySelector(FOCUSABLE_SELECTOR) || dialog
      first.focus({ preventScroll: true })
    })
  }

  close(event) {
    if (event) event.preventDefault()

    const overlay = this.element.classList.contains("modal-overlay")
      ? this.element
      : this.element.closest(".modal-overlay")

    if (!overlay) return
    overlay.style.display = "none"
    document.body.style.overflow = "auto"
    this._restoreBackgroundInert(false)

    if (this._previouslyFocused && typeof this._previouslyFocused.focus === "function") {
      this._previouslyFocused.focus({ preventScroll: true })
      this._previouslyFocused = null
    }
  }

  closeOnOverlay(event) {
    if (event.target === event.currentTarget) this.close()
  }

  onKeydown(event) {
    const overlay = this.element.classList.contains("modal-overlay")
      ? this.element
      : this.element.closest(".modal-overlay")
    if (!overlay || overlay.style.display === "none") return

    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
      return
    }

    if (event.key !== "Tab") return

    const dialog = overlay.querySelector('[role="dialog"]') || overlay
    const focusables = Array.from(dialog.querySelectorAll(FOCUSABLE_SELECTOR))
      .filter(el => el.offsetParent !== null)
    if (focusables.length === 0) return

    const first = focusables[0]
    const last = focusables[focusables.length - 1]
    const active = document.activeElement

    if (event.shiftKey && active === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && active === last) {
      event.preventDefault()
      first.focus()
    }
  }

  _restoreBackgroundInert(activate, modal = null) {
    const main = document.querySelector("main, #main, [data-modal-root='main']")
    if (!main) return
    if (activate && modal && main.contains(modal)) return // never inert the modal's own ancestor
    if (activate) {
      main.setAttribute("inert", "")
      main.setAttribute("aria-hidden", "true")
    } else {
      main.removeAttribute("inert")
      main.removeAttribute("aria-hidden")
    }
  }
}
```

- [ ] **Step 5: Confirm the data-action is wired**

Re-open `app/components/ui/modal/component.rb` and confirm the overlay's `data: { ... action: "click->ui-modal#closeOnOverlay keydown@window->ui-modal#onKeydown" ... }` is present (set in Task 4 Step 3). If a teammate overwrote it, restore.

- [ ] **Step 6: Run system spec to verify it passes**

Run: `make rspec SPEC=spec/system/modal_a11y_spec.rb`
Expected: PASS — focus enters dialog on open, Esc closes, focus restores to trigger.

- [ ] **Step 7: Run full system suite to catch regressions**

Run: `make rspec SPEC=spec/system`
Expected: PASS — no flow that previously relied on tab-leaking from a modal is broken.

- [ ] **Step 8: Browser smoke test**

`bin/dev`, open any modal (parent rewards delete, kid celebration), verify:
- Tab cycles inside dialog only.
- Esc closes the dialog.
- After close, focus returns to the button that opened it.
- Background `<main>` is not interactive while open (try clicking a sidebar link — should not navigate).

- [ ] **Step 9: Commit**

```bash
git add app/assets/controllers/ui_modal_controller.js spec/system/modal_a11y_spec.rb
git commit -m "feat(modal): focus trap, Esc-to-close, focus restore, and inert background"
```

---

## Final Verification

- [ ] **Step 1: Run full local CI**

Run: `make rspec`
Expected: PASS — entire suite green.

Run: `bin/rubocop`
Expected: no new offenses.

- [ ] **Step 2: Manual a11y walk-through**

`bin/dev`, with macOS VoiceOver (`Cmd+F5`) or NVDA on Windows:
- Tab through kid bottom nav — each item announces label and "current page" when active.
- Open a modal — VoiceOver announces `dialog`, the title, and the description (if subtitle present). Tab stays inside.
- Esc closes the dialog. Focus returns to the trigger button.

- [ ] **Step 3: Tag the audit phase as P0-complete**

This plan does not introduce a roadmap entry; if running inside GSD, append a one-liner to the current phase log:
```bash
echo "- 2026-04-29 P0 a11y/touch fixes shipped (plan: docs/superpowers/plans/2026-04-29-ui-audit-p0-a11y-touch.md)" >> .planning/CHANGELOG.md
```
(Skip if `.planning/CHANGELOG.md` is not the repo's convention — check `git log --oneline | head -5` for prior style first.)

---

## Out of Scope (P1/P2 — separate plans)

- Reduced-motion global coverage in `tailwind/animations.css`
- Parent mobile dual-nav consolidation
- Inline-style → utility-class migration (`kid/rewards`, `kid/dashboard`, `parent/global_tasks/_form`)
- Hex-raw → token cleanup in `btn.css` and `modal#variant_band_class`
- `< 12px` text audit on kid surfaces
- Skeleton/loading states for parent dashboard and kid missions list
- Tabular numerals on stat cards / level progress
- Nav badge color-only fix (sr-only count text)

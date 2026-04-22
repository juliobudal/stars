# UI/UX Big Opportunities Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix four high-impact UI/UX gaps identified in the April 2026 audit: remaining broken turbo stream templates, CDN-dependent icon/font loading, CSS variable collision preventing Duolingo rebrand, and missing parent navigation.

**Architecture:** Each task is self-contained. Tasks 1–3 are refactors/fixes with no new Rails artifacts. Task 4 adds a bottom nav partial + `with-nav` padding. Tasks should be executed in order — Task 1 clears the turbo stream debt, Task 2 removes CDN risk, Task 3 makes the Duolingo brand colors visually effective, Task 4 closes the parent UX gap.

**Tech Stack:** Rails 8.1 · Tailwind 4 · ViewComponent 4.7 · ERB · CSS custom properties · Vite · `@phosphor-icons/web` npm package

---

## File Map

| File | Action | Reason |
|------|--------|--------|
| `app/views/parent/approvals/approve_redemption.turbo_stream.erb` | Modify | Fix `ui--confetti` → `celebration`, `bg-brand-green` flash, missing `pending_approvals_kpi` update |
| `app/views/parent/approvals/reject_redemption.turbo_stream.erb` | Modify | Fix `bg-red-600` raw HTML flash, inconsistent empty state |
| `app/views/shared/_head.html.erb` | Modify | Replace CDN links with self-hosted assets |
| `app/assets/stylesheets/tailwind/fonts.css` | Modify | Replace `@import` of Google Fonts URL with local font declarations |
| `app/assets/fonts/` | Create | Directory for self-hosted Nunito + Fredoka font files |
| `app/assets/stylesheets/tailwind/theme.css` | Modify | Change `--font-sans` from Fredoka to Nunito (align with design_system.css body font) |
| `app/assets/stylesheets/design_system.css` | Modify (already partially done) | Confirm no remaining `--primary`/`--success` overrides |
| `app/views/layouts/parent.html.erb` | Modify | Add `with-nav` class + bottom nav partial |
| `app/views/shared/_parent_nav.html.erb` | Create | Bottom nav for parent interface (4 items + approval badge count) |
| `app/views/parent/**/*.html.erb` | Modify (4 files) | Add `with-nav` to `.screen` divs that need nav clearance |

---

## Task 1: Fix Remaining Broken Turbo Stream Templates

`approve_redemption.turbo_stream.erb` and `reject_redemption.turbo_stream.erb` still use the old `ui--confetti` controller name and `bg-brand-green` / `bg-red-600` hardcoded flash HTML from before the design system refactor.

**Files:**
- Modify: `app/views/parent/approvals/approve_redemption.turbo_stream.erb`
- Modify: `app/views/parent/approvals/reject_redemption.turbo_stream.erb`

- [ ] **Step 1: Read both files to confirm current state**

```bash
cat app/views/parent/approvals/approve_redemption.turbo_stream.erb
cat app/views/parent/approvals/reject_redemption.turbo_stream.erb
```

- [ ] **Step 2: Rewrite approve_redemption.turbo_stream.erb**

Replace the entire file:

```erb
<%= turbo_stream.remove @redemption %>

<%= turbo_stream.append "body" do %>
  <div data-controller="celebration" data-celebration-auto-fire-value="true" class="hidden"></div>
<% end %>

<%= turbo_stream.update :flash do %>
  <div
    data-controller="flash"
    data-flash-dismiss-after-value="2200"
    class="pointer-events-auto flex items-center gap-2 px-5 py-3 rounded-full text-white font-extrabold text-[15px] shadow-lift animate-popIn"
    style="background-color: var(--success);"
  >
    <%= render Ui::Icon::Component.new("check", size: 18, color: "white") %>
    <span>Resgate aprovado! 🎁</span>
  </div>
<% end %>

<% if current_profile.family.redemptions.pending.count == 0 && current_profile.family.profile_tasks.awaiting_approval.count == 0 %>
  <%= turbo_stream.replace "approvals_list" do %>
    <div class="bg-white rounded-3xl p-12 text-center" style="border: var(--border-card); box-shadow: 0 4px 0 0 rgba(0,0,0,0.05);">
      <div class="text-6xl mb-6">✨</div>
      <h3 class="h-display mb-2" style="font-size: 22px;">Tudo Limpo!</h3>
      <p style="color: var(--text-muted); font-weight: 600;">Nenhuma pendência. Trabalho incrível!</p>
    </div>
  <% end %>
<% end %>

<%= turbo_stream.update "pending_approvals_kpi" do %>
  <%= current_profile.family.profile_tasks.awaiting_approval.count %>
<% end %>
```

- [ ] **Step 3: Rewrite reject_redemption.turbo_stream.erb**

Replace the entire file:

```erb
<%= turbo_stream.remove @redemption %>

<%= turbo_stream.update :flash do %>
  <div
    data-controller="flash"
    data-flash-dismiss-after-value="2200"
    class="pointer-events-auto flex items-center gap-2 px-5 py-3 rounded-full text-white font-extrabold text-[15px] shadow-lift animate-popIn"
    style="background-color: var(--danger);"
  >
    <%= render Ui::Icon::Component.new("close", size: 18, color: "white") %>
    <span>Resgate rejeitado e pontos devolvidos.</span>
  </div>
<% end %>

<% pending_tasks = current_profile.family.profile_tasks.awaiting_approval.count %>
<% pending_redemptions = Redemption.pending.joins(:profile).where(profiles: { family_id: current_profile.family_id }).count %>
<% if pending_tasks == 0 && pending_redemptions == 0 %>
  <%= turbo_stream.replace "approvals_list" do %>
    <div class="bg-white rounded-3xl p-12 text-center" style="border: var(--border-card); box-shadow: 0 4px 0 0 rgba(0,0,0,0.05);">
      <div class="text-6xl mb-6">💤</div>
      <h3 class="h-display mb-2" style="font-size: 22px;">Tudo em dia!</h3>
      <p style="color: var(--text-muted); font-weight: 600;">Não há missões ou resgates aguardando aprovação.</p>
    </div>
  <% end %>
<% end %>

<%= turbo_stream.update "pending_approvals_kpi" do %>
  <%= current_profile.family.profile_tasks.awaiting_approval.count %>
<% end %>
```

- [ ] **Step 4: Verify no remaining `ui--confetti` or `bg-brand-green` references**

```bash
grep -rn "ui--confetti\|bg-brand-green\|bg-red-600\|border-brand-green\|pending_approvals_count" app/views/
```

Expected: no output.

- [ ] **Step 5: Commit**

```bash
git add app/views/parent/approvals/approve_redemption.turbo_stream.erb \
        app/views/parent/approvals/reject_redemption.turbo_stream.erb
git commit -m "fix: repair approve/reject redemption turbo stream templates

- Fix ui--confetti → celebration controller
- Replace bg-brand-green flash with CSS variable toast
- Add pending_approvals_kpi live counter update
- Use consistent design system empty state markup"
```

---

## Task 2: Self-Host Phosphor Icons and Google Fonts

All icons (`Ui::Icon::Component`) and both fonts (Nunito, Fredoka) load from external CDNs. If unpkg or Google Fonts is slow/blocked, the entire UI breaks — icons disappear and Lumi is invisible.

**Files:**
- Modify: `app/views/shared/_head.html.erb`
- Modify: `app/assets/stylesheets/tailwind/fonts.css`
- Create: `app/assets/fonts/` (font files downloaded in steps below)

- [ ] **Step 1: Install Phosphor icons via npm**

```bash
npm install @phosphor-icons/web@2.1.1
```

Expected: `node_modules/@phosphor-icons/web/` directory created. Verify:

```bash
ls node_modules/@phosphor-icons/web/src/
```

Expected output includes: `regular/`, `bold/`, `fill/`, `duotone/`.

- [ ] **Step 2: Copy Phosphor assets to public directory**

```bash
mkdir -p public/fonts/phosphor
cp -r node_modules/@phosphor-icons/web/src/regular public/fonts/phosphor/
cp -r node_modules/@phosphor-icons/web/src/bold public/fonts/phosphor/
cp -r node_modules/@phosphor-icons/web/src/fill public/fonts/phosphor/
cp -r node_modules/@phosphor-icons/web/src/duotone public/fonts/phosphor/
```

Verify:

```bash
ls public/fonts/phosphor/
```

Expected: `regular/  bold/  fill/  duotone/`

- [ ] **Step 3: Update Phosphor CSS to reference local font paths**

Each Phosphor CSS file (e.g. `public/fonts/phosphor/fill/style.css`) references font files with relative paths. Since we copied the full directory structure, relative paths are already correct. Verify one:

```bash
head -20 public/fonts/phosphor/fill/style.css
```

Expected: `src: url('./PhosphorIcons-Fill.ttf')` or similar relative path — already pointing to files in the same directory.

- [ ] **Step 4: Download Google Fonts as local files**

Use the `google-webfonts-helper` approach — download woff2 files for both fonts. Run from project root:

```bash
mkdir -p app/assets/fonts

# Nunito (weights used: 400, 600, 700, 800)
curl -o app/assets/fonts/nunito-400.woff2 \
  "https://fonts.gstatic.com/s/nunito/v26/XRXI3I6Li01BKofiOc5wtlZ2di8HDOUhdTQ3j6zbXWjge0v.woff2"
curl -o app/assets/fonts/nunito-600.woff2 \
  "https://fonts.gstatic.com/s/nunito/v26/XRXI3I6Li01BKofiOc5wtlZ2di8HDLshhdTQ3j6zbXWjge0v.woff2"
curl -o app/assets/fonts/nunito-700.woff2 \
  "https://fonts.gstatic.com/s/nunito/v26/XRXI3I6Li01BKofiOc5wtlZ2di8HDIUihdTQ3j6zbXWjge0v.woff2"
curl -o app/assets/fonts/nunito-800.woff2 \
  "https://fonts.gstatic.com/s/nunito/v26/XRXI3I6Li01BKofiOc5wtlZ2di8HDJkhhdTQ3j6zbXWjge0v.woff2"

# Fredoka (weights used: 400, 500, 600, 700)
curl -o app/assets/fonts/fredoka-400.woff2 \
  "https://fonts.gstatic.com/s/fredoka/v14/X7nP4b87HvSqjb_WIi2yDCRwoQ.woff2"
curl -o app/assets/fonts/fredoka-700.woff2 \
  "https://fonts.gstatic.com/s/fredoka/v14/X7nP4b87HvSqjb_WIi2yDCRwoQ.woff2"
```

> **Note:** If the curl URLs above return 403, open `https://fonts.googleapis.com/css2?family=Fredoka:wght@400;700&family=Nunito:wght@400;600;700;800&display=swap` in a browser with a `User-Agent: Mozilla/5.0` header to get the actual woff2 URLs. A reliable alternative: `npm install -g google-webfonts-helper` or use the web tool at `gwfh.mranftl.com`.

Verify files exist and are non-empty:

```bash
ls -lh app/assets/fonts/
```

Expected: 6+ `.woff2` files, each > 10KB.

- [ ] **Step 5: Replace fonts.css with local @font-face declarations**

Read the current `app/assets/stylesheets/tailwind/fonts.css` first, then replace its content with:

```css
@font-face {
  font-family: 'Nunito';
  src: url('/assets/fonts/nunito-400.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}
@font-face {
  font-family: 'Nunito';
  src: url('/assets/fonts/nunito-600.woff2') format('woff2');
  font-weight: 600;
  font-style: normal;
  font-display: swap;
}
@font-face {
  font-family: 'Nunito';
  src: url('/assets/fonts/nunito-700.woff2') format('woff2');
  font-weight: 700;
  font-style: normal;
  font-display: swap;
}
@font-face {
  font-family: 'Nunito';
  src: url('/assets/fonts/nunito-800.woff2') format('woff2');
  font-weight: 800;
  font-style: normal;
  font-display: swap;
}
@font-face {
  font-family: 'Fredoka';
  src: url('/assets/fonts/fredoka-400.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}
@font-face {
  font-family: 'Fredoka';
  src: url('/assets/fonts/fredoka-700.woff2') format('woff2');
  font-weight: 700;
  font-style: normal;
  font-display: swap;
}
```

- [ ] **Step 6: Update _head.html.erb to use local Phosphor and remove Google Fonts CDN**

Read `app/views/shared/_head.html.erb`, then replace lines 7–14 (the preconnect + CDN links):

```erb
<link rel="stylesheet" href="/fonts/phosphor/regular/style.css">
<link rel="stylesheet" href="/fonts/phosphor/bold/style.css">
<link rel="stylesheet" href="/fonts/phosphor/fill/style.css">
<link rel="stylesheet" href="/fonts/phosphor/duotone/style.css">
```

Remove the `<link rel="preconnect" href="https://fonts.googleapis.com">`, `<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>`, and `<link href="https://fonts.googleapis.com/...">` lines entirely.

- [ ] **Step 7: Verify in browser (start dev server)**

```bash
bin/dev
```

Open `http://localhost:3000`. In DevTools Network tab, confirm:
- No requests to `fonts.googleapis.com`, `fonts.gstatic.com`, or `unpkg.com`
- Icons render correctly on session screen and dashboard
- Lumi mascot (star + face icon) visible without CDN

- [ ] **Step 8: Commit**

```bash
git add app/assets/fonts/ \
        public/fonts/phosphor/ \
        app/assets/stylesheets/tailwind/fonts.css \
        app/views/shared/_head.html.erb
git commit -m "feat: self-host Phosphor icons and Google Fonts

Removes 6 CDN dependencies (unpkg × 4, fonts.googleapis.com × 2).
Icons and fonts now served from /public/fonts/phosphor/ and
/assets/fonts/ respectively — app fully functional offline."
```

---

## Task 3: Fix Font System Split

`tailwind/theme.css` sets `--font-sans: 'Fredoka'` which means Tailwind utility `font-sans` renders Fredoka. But `design_system.css` sets `--font-body: 'Nunito'` and all design system classes use Nunito. Result: Tailwind utilities and design system classes render different fonts in adjacent elements.

**Files:**
- Modify: `app/assets/stylesheets/tailwind/theme.css`

- [ ] **Step 1: Read theme.css to confirm current font-sans value**

```bash
head -5 app/assets/stylesheets/tailwind/theme.css
```

Expected: `--font-sans: 'Fredoka', ui-sans-serif, system-ui, ...`

- [ ] **Step 2: Update font-sans to Nunito**

In `app/assets/stylesheets/tailwind/theme.css`, change line 2:

```css
/* Before */
--font-sans: 'Fredoka', ui-sans-serif, system-ui, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol';

/* After */
--font-sans: 'Nunito', ui-sans-serif, system-ui, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol';
```

Fredoka is still available via `--font-display` in design_system.css for explicit heading use. This change only affects elements that use `font-sans` Tailwind utility (e.g. flash toasts with `font-extrabold`).

- [ ] **Step 3: Verify no unintended font changes**

```bash
bin/dev
```

Open the session screen (`/`), dashboard, and approvals page. Check that flash toasts, form labels, and table text all render in Nunito (round, warm). Fredoka (geometric) should only appear on explicit display headings.

- [ ] **Step 4: Commit**

```bash
git add app/assets/stylesheets/tailwind/theme.css
git commit -m "fix: align Tailwind font-sans to Nunito for typographic consistency

Fredoka was set as font-sans, making Tailwind utilities render different
font from design system classes. Now both use Nunito as body font.
Fredoka still available via --font-display for display headings."
```

---

## Task 4: Add Persistent Parent Bottom Navigation

The parent layout has no persistent navigation. Every sub-page requires tapping the TopBar back arrow to return to the dashboard hub, then tapping a tile to go elsewhere. A bottom nav with badge count on Aprovações reduces the most common parent workflow from 4+ taps to 1.

**Files:**
- Create: `app/views/shared/_parent_nav.html.erb`
- Modify: `app/views/layouts/parent.html.erb`
- Modify: `app/views/parent/dashboard/index.html.erb`
- Modify: `app/views/parent/approvals/index.html.erb`
- Modify: `app/views/parent/global_tasks/index.html.erb`
- Modify: `app/views/parent/rewards/index.html.erb`

- [ ] **Step 1: Create the parent nav partial**

Create `app/views/shared/_parent_nav.html.erb`:

```erb
<%
  pending_count = current_profile.family.profile_tasks.awaiting_approval.count +
                  Redemption.pending.joins(:profile).where(profiles: { family_id: current_profile.family_id }).count

  nav_item = ->(icon_name, path, title) {
    active = current_page?(path)
    link_to path, class: "nav-item #{active ? 'active' : ''}", title: title do
      render Ui::Icon::Component.new(icon_name, size: 26)
    end
  }
%>
<div class="bottom-nav">
  <%= nav_item.call("house", parent_root_path, "Início") %>

  <% approvals_path = parent_approvals_path %>
  <% approvals_active = current_page?(approvals_path) %>
  <%= link_to approvals_path, class: "nav-item #{approvals_active ? 'active' : ''} relative", title: "Aprovações" do %>
    <%= render Ui::Icon::Component.new("clock", size: 26) %>
    <% if pending_count > 0 %>
      <span id="nav_approvals_badge" style="
        position: absolute;
        top: 6px; right: 6px;
        min-width: 16px; height: 16px;
        background: var(--c-peach);
        color: white;
        font-size: 10px;
        font-weight: 800;
        border-radius: var(--r-full);
        display: flex; align-items: center; justify-content: center;
        padding: 0 4px;
      "><%= pending_count %></span>
    <% end %>
  <% end %>

  <%= nav_item.call("list-checks", parent_global_tasks_path, "Missões") %>
  <%= nav_item.call("bag", parent_rewards_path, "Loja") %>
</div>
```

- [ ] **Step 2: Update parent layout to include nav + viewport padding**

Read `app/views/layouts/parent.html.erb`, then modify it:

```erb
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for(:title) || "LittleStars | Painel Responsável" %></title>
    <%= render "shared/head" %>
    <%= yield :head %>
  </head>

  <body class="app-shell" data-palette="sky">
    <%= turbo_stream_from current_profile.family, "approvals" %>
    <div class="viewport pb-24">
      <%= render Ui::Flash::Component.new %>
      <%= yield %>
    </div>
    <%= render "shared/parent_nav" %>
  </body>
</html>
```

- [ ] **Step 3: Add `with-nav` to parent views that need bottom clearance**

Read each file first, then add `with-nav` to the `.screen` div's class string:

**`app/views/parent/dashboard/index.html.erb`** — change line 1:
```erb
<!-- Before -->
<div class="screen screen-enter">

<!-- After -->
<div class="screen screen-enter with-nav">
```

**`app/views/parent/approvals/index.html.erb`** — change line 1:
```erb
<!-- Before -->
<div class="screen screen-enter-right">

<!-- After -->
<div class="screen screen-enter-right with-nav">
```

**`app/views/parent/global_tasks/index.html.erb`** — read file first, find the outer `.screen` div, add `with-nav`.

**`app/views/parent/rewards/index.html.erb`** — read file first, find the outer `.screen` div, add `with-nav`.

- [ ] **Step 4: Add `data-turbo-submits-with` to approve/reject buttons to prevent double-submit**

Read `app/views/parent/approvals/index.html.erb`. For each of the 4 `button_to` elements (reject task, approve task, reject redemption, approve redemption), add `data: { turbo_submits_with: "..." }`:

```erb
<%= button_to approve_parent_approval_path(task), method: :patch,
    class: "btn btn-success btn-icon",
    aria: { label: "Aprovar missão de #{task.title}" },
    data: { turbo_frame: "approvals_list", turbo_submits_with: render(Ui::Icon::Component.new("spinner", size: 22, color: "white")) } do %>
  <%= render Ui::Icon::Component.new("check", size: 22, color: "white") %>
<% end %>
```

Apply the same pattern to the reject and both redemption buttons (use appropriate icon and aria label for each).

> **Note:** If `Ui::Icon::Component.new("spinner", ...)` does not render a visible spinner, use `"..."` as the `turbo_submits_with` string fallback.

- [ ] **Step 5: Verify in browser**

```bash
bin/dev
```

Log in as a parent profile. Verify:
1. Bottom nav renders on dashboard, approvals, global_tasks, and rewards pages
2. Orange badge count on "Aprovações" nav item matches pending count
3. Active nav item highlighted in `var(--primary)` blue
4. Tapping approve/reject disables the button immediately (no double-submit)
5. Nav does not overlap content on iPhone-sized viewport (375px wide)

- [ ] **Step 6: Commit**

```bash
git add app/views/shared/_parent_nav.html.erb \
        app/views/layouts/parent.html.erb \
        app/views/parent/dashboard/index.html.erb \
        app/views/parent/approvals/index.html.erb \
        app/views/parent/global_tasks/index.html.erb \
        app/views/parent/rewards/index.html.erb
git commit -m "feat: add persistent bottom navigation for parent interface

Parent interface previously had no persistent nav — every sub-page
required tapping back then re-selecting. Bottom nav adds 4-item nav
(Início, Aprovações, Missões, Loja) with live badge count on pending
approvals. Also adds turbo_submits_with to prevent double-submission."
```

---

## Self-Review

**Spec coverage check:**

| Opportunity | Covered by |
|------------|-----------|
| Broken turbo streams (approve/reject redemption) | Task 1 |
| CDN dependency on Phosphor + Google Fonts | Task 2 |
| Font system split (Fredoka vs Nunito) | Task 3 |
| Parent persistent navigation | Task 4 |
| `pending_approvals_kpi` dead counter | Task 1 + Task 4 (badge) |
| Double-submit on approve/reject | Task 4 Step 4 |

**Placeholder scan:** No TBDs found. Task 2 Step 4 includes a Note about curl URL fallback — this is a genuine environmental dependency, not a placeholder.

**Type consistency:** `pending_count`, `nav_item`, route helpers, component names consistent across all tasks.

**Not covered in this plan (separate work):**
- Full inline `style=` → named class extraction (214 occurrences, needs its own milestone)
- Dark mode coverage in design_system.css
- Lumi empty states for kid interface

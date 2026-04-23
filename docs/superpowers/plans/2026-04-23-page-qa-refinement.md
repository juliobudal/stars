# Page-by-Page QA Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Compare each app screen against Stars/ design reference, fix all visual gaps, and extract repeated UI patterns into reusable partials/components.

**Architecture:** Rails 8 ERB views + Tailwind 4 + ViewComponent. Fixes go directly into ERB partials and CSS; new reusable pieces become ViewComponents or shared partials under `app/views/shared/`. No new routes or controllers needed.

**Tech Stack:** Rails 8 · Tailwind 4 · ViewComponent 4.7 · Playwright MCP (visual QA) · Stimulus

---

## Screen → File Map

| Stars ref URL | App URL | Primary file(s) |
|---|---|---|
| `#a-picker` | `/` (profile picker) | `app/views/sessions/new.html.erb` |
| `#a-dash` | `/kid/dashboard` | `app/views/kid/dashboard/index.html.erb` |
| `#a-shop` | `/kid/rewards` | `app/views/kid/rewards/index.html.erb` |
| `#a-history` | `/kid/wallet` | `app/views/kid/wallet/index.html.erb` |
| `#pa-dashboard` | `/parent/dashboard` | `app/views/parent/dashboard/index.html.erb` |
| `#pa-approvals` | `/parent/approvals` | `app/views/parent/approvals/index.html.erb` |
| `#pa-kids` | `/parent/profiles` | `app/views/parent/profiles/index.html.erb` |
| `#pa-missions` | `/parent/global_tasks` | `app/views/parent/global_tasks/index.html.erb` |
| `#pa-rewards` | `/parent/rewards` | `app/views/parent/rewards/index.html.erb` |
| `#pa-settings` | `/parent/settings` | `app/views/parent/settings/index.html.erb` |

## Reference URLs

- Stars hub: `http://localhost:9999/index.html`
- Stars screen deep-link: `http://localhost:9999/LittleStars.html?v=4#<screen-id>`
- App: `http://localhost:10301` (Docker `guardian-web-1`)
- Login: navigate to root → pick a profile (session must be active before visiting kid/parent routes)

## Shared files (CSS tokens, layout)

- `app/assets/stylesheets/tailwind/theme.css` — design tokens (colors, radii, spacing)
- `app/assets/stylesheets/design_system.css` — component-level rules
- `app/assets/stylesheets/brand.css` — brand-specific overrides
- `app/views/shared/_kid_nav.html.erb` — kid bottom nav
- `app/views/shared/_parent_nav.html.erb` — parent sidebar nav
- `app/views/shared/_bg_shapes.html.erb` — decorative blob shapes
- `app/views/shared/_star_mascot.html.erb` — star mascot SVG
- `app/views/layouts/kid.html.erb` — kid layout wrapper
- `app/views/layouts/parent.html.erb` — parent layout wrapper

---

## Task 1: Profile Picker (`#a-picker`)

**Files:**
- Review: `app/views/sessions/new.html.erb`
- Shared: `app/views/shared/_bg_shapes.html.erb`

- [ ] **Step 1: Screenshot Stars ref**

  Open `http://localhost:9999/LittleStars.html?v=4#a-picker` via Playwright. Take screenshot.

- [ ] **Step 2: Screenshot app**

  Open `http://localhost:10301/` via Playwright. Take screenshot.

- [ ] **Step 3: Document gaps**

  Compare both screenshots side-by-side. Check:
  - Decorative blob shapes present and positioned correctly
  - Star mascot centered above title
  - Title font (Fraunces italic), subtitle font (Nunito)
  - Profile card layout: avatar circle size, name font-weight, role badge
  - "Add profile" ghost card style
  - Background color (`#f8f5f2` warm off-white)
  - Card shadow and border-radius
  - Spacing between cards

- [ ] **Step 4: Fix gaps**

  Edit the identified files. Apply Tailwind utilities or inline CSS where needed. Example pattern for card fix:
  ```erb
  <%# app/views/sessions/new.html.erb %>
  <div class="profile-card rounded-2xl bg-white shadow-soft p-5 flex flex-col items-center gap-3">
  ```

  For blob shapes, ensure `<%= render 'shared/bg_shapes' %>` is present inside the layout or view with correct z-index (behind content).

- [ ] **Step 5: Verify in browser**

  Navigate to `http://localhost:10301/` in Playwright. Take screenshot. Compare. Confirm gaps closed.

- [ ] **Step 6: Commit**

  ```bash
  git add app/views/sessions/ app/views/shared/ app/assets/stylesheets/
  git commit -m "style: picker — match Stars ref (blobs, card layout, mascot)"
  ```

---

## Task 2: Kid Dashboard (`#a-dash`)

**Files:**
- Review: `app/views/kid/dashboard/index.html.erb`
- Partials: `app/views/kid/dashboard/_profile_task.html.erb`, `_awaiting_task.html.erb`, `_completed_task.html.erb`
- Shared: `app/views/shared/_star_mascot.html.erb`, `app/views/shared/_kid_nav.html.erb`

- [ ] **Step 1: Screenshot Stars ref**

  Open `http://localhost:9999/LittleStars.html?v=4#a-dash`.

- [ ] **Step 2: Screenshot app**

  Login via profile picker, then navigate to `/kid/dashboard`.

- [ ] **Step 3: Document gaps**

  Check:
  - Header: avatar with ring, greeting text ("Oi, [Name]!"), streak badge, notification bell, star button
  - Balance tile: star icon, balance number (large, Baloo 2 font), "estrelinhas guardadas" label
  - "1 aguardando" approval badge chip
  - Progress bar: "PROGRESSO DE HOJE" label, "X de Y" counter, orange fill bar
  - Mission list items: category icon circle (colored by category), title, badges (categoria · frequência · points)
  - Completed task: green circle with check, title struck-through or muted
  - "+30 ao concluir tudo" bonus row at bottom of list
  - Kid bottom nav: 3 tabs (Jornada/active, Estrelinhas/shop, Diário)
  - Bottom nav active tab styling

- [ ] **Step 4: Fix gaps**

  Edit `app/views/kid/dashboard/index.html.erb` and partials. Example for mission item badge layout:
  ```erb
  <%# _profile_task.html.erb %>
  <div class="flex items-center gap-1.5 text-xs text-[--color-muted]">
    <span><%= profile_task.category %></span>
    <span>·</span>
    <span><%= profile_task.frequency %></span>
    <span>·</span>
    <span class="chip chip-sm chip-star">⭐ <%= profile_task.points %></span>
  </div>
  ```

- [ ] **Step 5: Verify**

  Navigate to `/kid/dashboard`. Screenshot. Compare.

- [ ] **Step 6: Commit**

  ```bash
  git add app/views/kid/dashboard/
  git commit -m "style: kid dashboard — match Stars ref (balance tile, mission items, nav)"
  ```

---

## Task 3: Kid Shop / Rewards (`#a-shop`)

**Files:**
- Review: `app/views/kid/rewards/index.html.erb`
- Component: `app/components/ui/mission_card/component.rb` (reward card analog)

- [ ] **Step 1: Screenshot Stars ref**

  Open `http://localhost:9999/LittleStars.html?v=4#a-shop`.

- [ ] **Step 2: Screenshot app**

  Navigate to `/kid/rewards`.

- [ ] **Step 3: Document gaps**

  Check:
  - Page header: balance display in top-right with star icon
  - Section title "Lojinha" with subtitle
  - Reward card layout: emoji/image area, reward name, point cost chip, "Trocar" button
  - Card grid columns and gap
  - Empty state design (if no rewards)
  - "Insufficient balance" disabled state on button
  - Bottom nav position and active tab

- [ ] **Step 4: Fix gaps**

  Edit `app/views/kid/rewards/index.html.erb`. Ensure reward card matches:
  ```erb
  <div class="reward-card rounded-2xl bg-white shadow-soft overflow-hidden">
    <div class="reward-card__image h-28 bg-[--color-surface-2] flex items-center justify-center text-4xl">
      <%= reward.emoji %>
    </div>
    <div class="p-4 flex flex-col gap-2">
      <p class="font-bold text-sm text-[--color-text]"><%= reward.title %></p>
      <div class="flex items-center justify-between">
        <span class="chip chip-sm chip-star">⭐ <%= reward.points_cost %></span>
        <%= button_to "Trocar", kid_reward_redeem_path(reward), class: "btn btn-sm btn-primary" %>
      </div>
    </div>
  </div>
  ```

- [ ] **Step 5: Verify**

  Navigate to `/kid/rewards`. Screenshot. Compare.

- [ ] **Step 6: Commit**

  ```bash
  git add app/views/kid/rewards/
  git commit -m "style: kid shop — match Stars ref (reward card layout, balance header)"
  ```

---

## Task 4: Kid Wallet / History (`#a-history`)

**Files:**
- Review: `app/views/kid/wallet/index.html.erb`, `app/views/kid/wallet/_day_groups.html.erb`

- [ ] **Step 1: Screenshot Stars ref**

  Open `http://localhost:9999/LittleStars.html?v=4#a-history`.

- [ ] **Step 2: Screenshot app**

  Navigate to `/kid/wallet`.

- [ ] **Step 3: Document gaps**

  Check:
  - Balance hero section: large number, "Meu cofrinho" label, star icon
  - Date group headers: styled date separators
  - Log item layout: icon left, title + subtitle, +/- points right (green earn, red redeem)
  - Empty state: illustration/mascot + message
  - Bottom nav

- [ ] **Step 4: Fix gaps**

  Edit `app/views/kid/wallet/index.html.erb` and `_day_groups.html.erb`.

- [ ] **Step 5: Verify**

  Navigate to `/kid/wallet`. Screenshot. Compare.

- [ ] **Step 6: Commit**

  ```bash
  git add app/views/kid/wallet/
  git commit -m "style: kid wallet — match Stars ref (balance hero, log items, empty state)"
  ```

---

## Task 5: Parent Dashboard (`#pa-dashboard`)

**Files:**
- Review: `app/views/parent/dashboard/index.html.erb`
- Shared: `app/views/shared/_parent_nav.html.erb`
- Layout: `app/views/layouts/parent.html.erb`

- [ ] **Step 1: Screenshot Stars ref**

  Open `http://localhost:9999/LittleStars.html?v=4#pa-dashboard`.

- [ ] **Step 2: Screenshot app**

  Login as parent profile, navigate to `/parent/dashboard`.

- [ ] **Step 3: Document gaps**

  Check:
  - Sidebar: logo + family name + subtitle, nav items with icons, active state, logout/switch at bottom
  - Dashboard grid: pending approvals count card, kids summary cards
  - Kid summary card: avatar, name, balance, pending count, "Ver jornada" link
  - Approvals preview list: task title, kid name, approve/reject buttons
  - Section headings style

- [ ] **Step 4: Fix gaps**

  Edit `app/views/parent/dashboard/index.html.erb`.

- [ ] **Step 5: Verify**

  Navigate to `/parent/dashboard`. Screenshot. Compare.

- [ ] **Step 6: Commit**

  ```bash
  git add app/views/parent/dashboard/
  git commit -m "style: parent dashboard — match Stars ref (grid layout, kid cards)"
  ```

---

## Task 6: Parent Approvals (`#pa-approvals`)

**Files:**
- Review: `app/views/parent/approvals/index.html.erb`
- Partials: `app/views/parent/approvals/_profile_task.html.erb`, `_redemption.html.erb`

- [ ] **Step 1: Screenshot Stars ref**

  Open `http://localhost:9999/LittleStars.html?v=4#pa-approvals`.

- [ ] **Step 2: Screenshot app**

  Navigate to `/parent/approvals`.

- [ ] **Step 3: Document gaps**

  Check:
  - Empty state design when queue is empty
  - Approval item layout: kid avatar, task title, category badge, points chip
  - Approve (green) / Reject (red/ghost) button pair styling
  - Redemption item vs task item visual distinction
  - Section tabs or filters (if any)

- [ ] **Step 4: Fix gaps**

  Edit `app/views/parent/approvals/index.html.erb` and partials.

- [ ] **Step 5: Verify**

  Navigate to `/parent/approvals`. Screenshot. Compare.

- [ ] **Step 6: Commit**

  ```bash
  git add app/views/parent/approvals/
  git commit -m "style: parent approvals — match Stars ref (item layout, action buttons)"
  ```

---

## Task 7: Parent Kids (`#pa-kids`)

**Files:**
- Review: `app/views/parent/profiles/index.html.erb`
- Form: `app/views/parent/profiles/_form.html.erb`

- [ ] **Step 1: Screenshot Stars ref**

  Open `http://localhost:9999/LittleStars.html?v=4#pa-kids`.

- [ ] **Step 2: Screenshot app**

  Navigate to `/parent/profiles`.

- [ ] **Step 3: Document gaps**

  Check:
  - Page header: "Filhos" title, subtitle, "Adicionar filho" button (purple)
  - Kid card: avatar circle (color-coded), name (Fraunces italic), age + level badges
  - Card stats row: balance (⭐ N), missions count
  - Card action links: "Ver jornada", "Remover"
  - Add child ghost card (+ icon, dashed border)
  - Card grid columns, gap, border-radius

- [ ] **Step 4: Fix gaps**

  Edit `app/views/parent/profiles/index.html.erb`.

- [ ] **Step 5: Verify**

  Navigate to `/parent/profiles`. Screenshot. Compare.

- [ ] **Step 6: Commit**

  ```bash
  git add app/views/parent/profiles/
  git commit -m "style: parent kids — match Stars ref (profile cards, add card)"
  ```

---

## Task 8: Parent Missions (`#pa-missions`)

**Files:**
- Review: `app/views/parent/global_tasks/index.html.erb`
- Form: `app/views/parent/global_tasks/_form.html.erb`, `new.html.erb`, `edit.html.erb`

- [ ] **Step 1: Screenshot Stars ref**

  Open `http://localhost:9999/LittleStars.html?v=4#pa-missions`.

- [ ] **Step 2: Screenshot app**

  Navigate to `/parent/global_tasks`.

- [ ] **Step 3: Document gaps**

  Check:
  - Page header: title, "Nova missão" button
  - Mission list item: category icon, title, frequency badge, points chip, edit/delete actions
  - Category color coding (each category has distinct icon bg color)
  - Frequency badge styling (chip chip-sm)
  - Empty state

- [ ] **Step 4: Fix gaps**

  Edit `app/views/parent/global_tasks/index.html.erb`.

- [ ] **Step 5: Verify**

  Navigate to `/parent/global_tasks`. Screenshot. Compare.

- [ ] **Step 6: Commit**

  ```bash
  git add app/views/parent/global_tasks/
  git commit -m "style: parent missions — match Stars ref (task list, category colors)"
  ```

---

## Task 9: Parent Rewards (`#pa-rewards`)

**Files:**
- Review: `app/views/parent/rewards/index.html.erb`
- Form: `app/views/parent/rewards/_form.html.erb`, `new.html.erb`

- [ ] **Step 1: Screenshot Stars ref**

  Open `http://localhost:9999/LittleStars.html?v=4#pa-rewards`.

- [ ] **Step 2: Screenshot app**

  Navigate to `/parent/rewards`.

- [ ] **Step 3: Document gaps**

  Check:
  - Reward card layout: emoji area, title, cost, availability toggle
  - "Novo prêmio" button style
  - Empty state
  - Pending redemptions section (if shown on this screen)

- [ ] **Step 4: Fix gaps**

  Edit `app/views/parent/rewards/index.html.erb`.

- [ ] **Step 5: Verify**

  Navigate to `/parent/rewards`. Screenshot. Compare.

- [ ] **Step 6: Commit**

  ```bash
  git add app/views/parent/rewards/
  git commit -m "style: parent rewards — match Stars ref (reward cards, admin layout)"
  ```

---

## Task 10: Parent Settings (`#pa-settings`)

**Files:**
- Review: `app/views/parent/settings/index.html.erb`

- [ ] **Step 1: Screenshot Stars ref**

  Open `http://localhost:9999/LittleStars.html?v=4#pa-settings`.

- [ ] **Step 2: Screenshot app**

  Navigate to `/parent/settings`.

- [ ] **Step 3: Document gaps**

  Check:
  - Settings sections: Family, Notifications (if any)
  - Family name field styling
  - Section card container style
  - Save button placement and style

- [ ] **Step 4: Fix gaps**

  Edit `app/views/parent/settings/index.html.erb`.

- [ ] **Step 5: Verify**

  Navigate to `/parent/settings`. Screenshot. Compare.

- [ ] **Step 6: Commit**

  ```bash
  git add app/views/parent/settings/
  git commit -m "style: parent settings — match Stars ref (form sections, card layout)"
  ```

---

## Task 11: Component Extraction

After Tasks 1–10, identify patterns that appear in 3+ screens and extract them.

**Files to create:**
- `app/views/shared/_balance_tile.html.erb` — kid balance hero (dashboard + wallet)
- `app/views/shared/_kid_profile_card.html.erb` — kid card used in picker + parent kids grid
- `app/components/ui/stat_chip/component.rb` — inline `⭐ N` chip (kid and parent screens)
- `app/views/shared/_approval_item.html.erb` — task approval row (dashboard preview + approvals list)

**Files to modify:**
- `app/views/kid/dashboard/index.html.erb` — replace balance block with partial
- `app/views/kid/wallet/index.html.erb` — replace balance block with partial
- `app/views/sessions/new.html.erb` — replace profile card with partial
- `app/views/parent/profiles/index.html.erb` — replace kid card with partial
- `app/views/parent/dashboard/index.html.erb` — replace approvals preview with partial
- `app/views/parent/approvals/index.html.erb` — replace approval items with partial

- [ ] **Step 1: Extract balance tile partial**

  Create `app/views/shared/_balance_tile.html.erb`:
  ```erb
  <%# locals: (balance:, label: "estrelinhas guardadas", pending_count: 0) %>
  <div class="balance-tile rounded-2xl bg-white shadow-soft p-5 flex flex-col gap-2">
    <p class="text-xs font-bold uppercase tracking-widest text-[--color-muted]">Meu cofrinho</p>
    <div class="flex items-center gap-2">
      <span class="text-3xl">⭐</span>
      <span class="text-4xl font-black font-display text-[--color-text]"><%= balance %></span>
      <span class="text-sm text-[--color-muted]"><%= label %></span>
    </div>
    <% if pending_count > 0 %>
      <span class="chip chip-sm chip-warning self-start"><%= pending_count %> aguardando</span>
    <% end %>
  </div>
  ```

  Replace in `kid/dashboard/index.html.erb` and `kid/wallet/index.html.erb`:
  ```erb
  <%= render 'shared/balance_tile', balance: @profile.points, pending_count: @pending_count %>
  ```

- [ ] **Step 2: Extract kid profile card partial**

  Create `app/views/shared/_kid_profile_card.html.erb`:
  ```erb
  <%# locals: (profile:, show_stats: false, link_to_journey: false) %>
  <div class="kid-profile-card rounded-2xl bg-white shadow-soft p-5 flex flex-col items-center gap-3 cursor-pointer">
    <%= render Ui::SmileyAvatar::Component.new(color: profile.color, expression: profile.expression, size: :lg) %>
    <div class="flex flex-col items-center gap-1">
      <p class="font-display italic font-bold text-lg text-[--color-text]"><%= profile.name %></p>
      <% if profile.parent? %>
        <span class="chip chip-sm">RESPONSÁVEL</span>
      <% else %>
        <div class="flex items-center gap-2 text-xs text-[--color-muted]">
          <span>⭐ <%= profile.points %></span>
          <span>🔥 <%= profile.streak_days %></span>
        </div>
      <% end %>
    </div>
    <% if show_stats %>
      <div class="w-full border-t border-[--color-border] pt-3 flex justify-between text-sm">
        <span>Saldo: ⭐ <%= profile.points %></span>
        <span>Missões: <%= profile.profile_tasks.count %></span>
      </div>
    <% end %>
  </div>
  ```

  Replace in `sessions/new.html.erb`:
  ```erb
  <%= render 'shared/kid_profile_card', profile: profile %>
  ```

  Replace in `parent/profiles/index.html.erb`:
  ```erb
  <%= render 'shared/kid_profile_card', profile: profile, show_stats: true, link_to_journey: true %>
  ```

- [ ] **Step 3: Run rubocop on modified files**

  ```bash
  docker exec guardian-web-1 bin/rubocop app/views/shared/ app/components/ui/stat_chip/
  ```
  Expected: no new offenses.

- [ ] **Step 4: Verify extraction in browser**

  Navigate to `/`, `/kid/dashboard`, `/kid/wallet`, `/parent/profiles`. Take screenshot each. Confirm visual unchanged.

- [ ] **Step 5: Commit**

  ```bash
  git add app/views/shared/ app/components/ui/stat_chip/ app/views/kid/ app/views/sessions/ app/views/parent/profiles/ app/views/parent/dashboard/
  git commit -m "refactor: extract shared balance tile and kid profile card partials"
  ```

---

## Task 12: Cross-screen CSS cleanup

After all fixes, do a final pass on shared CSS.

**Files:**
- `app/assets/stylesheets/design_system.css`
- `app/assets/stylesheets/tailwind/theme.css`

- [ ] **Step 1: Audit unused/duplicate rules**

  Check for any one-off inline styles added during Tasks 1–10 that can be promoted to design_system.css tokens/classes.

- [ ] **Step 2: Promote recurring patterns**

  If a pattern (e.g. `rounded-2xl bg-white shadow-soft p-5`) appears 4+ times with the same meaning, add a named CSS class:
  ```css
  /* design_system.css */
  .card { @apply rounded-2xl bg-white shadow-[0_2px_12px_rgba(0,0,0,.06)] p-5; }
  ```

- [ ] **Step 3: Verify no visual regressions**

  Navigate through all 10 screens in Playwright. Take screenshots. Confirm no regressions.

- [ ] **Step 4: Run full CI**

  ```bash
  docker exec guardian-web-1 bin/ci
  ```
  Expected: all green.

- [ ] **Step 5: Commit**

  ```bash
  git add app/assets/stylesheets/
  git commit -m "style: promote recurring card/chip patterns to design_system.css"
  ```

---

## Execution Order

Tasks 1–10 are independent per screen — do them sequentially. Tasks 11–12 depend on 1–10 being complete.

## Key constraints

- App is at `localhost:10301` inside Docker (`guardian-web-1`); run Rails commands via `docker exec guardian-web-1 <cmd>`
- Vite auto-reloads CSS/JS; no rebuild needed for stylesheet changes in dev
- Sessions expire on direct URL navigation — always navigate through profile picker first
- `Ui::SmileyAvatar::Component` and `Ui::MissionCard::Component` already exist — reuse them
- `app/views/shared/_bg_shapes.html.erb` and `_star_mascot.html.erb` already exist — render them, don't recreate
- After extracting components in Task 11, run `bin/rubocop` to catch any `.html.erb` strict-locals issues

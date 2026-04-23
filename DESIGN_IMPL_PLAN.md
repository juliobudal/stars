# LittleStars — Design Implementation Plan
**Source:** `Stars/LittleStars.html` → Direction A "Soft Candy"  
**Status:** Planning complete. Ready to implement.

---

## Design Reference Files
All design source lives in `Stars/src/`:
- `tokens.jsx` — all color tokens + sample data
- `shared.jsx` — StarMascot SVG, SmileyAvatar SVG, StarBadge, TaskIcon, NavIcon, RewardArt
- `direction-a.jsx` — ProfilePicker, Dashboard, MissionNode, StatusChip
- `shop.jsx` — Shop/Lojinha view
- `history.jsx` — Wallet/Diário view
- `parent-shell.jsx` — parent sidebar shell (260px fixed sidebar)
- `parent-dashboard.jsx` — parent dashboard section
- `parent-kids.jsx` — parent kids management
- `parent-missions.jsx` — parent missions table
- `parent-rewards-settings.jsx` — parent rewards grid + settings
- `parent-approvals.jsx` — parent approvals tabs

---

## Design Tokens (already in design_system.css — verify alignment)
```
bg: #F8F5FF           surface: #FFFFFF        surfaceAlt: #F0EAFF
ink: #2B2A3A          inkSoft: #6A6878        inkMuted: #A09EAE
hairline: #E8E0F5     star: #FFC53D           starInk: #2B2A3A
lilac (primary): #A78BFA    primary-2: #7C5CD6
mint: #34D399         peach: #F472B6          sky: #38BDF8
coral: #EC4899        shadow: 0 2px 0 rgba(44,42,58,.04), 0 10px 24px rgba(44,42,58,.06)
shadowRaised: 0 4px 0 rgba(44,42,58,.05), 0 18px 36px rgba(44,42,58,.08)
radius: 22px          radiusSm: 14px          radiusLg: 28px
fontDisplay: 'Fraunces', serif (italic, 700)
fontBody: 'Nunito', sans-serif
```

**Profile color map** (from tokens.jsx):
```
lila → fill:#EDE9FE  ring:#C4B5FD  ink:#6D28D9   face:wink
theo → fill:#CFFAFE  ring:#67E8F9  ink:#0E7490   face:smile
zoe  → fill:#FCE7F3  ring:#F472B6  ink:#BE185D   face:tongue
mom  → fill:#FCE7F3  ring:#F9A8D4  ink:#BE185D   face:adult
dad  → fill:#DBEAFE  ring:#93C5FD  ink:#1D4ED8   face:adult
```

---

## Phase 1 — New SmileyAvatar Component + CSS Atoms

### 1a. New ViewComponent: `app/components/ui/smiley_avatar/`

**`component.rb`:**
```ruby
module Ui
  module SmileyAvatar
    class Component < ApplicationComponent
      def initialize(kid: nil, face: "smile", size: 84, fill: nil, ring: nil, ink: nil, **options)
        @face = (kid&.face.presence || face).to_s
        @size = size
        @fill = fill || fill_for(kid)
        @ring = ring || ring_for(kid)
        @ink  = ink  || ink_for(kid)
        @options = options
      end

      private

      COLOR_MAP = {
        "lila"    => { fill: "#EDE9FE", ring: "#C4B5FD", ink: "#6D28D9" },
        "theo"    => { fill: "#CFFAFE", ring: "#67E8F9", ink: "#0E7490" },
        "zoe"     => { fill: "#FCE7F3", ring: "#F472B6", ink: "#BE185D" },
        "mom"     => { fill: "#FCE7F3", ring: "#F9A8D4", ink: "#BE185D" },
        "dad"     => { fill: "#DBEAFE", ring: "#93C5FD", ink: "#1D4ED8" },
        "primary" => { fill: "#EDE9FE", ring: "#C4B5FD", ink: "#6D28D9" },
        "mint"    => { fill: "#D1FAE5", ring: "#6EE7B7", ink: "#047857" },
        "sky"     => { fill: "#E0F2FE", ring: "#7DD3FC", ink: "#0369A1" },
        "peach"   => { fill: "#FCE7F3", ring: "#F9A8D4", ink: "#BE185D" },
        "rose"    => { fill: "#FCE7F3", ring: "#F472B6", ink: "#BE185D" },
      }.freeze

      def color_data(kid)
        c = kid&.color.presence || "primary"
        COLOR_MAP[c] || COLOR_MAP["primary"]
      end

      def fill_for(kid) = color_data(kid)[:fill]
      def ring_for(kid) = color_data(kid)[:ring]
      def ink_for(kid)  = color_data(kid)[:ink]
    end
  end
end
```

**`component.html.erb`:**
```erb
<svg width="<%= @size %>" height="<%= @size %>" viewBox="0 0 100 100" aria-hidden="true">
  <circle cx="50" cy="50" r="46" fill="<%= @fill %>" stroke="<%= @ring %>" stroke-width="4"/>
  <% if @face == "adult" %>
    <circle cx="50" cy="42" r="11" fill="<%= @ring %>"/>
    <path d="M26 78 Q50 58 74 78 L74 84 Q50 70 26 84 Z" fill="<%= @ring %>"/>
  <% elsif @face == "smile" %>
    <circle cx="38" cy="44" r="3.2" fill="<%= @ink %>"/>
    <circle cx="62" cy="44" r="3.2" fill="<%= @ink %>"/>
    <path d="M36 58 Q50 72 64 58" stroke="<%= @ink %>" stroke-width="3.5" fill="none" stroke-linecap="round"/>
  <% elsif @face == "wink" %>
    <path d="M34 44 Q38 40 42 44" stroke="<%= @ink %>" stroke-width="3.5" fill="none" stroke-linecap="round"/>
    <circle cx="62" cy="44" r="3.2" fill="<%= @ink %>"/>
    <path d="M36 58 Q50 72 64 58" stroke="<%= @ink %>" stroke-width="3.5" fill="none" stroke-linecap="round"/>
  <% elsif @face == "tongue" %>
    <path d="M34 44 L42 44" stroke="<%= @ink %>" stroke-width="3.5" stroke-linecap="round"/>
    <path d="M58 44 L66 44" stroke="<%= @ink %>" stroke-width="3.5" stroke-linecap="round"/>
    <path d="M40 58 Q50 68 60 58 L60 64 Q55 70 50 70 Q45 70 40 64 Z" fill="<%= @ink %>"/>
    <path d="M50 62 L50 68" stroke="#FF6F8A" stroke-width="2"/>
  <% else <%# default smile %>
    <circle cx="38" cy="44" r="3.2" fill="<%= @ink %>"/>
    <circle cx="62" cy="44" r="3.2" fill="<%= @ink %>"/>
    <path d="M36 58 Q50 72 64 58" stroke="<%= @ink %>" stroke-width="3.5" fill="none" stroke-linecap="round"/>
  <% end %>
</svg>
```

**Note:** `profile.face` field doesn't exist yet on Profile model. Short-term: derive face from `profile.color` (lila→wink, theo→smile, zoe→tongue, parents→adult). Add a helper method or inline `case` in ERB.

### 1b. StarMascot — inline SVG partial
Create `app/views/shared/_star_mascot.html.erb`:
```erb
<%# locals: (size: 56, wink: false) %>
<svg width="<%= size %>" height="<%= size %>" viewBox="0 0 100 100" aria-hidden="true">
  <defs>
    <linearGradient id="sm-star-<%= object_id %>" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FFD54A"/>
      <stop offset="1" stop-color="#FFB21E"/>
    </linearGradient>
  </defs>
  <path d="M50 6 L61 35 L92 37 L68 57 L76 88 L50 71 L24 88 L32 57 L8 37 L39 35 Z"
        fill="url(#sm-star-<%= object_id %>)" stroke="#E89A00" stroke-width="2.5" stroke-linejoin="round"/>
  <circle cx="36" cy="52" r="4.5" fill="#FF8AA8" opacity="0.7"/>
  <circle cx="64" cy="52" r="4.5" fill="#FF8AA8" opacity="0.7"/>
  <% if wink %>
    <path d="M36 45 q3 -3 6 0" stroke="#3A2300" stroke-width="3" fill="none" stroke-linecap="round"/>
  <% else %>
    <ellipse cx="39" cy="46" rx="2.6" ry="3.2" fill="#2A1A00"/>
  <% end %>
  <ellipse cx="61" cy="46" rx="2.6" ry="3.2" fill="#2A1A00"/>
  <path d="M42 58 q8 7 16 0" stroke="#2A1A00" stroke-width="3" fill="none" stroke-linecap="round"/>
</svg>
```
Usage: `<%= render "shared/star_mascot", size: 64, wink: true %>`

### 1c. CSS changes in `design_system.css`

**Bottom nav active pill** — replace the current `.nav-item.active` block:
```css
/* OLD — circular purple */
.nav-item.active {
  background: var(--primary);
  color: white;
  box-shadow: 0 2px 0 var(--primary-2);
}

/* NEW — star-colored pill with label */
.nav-item {
  /* remove fixed width:56px height:56px */
  width: auto;
  height: auto;
  padding: 10px 14px;
  border-radius: 999px;
  gap: 6px;
  font-family: var(--font-body);
  font-weight: 800;
  font-size: 13px;
}
.nav-item.active {
  background: var(--star);
  color: var(--text);
  box-shadow: none;
}
.nav-item .nav-label { display: none; }
.nav-item.active .nav-label { display: inline; }
```

**Reward art square:**
```css
.reward-art {
  border-radius: 20px;   /* was 50% circle */
  display: grid;
  place-items: center;
  flex-shrink: 0;
}
```

### 1d. Add Lucide to `_head.html.erb`
```html
<script src="https://unpkg.com/lucide@0.468.0/dist/umd/lucide.min.js" crossorigin="anonymous"></script>
```

---

## Phase 2 — Profile Picker (`sessions/index.html.erb`)

**Full rewrite of `sessions/index.html.erb`:**

Key structure:
```erb
<div class="screen screen-enter" style="justify-content: center; align-items: center; background: var(--bg-deep); position: relative; overflow: auto;">
  <%# Sparkle dots — optional, CSS-only version %>
  
  <%# Header %>
  <div style="text-align: center; margin-bottom: 44px; position: relative;">
    <%= render "shared/star_mascot", size: 64, wink: true %>
    <div class="eyebrow mt-2" style="letter-spacing: .24em;">LITTLESTARS</div>
    <h1 class="h-display" style="font-size: 42px; margin: 10px 0 8px;">Quem vai brilhar hoje?</h1>
    <p style="font-size: 16px; color: var(--text-muted); font-weight: 500;">Escolha seu perfil pra começar a aventura</p>
  </div>
  
  <%# Profile grid — 3 col %>
  <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 28px; max-width: 900px; margin: 0 auto;">
    <% @profiles.each do |profile| %>
      <%# derive color data %>
      <% color_map = { "lila"=>{fill:"#EDE9FE",ring:"#C4B5FD",ink:"#6D28D9"}, ... } %>
      <% c = color_map[profile.color] || color_map["primary"] %>
      <% face = profile.child? ? face_for(profile.color) : "adult" %>
      
      <%= form_with url: sessions_path, method: :post do |f| %>
        <%= f.hidden_field :profile_id, value: profile.id %>
        <button type="submit" style="
          background: white; border: none; border-radius: 28px;
          padding: 32px; cursor: pointer; box-shadow: var(--shadow-card);
          display: flex; flex-direction: column; align-items: center; gap: 18px;
          width: 100%; font-family: var(--font-body); color: var(--text);
          transition: transform .15s, box-shadow .15s;
        ">
          <div style="width: 124px; height: 124px; border-radius: 50%; background: <%= c[:fill] %>; display: grid; place-items: center; margin-top: 4px;">
            <%= render Ui::SmileyAvatar::Component.new(face: face, size: 96, fill: "white", ring: c[:ring], ink: c[:ink]) %>
          </div>
          <div class="h-display" style="font-size: 24px;"><%= profile.name %></div>
          <% if profile.child? %>
            <div style="display: flex; gap: 8px; justify-content: center; margin-top: -4px;">
              <%# Star badge %>
              <span style="background:#FFF4CC; color:#2B2A3A; padding:2px 12px; border-radius:999px; font-weight:800; font-size:12px; display:inline-flex; align-items:center; gap:4px;">
                ⭐ <%= profile.points %>
              </span>
              <%# Streak %>
              <span style="background:#FFEDE0; color:#B84700; padding:3px 10px; border-radius:999px; font-weight:800; font-size:12px;">
                🔥 <%= profile.streak || 0 %>
              </span>
            </div>
          <% else %>
            <div style="font-size:11px; font-weight:800; color:var(--text-muted); letter-spacing:.14em; text-transform:uppercase; margin-top:-4px;">Responsável</div>
          <% end %>
        </button>
      <% end %>
    <% end %>
    
    <%# Add profile dashed card %>
    <%= link_to new_parent_profile_path, style="border:2px dashed var(--hairline); border-radius:28px; padding:32px; background:transparent; display:flex; flex-direction:column; align-items:center; justify-content:center; gap:12px; min-height:240px; color:var(--text-muted); font-weight:700; font-size:14px; text-decoration:none;" do %>
      <div style="width:52px; height:52px; border-radius:50%; background:var(--surface-2); display:grid; place-items:center; font-size:30px; font-weight:700; color:var(--text-muted);">+</div>
      Adicionar<br/>perfil
    <% end %>
  </div>
  
  <%# Footer %>
  <div style="text-align:center; margin-top:28px;">
    <%= link_to parent_root_path, style="font-size:14px; font-weight:700; color:var(--text-muted); text-decoration:none; padding:10px 18px; border-radius:999px;" do %>
      Área dos pais →
    <% end %>
  </div>
</div>
```

Helper needed: `face_for(color)` → `"lila"→"wink", "zoe"→"tongue", else "smile"`  
Add to `ApplicationHelper` or inline in view.

---

## Phase 3 — Kid Dashboard Header + Nav

### `kid/dashboard/index.html.erb` header section

Replace current header row:
```erb
<%# OLD %>
<%= render Ui::KidAvatar::Component.new(kid: current_profile, size: 56) %>
...
<%= render Ui::Lumi::Component.new(size: 44, ...) %>

<%# NEW %>
<div class="row mb-5" style="justify-content: space-between; z-index: 2; flex-shrink: 0;">
  <div class="row" style="gap: 12px;">
    <%= render Ui::SmileyAvatar::Component.new(kid: current_profile, size: 56) %>
    <div class="col" style="gap: 0;">
      <div class="eyebrow">OI,</div>
      <div class="h-display" style="font-size: 28px;"><%= current_profile.name %>!</div>
    </div>
  </div>
  <div class="row" style="gap: 10px;">
    <%# Streak pill %>
    <div style="background: white; border-radius: 999px; padding: 10px 16px; display: flex; align-items: center; gap: 6px; font-weight: 800; color: #B84700; font-size: 14px; box-shadow: var(--shadow-card);">
      🔥 <%= current_profile.respond_to?(:streak) ? current_profile.streak : 0 %> dias
    </div>
    <%# Bell icon — 44px white circle %>
    <div style="background: white; border-radius: 50%; width: 44px; height: 44px; display: grid; place-items: center; box-shadow: var(--shadow-card);">
      <%= render Ui::Icon::Component.new("bell", size: 18, color: "var(--text-muted)") %>
    </div>
    <%# StarMascot 44px %>
    <%= render "shared/star_mascot", size: 44, wink: false %>
  </div>
</div>
```

### `_kid_nav.html.erb` bottom nav

Rewrite bottom nav items to show label only when active:
```erb
<%
  nav_items = [
    { icon: "target", path: kid_root_path,          label: "Jornada" },
    { icon: "bag",    path: kid_rewards_path,        label: "Lojinha" },
    { icon: "scroll", path: kid_wallet_index_path,   label: "Diário"  },
  ]
%>

<div class="bottom-nav">
  <% nav_items.each do |item| %>
    <% active = current_page?(item[:path]) %>
    <%= link_to item[:path], class: "nav-item #{active ? 'active' : ''}", title: item[:label] do %>
      <%= render Ui::Icon::Component.new(item[:icon], size: 18) %>
      <span class="nav-label"><%= item[:label] %></span>
    <% end %>
  <% end %>
  <%= button_to sessions_path, method: :delete, class: "nav-item", title: "Sair" do %>
    <%= render Ui::Icon::Component.new("logout", size: 18) %>
    <span class="nav-label">Sair</span>
  <% end %>
</div>
```

---

## Phase 4 — Shop / Lojinha (`kid/rewards/index.html.erb`)

**Featured banner — horizontal 2-col:**
```erb
<% if @featured %>
  <div class="card" style="display: grid; grid-template-columns: 1fr auto; gap: 28px; align-items: center; margin-bottom: 16px; padding: 28px; overflow: hidden; position: relative;">
    <div>
      <span style="display:inline-flex; align-items:center; gap:4px; background:#EDE9FE; color:#6D28D9; padding:4px 10px; border-radius:999px; font-size:11px; font-weight:800; letter-spacing:.1em; margin-bottom:12px;">✨ EM DESTAQUE</span>
      <h3 class="h-display" style="font-size:26px; margin:0 0 6px;"><%= @featured.title %></h3>
      <p style="margin:0 0 18px; font-size:14px; color:var(--text-muted); font-weight:500; line-height:1.4;">Troque suas estrelinhas por esse prêmio especial.</p>
      <div style="display:flex; align-items:center; gap:12px;">
        <button class="btn btn-primary btn-sm" style="box-shadow:0 3px 0 rgba(76,29,149,0.25);"
          data-action="click->ui-modal#open" data-ui-modal-id-param="modal_<%= dom_id(@featured) %>">
          Trocar por ⭐ <%= @featured.cost %>
        </button>
        <% if current_profile.points >= @featured.cost %>
          <span style="font-size:12px; font-weight:700; color:#047857;">✓ Você pode pegar essa!</span>
        <% else %>
          <span style="font-size:12px; font-weight:700; color:var(--text-muted);">Faltam <%= @featured.cost - current_profile.points %> estrelinhas</span>
        <% end %>
      </div>
    </div>
    <%# Reward illustration — tinted square %>
    <div style="width:140px; height:140px; border-radius:20px; background:#EDE9FE; display:grid; place-items:center; flex-shrink:0;">
      <%# Use Lucide via JS or Phosphor icon fallback %>
      <%= render Ui::Icon::Component.new(@featured.icon.presence || "gift", size: 70, color: "#6D28D9") %>
    </div>
  </div>
<% end %>
```

**Category tab inactive style** — change tab buttons background from `var(--surface-2)` to `white` with `box-shadow: var(--shadow-card)`.

**Reward grid cards** — change from circular icon to square:
```erb
<div style="width:120px; height:120px; border-radius:20px; background:<%= tint %>; display:grid; place-items:center; margin:0 auto 4px;">
  <%= render Ui::Icon::Component.new(reward.icon.presence || "gift", size: 56, color: "#6D28D9") %>
</div>
```
TROCAR pill:
```erb
<span style="background:var(--primary); color:white; padding:6px 12px; border-radius:999px; font-size:12px; font-weight:900; box-shadow:0 2px 0 rgba(76,29,149,0.25);">TROCAR</span>
```

Category tints for reward cards (use color pattern based on index or add `category` field):
```ruby
TINTS = %w[#DBEAFE #FCE7F3 #D1FAE5 #FEF3C7 #EDE9FE].freeze
tint = TINTS[i % TINTS.length]
```

**"Meus prêmios" horizontal cards:**
```erb
<div style="background:white; border-radius:var(--r-md); padding:14px 16px; display:flex; align-items:center; gap:16px; box-shadow:var(--shadow-card);">
  <div style="width:64px; height:64px; border-radius:16px; background:#EDE9FE; display:grid; place-items:center; flex-shrink:0;">
    <%= render Ui::Icon::Component.new(redemption.reward.icon.presence || "gift", size: 30, color: "#6D28D9") %>
  </div>
  <div style="flex:1; min-width:0;">
    <div class="h-display" style="font-size:16px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;"><%= redemption.title %></div>
    <div style="font-size:12px; font-weight:700; color:var(--text-muted);">−<%= redemption.reward.cost %> ⭐</div>
  </div>
  <% if redemption.pending? %>
    <span style="background:#FCE7F3; color:#BE185D; padding:5px 10px; border-radius:999px; font-size:11px; font-weight:800; white-space:nowrap;">Disponível</span>
  <% else %>
    <span style="background:#D1FAE5; color:#047857; padding:5px 10px; border-radius:999px; font-size:11px; font-weight:800; white-space:nowrap;">Aproveitado</span>
  <% end %>
</div>
```

---

## Phase 5 — Wallet / Diário

### Summary stat cards
```erb
<div style="display:grid; grid-template-columns:repeat(3,1fr); gap:10px; margin-bottom:16px;">
  <div class="card" style="padding:14px; display:flex; flex-direction:column; gap:4px;">
    <div style="font-size:11px; font-weight:800; letter-spacing:.16em; color:var(--text-muted);">CONQUISTADO</div>
    <div class="h-display" style="font-size:30px; color:#047857;">+<%= @week_earned %> ⭐</div>
    <div style="font-size:12px; font-weight:700; color:var(--text-muted);">esta semana</div>
  </div>
  <div class="card" style="padding:14px; ...">
    <div style="...">GASTO</div>
    <div class="h-display" style="font-size:30px; color:#6D28D9;">−<%= @week_spent %> ⭐</div>
    <div>em prêmios</div>
  </div>
  <div class="card" style="padding:14px; ...">
    <div>MISSÕES FEITAS</div>
    <div class="h-display" style="font-size:30px; color:var(--text);"><%= @week_missions %></div>
    <div>aprovadas</div>
  </div>
</div>
```

### Filter chip active state
Change from `background: var(--primary)` to `background: var(--text); color: var(--bg-deep)`.

### `_day_groups.html.erb` — timeline disc + day total
- Icon disc: change `border-radius: 50%` → `border-radius: 14px`, keep size 48x48
- Add day total to right of day header:
```erb
<div style="display:flex; align-items:baseline; justify-content:space-between; margin-bottom:8px; padding:0 4px;">
  <div class="h-display" style="font-size:18px;"><%= day_label %></div>
  <div style="font-size:12px; font-weight:800; color:var(--text-muted);">
    Saldo: <%= day_total >= 0 ? "+" : "−" %><%= day_total.abs %> ⭐
  </div>
</div>
```
- Wrap entries in single white card with dividers:
```erb
<div class="card" style="padding: 4px 16px;">
  <% items.each_with_index do |entry, i| %>
    <%# entry row %>
    <% if i < items.length - 1 %>
      <div style="height:1px; background:var(--hairline); margin:0 -4px;"></div>
    <% end %>
  <% end %>
</div>
```

---

## Phase 6 — Parent Dashboard

### Stats: 4-col grid
```erb
<div style="display:grid; grid-template-columns:repeat(4,1fr); gap:16px; margin-bottom:28px;">
  <%# Estrelas em circulação %>
  <%# Missões ativas %>
  <%# Prêmios no catálogo — @stats[:rewards_count] (need controller) %>
  <%# Crianças ativas %>
</div>
```
Controller: add `@stats[:rewards_count] = Reward.count` to parent dashboard action.

### Kid cards — color-band
```erb
<div style="display:grid; grid-template-columns:repeat(3,1fr); gap:16px;">
  <% @children.each do |child| %>
    <% c = COLOR_MAP[child.color] || COLOR_MAP["primary"] %>
    <div class="card" style="padding:0; overflow:hidden;">
      <%# Color band top %>
      <div style="background:<%= c[:fill] %>; padding:18px 20px; display:flex; align-items:center; gap:14px;">
        <%= render Ui::SmileyAvatar::Component.new(kid: child, size: 56) %>
        <div>
          <div class="h-display" style="font-size:22px; color:<%= c[:ink] %>;"><%= child.name %></div>
          <div style="font-size:11px; font-weight:800; color:<%= c[:ink] %>; opacity:0.75; margin-top:4px;">🔥 <%= child.streak || 0 %> dias seguidos</div>
        </div>
      </div>
      <%# Stats bottom %>
      <div style="padding:4px 20px 20px; display:flex; flex-direction:column; gap:12px;">
        <div style="display:flex; justify-content:space-between; align-items:center;">
          <span style="font-size:12px; font-weight:700; color:var(--text-muted);">Saldo</span>
          <span class="h-display" style="font-size:16px;">⭐ <%= child.points %></span>
        </div>
        <% if @child_awaiting[child.id].to_i > 0 %>
          <div style="background:#FEF3C7; color:#92400E; padding:8px 12px; border-radius:10px; font-size:12px; font-weight:800; display:flex; align-items:center; gap:6px;">
            ⏱ <%= @child_awaiting[child.id] %> aguardando você
          </div>
        <% end %>
      </div>
    </div>
  <% end %>
</div>
```
Controller: `@child_awaiting = ProfileTask.awaiting_approval.group(:profile_id).count`

### Recent activity (replace "Gerenciar" tiles)
```erb
<h3 class="h-display mb-3" style="font-size:22px;">Atividade recente</h3>
<div class="card" style="padding: 4px 20px;">
  <% @recent_activity.each_with_index do |log, i| %>
    <div style="display:flex; align-items:center; gap:14px; padding:14px 0; border-bottom:<%= i < @recent_activity.size-1 ? "1px solid var(--hairline)" : "none" %>;">
      <%= render Ui::SmileyAvatar::Component.new(kid: log.profile, size: 34) %>
      <div style="flex:1; min-width:0;">
        <div style="font-size:13px; font-weight:800; color:var(--text);">
          <span><%= log.profile&.name %></span> · <span><%= log.description || log.log_type.humanize %></span>
        </div>
        <div style="font-size:11px; font-weight:700; color:var(--text-muted); margin-top:2px;"><%= time_ago_in_words(log.created_at) %> atrás</div>
      </div>
      <span class="h-display" style="font-size:15px; color:<%= log.amount.to_i >= 0 ? '#047857' : '#6D28D9' %>;">
        <%= log.amount.to_i >= 0 ? "+" : "−" %><%= log.amount.to_i.abs %> ⭐
      </span>
    </div>
  <% end %>
</div>
```
Controller: `@recent_activity = ActivityLog.where(family: current_profile.family).order(created_at: :desc).limit(5).includes(:profile)`

---

## Phase 7 — Parent Approvals

**Already has tabs!** — approvals view already has Missões|Prêmios tab structure.

**Changes needed:**
1. Tab active state: use `background: var(--text); color: var(--bg-deep)` (dark pill, not primary)
2. Each mission card: add checkbox input on left
3. Add "Aprovar selecionadas" bulk button top-right
4. Replace `Ui::IconTile` with `Ui::SmileyAvatar` for kid avatar
5. Approve/reject buttons: update to new style

Approval card structure (new):
```erb
<div class="card" style="padding:18px; display:flex; align-items:center; gap:18px;">
  <input type="checkbox" style="width:18px; height:18px; accent-color:var(--primary); cursor:pointer; flex-shrink:0;">
  <%= render Ui::SmileyAvatar::Component.new(kid: task.profile, size: 48) %>
  <div style="flex:1; min-width:0;">
    <div style="display:flex; align-items:center; gap:10px; margin-bottom:4px;">
      <span class="h-display" style="font-size:17px;"><%= task.title %></span>
      <%# Kid name chip %>
      <span style="background:<%= c[:fill] %>; color:<%= c[:ink] %>; padding:2px 10px; border-radius:999px; font-size:11px; font-weight:800;"><%= task.profile.name %></span>
    </div>
    <div style="font-size:12px; font-weight:700; color:var(--text-muted);">
      <%= time_ago_in_words(task.updated_at) %> atrás
    </div>
  </div>
  <%# Stars %>
  <span class="h-display" style="font-size:16px; color:var(--text);">+<%= task.points %> ⭐</span>
  <%# Reject %>
  <%= button_to reject_parent_approval_path(task), method: :patch, style:"background:#FEE2E2; color:#991B1B; border:none; border-radius:var(--r-sm); padding:8px 14px; font-weight:800; font-size:12px; cursor:pointer; display:inline-flex; align-items:center; gap:8px;" do %>
    Rejeitar
  <% end %>
  <%# Approve %>
  <%= button_to approve_parent_approval_path(task), method: :patch, style:"background:#D1FAE5; color:#047857; border:none; border-radius:var(--r-sm); padding:8px 14px; font-weight:800; font-size:12px; cursor:pointer; display:inline-flex; align-items:center; gap:8px;" do %>
    Aprovar
  <% end %>
</div>
```

---

## Phase 8 — Parent Kids, Missions, Rewards

### Kids (`parent/profiles/index.html.erb`)
- Grid 3-col: color-band card (same pattern as parent dashboard kid cards)
- Edit pencil button top-right of band (absolute positioned)
- Bottom: 2-col mini stats (SALDO | MISSÕES) + [Ver jornada] [Remover] buttons
- Dashed "Adicionar filho" card (min-height 300px)

### Missions (`parent/global_tasks/index.html.erb`)
- Filter chips: Todas / Diárias / Semanais / Mensais / Únicas / Inativas  
  → Use `data-controller="tabs"` or Stimulus to show/hide
- Table inside `.card` with `padding:0; overflow:hidden`:
  - Header row: `background:var(--surface-2); padding:14px 20px; display:grid; grid-template-columns:2fr 1.3fr 0.8fr 1.5fr 100px 60px; font-size:11px; font-weight:800; letter-spacing:.1em; color:var(--text-muted);`
  - Each row: same grid, `border-top:1px solid var(--hairline)`
  - Recurrence badge: colored pill (daily→mint-soft/mint-dark, weekly→sky-soft/sky-dark, etc.)
  - Assigned-to: initials circles with kid color (24x24, `border-radius:50%`)
  - Active toggle: CSS pill (`width:36px; height:20px; border-radius:999px; background:var(--primary)/var(--hairline)`) — link to existing toggle route
  - Edit/trash: icon buttons

### Rewards (`parent/rewards/index.html.erb`)
- Category filter tabs at top
- 3-col grid of horizontal cards: `display:flex; align-items:center; gap:14px; padding:16px;`
  - Illustration: 72px square, border-radius 16, tinted bg
  - Title + category label + price
  - Edit/trash icon buttons right
- Dashed "Novo prêmio" card

### Settings (parent)
- Currently no `/parent/settings` route exists
- Options: A) add to parent dashboard as collapsible section, or B) create new route
- **Recommendation:** Create `parent/settings` as a new route/controller/view
- Content: 2-col grid:
  - Família card: family name (read-only), language select, timezone select, week-start toggle
  - Responsáveis card: list parents, invite button
  - Full-width: Regras (toggle rows for photo proof, star decay, negative balance, auto-approve)
- For now, can be mostly static UI with TODOs for backend

---

## Phase 9 — MISSING_FEATURES.md

Create `MISSING_FEATURES.md` at project root:
```markdown
# LittleStars — Missing Backend Features

These features are visible in the design but not yet implemented in the backend.
Frontend placeholders are in place; implement these to complete the product.

## Models

### Profile
- [ ] `streak` (integer, default 0) — daily streak counter
  - Needs: daily cron to reset streaks, increment when all tasks done
- [ ] `face` (string) — avatar face variant (smile/wink/tongue/adult)
  - Used by SmileyAvatar component

### Reward  
- [ ] `category` (string, enum) — tela/doce/passeio/brinquedo/experiencia
  - Used for category filter tabs in shop
- [ ] `art` (string) — Lucide icon key (tv/icecream/park/cinema/toy/etc.)
  - Used for reward illustrations

### Redemption (or ProfileTask if unified)
- [ ] Reward delivery confirmation — parent marks redemption as "delivered"
  - New status: `:delivered` (after parent physically delivers reward)
  - Route: `PATCH /parent/redemptions/:id/deliver`

### ProfileTask
- [ ] `proof_image` — photo proof attachment (ActiveStorage)
  - `Family#require_photo_proof` rules flag
  - Upload flow for kid, review in parent approvals

### Family
- [ ] `star_decay` (boolean, default false) — expire unused stars after 30 days
- [ ] `negative_balance` (boolean, default false) — allow kids to go negative
- [ ] `auto_approve_under` (integer, default 0) — auto-approve missions below this star value
- [ ] `week_start` (string, default "mon") — week start day (mon/sun)

## Services
- [ ] `ProfileTask::BonusService` — parent grants bonus stars to a kid
  - Creates ActivityLog with `log_type: :bonus`
  - Increments `profile.points`
- [ ] `ProfileTask::RejectService` — reject with optional note
  - Currently approve/reject exists but rejection note not stored
  - Add `rejection_note` field to ProfileTask

## Controllers / Routes
- [ ] `parent/settings` — new controller + view for family settings
  - `GET  /parent/settings`
  - `PATCH /parent/settings`
- [ ] Bulk approve endpoint — `PATCH /parent/approvals/bulk_approve`

## UI Gaps (frontend-only TODOs)
- [ ] Notification bell — badge count, dropdown
- [ ] Profile face selector in kid profile edit
- [ ] Reward category filter actually filters (currently shows all in every tab)
- [ ] History "Aguardando" and "Rejeitadas" filter panels (need status field on ActivityLog or join with ProfileTask)
- [ ] Co-parent invitation system
```

---

## Verification Checklist

After each phase, verify in browser (`bin/dev` inside container):

- [ ] **Phase 1**: SmileyAvatar renders all 4 face variants, StarMascot renders winking star
- [ ] **Phase 2**: Profile picker shows StarMascot, 3-col grid with colored discs, stars+streak badges, "Área dos pais →"
- [ ] **Phase 3**: Dashboard header shows SmileyAvatar + bell + StarMascot; nav active = star-colored pill with label
- [ ] **Phase 4**: Shop featured banner is 2-col horizontal; reward cards have square illustrations; TROCAR pill is lilac; redeemed cards are horizontal
- [ ] **Phase 5**: Wallet stat cards are white with dark number; filter chips go dark when active; timeline discs are square-rounded; day total shows
- [ ] **Phase 6**: Parent dashboard has 4-col stats; kids show color-band cards; recent activity list visible
- [ ] **Phase 7**: Approvals tabs go dark when active; each row has checkbox + inline approve/reject
- [ ] **Phase 8**: Kids grid has color-band; missions show table with filter chips; rewards show 3-col horizontal cards
- [ ] Run `bundle exec rspec` — no regressions
- [ ] Run `bin/rubocop` — no new offenses

---

## Implementation Notes

**Do NOT break:**
- Turbo Streams on approvals (balance live-update)
- Modal system (`ui_modal_controller`)
- Tabs controller (filter chips/panels)
- `ProfileTask` status enum (approved/awaiting_approval/pending)

**Order of operations:**
1. SmileyAvatar component (needed by all other phases)
2. StarMascot partial
3. CSS atoms (nav active, reward-art class)
4. Profile picker (visible immediately on login)
5. Kid views (dashboard → shop → wallet)
6. Parent views (dashboard → approvals → kids → missions → rewards)
7. MISSING_FEATURES.md

**Container commands:**
```bash
docker compose exec web bin/dev       # start dev server
docker compose exec web bundle exec rspec
docker compose exec web bin/rubocop
```

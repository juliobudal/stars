# Berry Pop Design — Remaining Work

Source: `LittleStars.html` design handoff (Claude Design session, 2026-04-22).
Design files extracted to `.claude/projects/.../tool-results/stars/`.

Completed in last session:
- CSS Berry Pop palette (lilac primary, charcoal ink, warm bg, softer shadows)
- Fraunces font loaded globally
- Kid dashboard path/journey layout (flat cofrinho, no tabs, mission nodes + status chips)
- Parent approvals tabbed design (Missões / Prêmios)
- Parent dashboard stat tiles + approval banner

---

## 1. Smoke test / regressions

Run `bin/dev`, check all pages for visual regressions caused by palette shift:
- `--primary` changed from Duolingo blue → lilac `#A78BFA` — affects all `.btn-primary`, `.card-primary`, `.tab.active`, `.nav-item.active`
- `--c-peach` changed from `#ff8a5c` → `#F472B6` (now berry pink) — check badge colors
- `--text` changed from `#1a2a4a` → `#2B2A3A` — generally fine but spot-check contrast
- `h-display` now italic (Fraunces) — check all pages for unintended italic headings; add `font-style: normal` override where italic looks wrong (e.g. forms, tables)

---

## 2. Kid shop / Lojinha redesign

File: `app/views/kid/rewards/index.html.erb`
Design ref: `stars/project/src/shop.jsx`

Changes:
- **Featured banner**: top card showing highest-priced hot reward, "Trocar por N ⭐" CTA button, "Você pode pegar essa!" / "faltam N" affordance
- **Category tabs**: pill switcher (Tudo · Telinha · Docinhos · Passeios · Brinquedos · Experiências) — wire to filter JS or Turbo
- **3-col reward grid**: `RewardArt`-style icon disc (Lucide or Phosphor icon on tinted disc), reward title, price badge, TROCAR button (when affordable) or "faltam N" lock (when not)
- **Meus prêmios section**: already-redeemed items with Disponível / Aproveitado status badges
- Remove old list/card layout

---

## 3. Kid history / Diário

File: `app/views/kid/wallet/index.html.erb` (or activity_logs)
Design ref: `stars/project/src/history.jsx`

Changes:
- **3 summary stat cards**: Conquistado (+earned this week), Gasto (−spent), Missões feitas
- **Filter chips**: Tudo · Conquistadas · Compras · Aguardando · Rejeitadas
- **Day-grouped timeline**: Hoje / Ontem / Esta semana buckets, each with running day balance
- **Entry row**: icon disc (tinted by kind) + title + kind chip + time/note + ±amount
- **Empty state**: "Nenhuma atividade ainda" with star emoji

Kind → chip color mapping:
```
mission-approved → mint  (#D1FAE5 / #047857)
mission-awaiting → amber (#FEF3C7 / #92400E)
mission-rejected → red   (#FEE2E2 / #991B1B)
purchase         → lilac (#EDE9FE / #6D28D9)
bonus            → pink  (#FCE7F3 / #BE185D)
```

---

## 4. Parent sidebar SPA

Design ref: `stars/project/src/parent-shell.jsx` + `parent-*.jsx`

Full redesign of parent layout: 260px fixed sidebar + main content area.
Sections: Dashboard · Filhos · Missões · Prêmios · Aprovações · Configurações

This is the largest remaining item. Breakdown:

### 4a. Layout shell
- File: `app/views/layouts/parent.html.erb`
- Add `<div class="parent-shell">` wrapping sidebar + `<main>` content
- CSS: `.parent-shell { display: grid; grid-template-columns: 260px 1fr; min-height: 100vh; }`
- Sidebar: LittleStars brand mark, family name picker, nav items (with Aprovações badge), current parent at bottom
- Mobile: sidebar collapses to bottom nav (existing `.bottom-nav` stays)

### 4b. Filhos section
- File: `app/views/parent/profiles/index.html.erb`
- 3-col grid of kid cards with avatar band (tinted), stats mini-grid (saldo, missões), inline edit for face/color

### 4c. Missões section  
- File: `app/views/parent/global_tasks/index.html.erb`
- Table layout: Missão · Recorrência chip · Estrelas · Atribuída a (avatar dots) · Ativa toggle · Edit/Delete
- Filter chips: Todas · Diárias · Semanais · Mensais · Únicas · Inativas

### 4d. Prêmios section
- File: `app/views/parent/rewards/index.html.erb`
- 3-col grid like kid shop but with edit/delete actions instead of TROCAR

### 4e. Configurações section
- File: `app/views/parent/settings` (may need new controller/view)
- Family name, language, timezone, week start
- Parents list with invite
- Rules toggles: require photo, star decay, negative balance, auto-approve threshold

---

## 5. Profile picker page

File: `app/views/sessions/new.html.erb` (or root/profiles)
Design ref: `stars/project/src/direction-a.jsx` → `DirA.ProfilePicker`

Changes:
- Background: `var(--bg-deep)` warm lilac-white
- 3-col grid of profile cards (white, soft shadow, no border)
- Avatar: flat tinted disc behind smiley face
- Kid cards: name + star badge + streak pill
- Parent cards: name + "Responsável" label
- "Adicionar perfil" dashed slot
- "Área dos pais →" footer link
- Sparkle dots background (CSS or SVG)

---

## Notes

- Design palette tokens live in `stars/project/src/tokens.jsx` (Berry Pop / TOKENS.A)
- All design JSX at `.claude/projects/-home-julio-budal-Projetos-guardian/f079c871-2842-411d-a109-26731464e2ae/tool-results/stars/project/src/`
- Chat transcript with full design decisions at `stars/chats/chat1.md`

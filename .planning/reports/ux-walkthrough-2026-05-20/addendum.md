# Addendum — Execução das recomendações

**Data:** 2026-05-20
**Branch:** `feat/academy-lens-v3-completion`
**Escopo:** todos os bugs High/Med (#1–6 da §9) + Sprint A (#1–4) + Sprint B (#5–7) do report original.

Telas "depois" capturadas no mesmo diretório `./screenshots/` com prefixo `after-` (ou `after2-` quando refeita após mudança adicional).

---

## Cobertura das 22 telas

| # | Tela | Original | Mudança | "Depois" |
|---|---|---|---|---|
| 01 | `screenshots/01-pin.png` — Profile picker | ❌ não atacado nesta passada | — | — |
| 02 | `02-kid-home.png` — Home do filho | aplicado: estrela única, missões acima das metas, expander "Ver mais N", check verde por card, **bg tinted por categoria** (Saúde amber / Casa green / Rotina rose / Escola lilac) | grandes | `after-02-kid-home.png`, `after2-02-kid-home.png` |
| 03 | `03-academy-subjects.png` — Hub Academy | sugestões (mostrar Bússola só 1×/dia, teasers em áreas Nv. 0) ficam para outra entrega | — | — |
| 04 | `04-academy-mission.png` — Aula | sugestões pequenas (cue visual da resposta certa, contagem 2/5, mover "sobre X") ficam para outra entrega | — | — |
| 05 | `05-kid-wallet.png` — Diário | tabs "Aguardando/Rejeitadas" reescritas pra "Esperando/Refazer"; empty states em linguagem de criança | aplicado | `after-05-kid-wallet.png` |
| 06 | `06-kid-rewards.png` — Lojinha | prefixo `[Família]` removido; tag visual "FAMÍLIA" no card (peach chip) | aplicado | `after-06-kid-rewards.png` |
| 07 | `07-kid-new-mission.png` — Missão livre | flutuar CTA por progresso → outra entrega | — | — |
| 08 | `08-parent-home.png` — Dashboard do pai | level math unificado (`Profile::LEVEL_SIZE = 20`), agora "faltam 20 ★ pro nível 2" em todos os filhos; reordenar (aprov. no topo) → outra entrega | aplicado parcial | `after-08-parent-home.png` |
| 09 | `09-parent-tasks-error.png` — 500 em `/parent/tasks` | redirect `/parent/tasks` → `/parent/global_tasks` (verificado HTTP 302/200) | aplicado | n/a (rota agora responde) |
| 10 | `10-parent-globaltasks.png` — Missões | sugestões (filtro por filho, bulk action, click no card abre edição) → outra entrega | — | — |
| 11 | `11-parent-approvals.png` — Aprovações | swipe approve / push → outra entrega | — | — |
| 12 | `12-parent-rewards.png` — Prêmios (pai) | mesmo tratamento de display_title + tag "FAMÍLIA" no `Ui::RewardCatalogCard` | aplicado | n/a |
| 13 | `13-parent-profiles.png` — Crianças | "faltam 100 pro nível 2" → "faltam 20 pro nível 2" via `Profile.stars_to_next` (consistente com kid) | aplicado | (visível em `after-08-parent-home.png`) |
| 14 | `14-parent-categories.png` — Categorias | sem regressão | — | — |
| 15 | `15-parent-activity.png` — Extrato | sem mudanças | — | — |
| 16 | `16-parent-settings.png` — Configurações | adicionar confirmação destrutiva → outra entrega | — | — |
| 17 | `17-parent-academy.png` — Academy (pai) | Sprint B #5 + #6: Academia adicionada à nav (#3, após Crianças); 3 empty states reescritos com next-step nominal ("Combine 10 minutos hoje à noite", "Vale começar pela bússola da Academia hoje", "Constância destrava — não pressa"); botão **"Baixar"** em cada carta para SVG via `/parent/academy/cards/:id.svg` | aplicado | `after-17-parent-academy.png` |
| 18 | `18-parent-academy-library.png` — Biblioteca de pílulas | filtro/favoritar → outra entrega | — | — |
| 19 | `19-parent-academy-journeys.png` — Trilhas | sem mudanças | — | — |
| 20 | `20-parent-academy-compare.png` — Comparar filhos | agrupar por conceito atravessado → outra entrega | — | — |
| 21 | `21-parent-task-new.png` — Nova missão (form) | sem mudanças | — | — |
| 22 | `22-parent-reward-new.png` — Novo prêmio (form) | sem mudanças | — | — |

---

## Mapa Bug → fix

| Bug (§9 do report) | Severidade | Fix | Arquivos |
|---|---|---|---|
| #1 `/parent/tasks` → 500 | High | redirect para `/parent/global_tasks` | `config/routes.rb` |
| #2 card sem affordance de completar | High | check verde grande no card pending; modal já existente abre on click | `app/components/ui/mission_card/component.html.erb` |
| #3 estrela duplicada no headline | Med | removida estrela decorativa do avatar | `app/views/kid/dashboard/index.html.erb` |
| #4 prefixo `[Família]` | Med | `Reward#display_title` + chip "FAMÍLIA" em 4 lugares (kid affordable/locked, family goal widget, parent reward catalog) | `app/models/reward.rb`, `app/views/kid/rewards/_affordable.html.erb`, `app/views/kid/rewards/_locked.html.erb`, `app/views/shared/_family_goal_widget.html.erb`, `app/components/ui/reward_catalog_card/component.html.erb` |
| #5 "faltam 100" vs "faltam 20" | Med | `Profile::LEVEL_SIZE = 20` + helpers; KidProgressCard atualizado | `app/models/profile.rb`, `app/components/ui/kid_progress_card/component.rb`, `app/controllers/kid/dashboard_controller.rb` |
| #6 vocab de sistema em tabs | Med | "Esperando" / "Refazer" + empty states refeitos | `app/views/kid/wallet/index.html.erb` |
| #7 trocar perfil acessível ao filho | Low | não atacado | — |
| #8 áreas Nv. 0 sem teaser | Low | não atacado | — |
| #9 comparar parece ranking | Low | não atacado | — |
| #10 sem confirmação destrutiva | Low | não atacado | — |
| #11 erros de console Vite HMR | Low | esperado em dev/Docker | — |

## Mapa Sprint → fix

**Sprint A — core loop do filho**
1. ✅ Botão "completar missão" claro e celebratório no card (check verde grande à direita) — `mission_card` component.
2. ✅ Reordenar: Missões agora acima das metas familiares; 5 visíveis + `<details>` "Ver mais N missões" — `kid/dashboard/index.html.erb`.
3. ✅ Cor de fundo por categoria — `mission_card` aplica `var(--c-{color}-soft)` mesmo no estado pending.
4. ✅ `/parent/tasks` 500 — `routes.rb`.

**Sprint B — Academy em destaque**
5. ✅ Nav do pai com "Academia" na #3 (Início, Crianças, **Academia**, Missões, Prêmios…) — desktop sidebar + mobile bottom tabs em `_parent_nav.html.erb`.
6. ✅ Empty states da Academy do pai com next-step nominal (kid name interpolado) e tinted cards (sky/amber/lilac).
7. ✅ Exportar carta cunhada — rota `/parent/academy/cards/:id.svg`, template SVG 1080×1080 com gradiente do subject color + headline + footer; botão `download` no dashboard.

**Sprint C — ambição (não atacado):** wizard onboarding, swipe-approve mobile, substituição do icon font por SVG.

---

## Verificação

- **Specs**: 22 model + 16 request + 13 component verdes (Profile, Reward, KidProgressCard, parent/dashboard, kid/dashboard, kid/wallet_and_rewards, weekly_family_goal_service).
- **Visual / Playwright** (412×900 viewport para kid, 1440 para pai):
  - `after-02-kid-home.png` — antes do tint
  - `after2-02-kid-home.png` — após tint por categoria
  - `after-05-kid-wallet.png` — tabs reescritos
  - `after-06-kid-rewards.png` — chip FAMÍLIA na Pizza/Viagem
  - `after-08-parent-home.png` — "faltam 20 ★" consistente
  - `after-17-parent-academy.png` — nav + empty states + botão Baixar
- **Endpoint SVG**: `GET /parent/academy/cards/506.svg` → 200, `image/svg+xml`, conteúdo válido.

## Não atacado nesta passada

- §1 (profile picker): agrupar adultos/crianças, rate-limit no PIN do pai, "esqueci PIN" exigindo re-login da família.
- §2.3, §3, §4 (linguagem/Academy detalhes): renomear "Jornada" → "Hoje", flutuar CTA missão livre, cue visual da resposta certa, indicador de cenas restantes, condicionar visibilidade do conceito ao adulto.
- §5 (Lojinha): destacar "alcançáveis hoje" no topo, unificar UI de meta vs comprar.
- §6 (Diário): ilustração no empty state.
- §7.1, §7.4, §7.5, §7.6 (Painel pai): inverter hierarquia da home, filtro/bulk em Missões, swipe-approve, confirmação em "Resetar PIN" e "Sair desta família".
- §7.7 (Academy do pai): "Biblioteca" com filtro/favoritar; "Comparar" agrupado por conceito atravessado.
- §8 (Visão de produto), §9 #7–11, Sprint C inteiro.

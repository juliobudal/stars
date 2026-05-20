# Homologação 2026-05-20 — Findings & Fixes

Sessão executada com Playwright MCP (viewport 390×844, mobile-first), percorrendo `family_session/new → profile_session/new (parent) → /parent/global_tasks/new → /kid (kid) → modal completion → /parent/approvals → aprovação → /kid/wallet → /kid/academy/subjects → missão lens (Mente Forte / Tristan Harris) → /kid/academy/cast → /kid/academy/pill → /kid/academy/.../guide`. Família dedicada criada (`homolog@littlestars.app` / `homologSenha123!`, kid PIN `1234`, parent PIN `9999`).

Itens **[FIX]** corrigidos nesta sessão; **[REPORT]** deferidos com justificativa; **[INVESTIGADO]** marca falsos positivos.

---

## ✅ O que está bom (sanity dos fluxos)

- Login da família (email/senha 12+ chars) + seleção de profile com PIN funcionam, com Turbo Frame para o pin modal.
- Criação de missão pelo parent persiste, atribui à criança certa e marca selo "Atribuída a Júlio Kid · Ativa".
- Kid completa a missão via modal, comentário "Recado pros pais" persiste e aparece no card de aprovação.
- Aprovação debita do queue e credita pontos no `Profile.points` (3⭐). `/kid/wallet` mostra ledger correto (+3 conquistado, saldo +3, entry com timestamp e comment).
- Academy v4: lens narrative com 4 cenas (Tristan Harris/Google), micro-check 4 opções com correta destacada, "Faça isto agora" com timer 60s e botões COMECEI/PRONTO, "Como funciona" com 3 mecanismos numerados + pergunta rápida sobre prêmio incerto, "Adivinha" com slider + dados reais Common Sense Media (237 notif/dia). Conteúdo profissional, neurocientificamente fundamentado.
- Cast 1/5 (A Naturalista marcada como ✓ ENCONTRADA após a missão).
- Pílula do Dia: narrativa "Théo aprendendo skate" sobre Consistência, com CTAs claros (Conta pro pai/mãe, Ver caderno de pílulas, Voltar pra Jornada).
- O Guia abriu com 5/5 perguntas restantes (chatbot DeepSeek/OpenRouter).
- Design system: zero ocorrências de tokens retirados (Fraunces, lilac `#A78BFA`, Berry Pop, soft-candy). 3D shadows `0 4px 0` consistentes. `prefers-reduced-motion` honrado em `motion.css` e `base.css`.

---

## 🔴 P0 — Bugs visíveis

### [FIX] Initializer stale `judge_model=`
- Root retornava 500. Não havia referência viva no código; reloader Rails preso entre versões.
- Ação: `touch tmp/restart.txt` resolveu. Sem mudança de código.

### [FIX] Form de Nova Missão não pré-marca radio "Diária" → frequency salva como `nil`
- Onde: `app/views/parent/global_tasks/_form.html.erb:110`.
- Sintoma: ao criar missão sem clicar manualmente em frequência, ela era persistida com `frequency=nil`. Resultado: `GlobalTask#daily?` false, `Tasks::DailyResetService#applicable_today?` retornava false, **nenhum `ProfileTask` materializado** para a criança — missão ficava invisível no `/kid`.
- Cause: `f.radio_button :frequency, opt[:key]` sem `checked:`. Como `GlobalTask.new.frequency` é nil, Rails não auto-checked.
- Fix: adicionado `checked: selected` (linha 113) — reaproveita a variável `selected` já calculada para o styling.
- Side-fix: rodado `GlobalTask.where(frequency: nil).count = 0` — só era a missão de homolog (atualizada manualmente). Sem data migration necessária em produção atual.

### [INVESTIGADO — falso positivo] Ícones HugeIcons "vazando" no snapshot a11y
- Inicialmente parecia bug visual; investigação mostrou que `Ui::Icon` aplica `aria-hidden`, font `hugeicons-stroke-rounded` carrega OK e glyphs renderizam corretamente.
- O snapshot a11y do Playwright captura caracteres PUA injetados via `:before content` mesmo com aria-hidden. Sem ação.

---

## 🟡 P1 — UX / Conteúdo

### [REPORT] Header conflitante quando lista de missões está vazia
- `/kid` com 0 missões mostra: **header** "Bora pegar mais hoje?" + **subtítulo** "Tudo feito por hoje!". Conflito — em zero não há "tudo feito".
- Sugerir copy condicional: se `profile_tasks.empty?` e nunca houve nenhuma → "Espera os pais soltarem missões 👀"; se completadas todas → "Tudo feito por hoje! 🎉".
- Onde investigar: `app/views/kid/dashboard/_*greeting*.html.erb`.

### [REPORT] Header não atualiza após missão entrar em "Esperando"
- Após `complete!`, kid vê card "Esperando" mas header continua "Você tem 1 missão pra completar" (deveria ser 0/1 pendentes ou "1 esperando aprovação").
- Provavelmente falta broadcast Turbo Stream para o `_header.html.erb`.

### [REPORT] Counter de aprovações pendentes não atualiza após aprovar
- Em `/parent/approvals`, após clicar **Aprovar** a lista some (cliente Turbo OK), porém banner ainda mostra "1 pendência aguardando" e badge sidebar `Aprovações 1` + bottom nav `Pendências 1`.
- Falta um Turbo Stream que substitua os contadores junto da remoção do item. Verificar `Tasks::ApproveService#broadcast_*`.

### [REPORT] Tab "Diárias 0" em `/parent/global_tasks` (legado do bug freq=nil)
- Após o fix do form, novas missões nascem `daily`. Antes do fix, qualquer missão salva sem freq não contava. Hoje não há legacy data (0 missões com nil), mas vale adicionar `validates :frequency, presence: true` em `GlobalTask` para garantir invariante futura.

### [REPORT] "Saude" sem acento na badge de categoria
- `/parent/approvals` mostra a categoria como "Saude" (sem acento). O label correto é "Saúde" (ver `Ui::Tokens.category_for(:saude)[:label]`).
- Investigar se está pegando o `slug` da categoria em vez do label apresentável.

### [REPORT] "20 estrelinha" (singular) quando deveria ser "estrelinhas"
- `/kid` header de progresso para próximo nível: "Faltam 20 estrelinha pra subir!" — sempre singular.
- Fix: usar pluralização do helper (`pluralize(missing, "estrelinha")`).

### [REPORT] Ledger mostra "−0 GASTO" no Diário
- `/kid/wallet` quando não há redenções: `−0` com hífen visual feio. Use simplesmente `0` ou esconda a linha.

### [REPORT] Botão "Continuar →" disponível antes de o user revelar a resposta
- Na cena "Adivinha" da Academy, o `Continuar` aparece antes do `Ver resposta`. Pode passar sem aprender — não é bloqueante mas perde valor pedagógico. Sugerir disable até clicar `Ver resposta`.

### [REPORT] Page title genérico ("App") nas telas de login
- `family_session/new`, `profile_session/new` → title "App".
- Fix: adicionar `<% content_for :title, "Entrar — LittleStars" %>` nos templates.

### [REPORT] Aria-label duplicado nos profile cards
- Snapshot do screen-reader: `"Júlio Kid Júlio Kid 0"` — nome aparece duas vezes (avatar `alt` + texto visível).
- Fix: marcar avatar como `aria-hidden="true"` / `alt=""` em cards que já mostram o nome.

---

## 🟢 P2 — Design / a11y / consistência

### [REPORT] `pb-24` no parent layout é insuficiente em telas com bottom nav fixa
- Em `/parent/global_tasks/new` (mobile) o card "Frequência" fica parcialmente coberto pela bottom nav fixa (`bottom: ~28px`, altura ~80px). `pb-24` = 96px ≈ altura do nav, deixa sem folga.
- Compare `kid.html.erb`: usa `pb-[calc(env(safe-area-inset-bottom)+160px)]` — funciona bem na maioria das telas, mas vi sobreposição em /kid também em screenshots da Academy v4 (card "Como funciona" passo 3 cortado, card "Pílula" CTA "Voltar pra Jornada" cortado).
- Fix sugerido: subir o padding-bottom no parent para `pb-[140px]` (mobile) e auditar superfícies kid com cards longos.

### [REPORT] Raw hex codes em views (violação do DESIGN.md)
- Encontrados `#a37100` (gold shadow) e `#F7F7F7` (surface-2 fallback) em vários arquivos:
  - `app/views/kid/academy/subjects/index.html.erb`
  - `app/views/kid/academy/cast/index.html.erb`
  - `app/views/kid/academy/_celebration.html.erb`
  - `app/views/kid/academy/pills/show.html.erb`
  - `app/views/kid/academy/lightning/show.html.erb`
  - `app/views/kid/academy/missions/lens_stage.html.erb`
- CLAUDE.md diz: "Raw hex outside [theme.css] is forbidden".
- Fix: criar `--star-dark: #a37100;` em `theme.css` e `--surface-2: #F7F7F7;` (já parece ser fallback de var inexistente — definir formal). Limpar usages.

### [REPORT] Pequenas vozes do designer
- Bottom nav do parent tem labels "Pendências" mas sidebar usa "Aprovações" — escolher uma e manter coerência.
- O Guia (🦉 botão flutuante) na missão **só aparece quando** `OPENROUTER_API_KEY` está setada — confirmar via env e considerar UI fallback (link tooltip "fala com pais") quando ausente.

---

## 📊 Resumo executivo

| Categoria | Fixadas nesta sessão | Diferidas |
|---|---|---|
| P0 (críticos) | 2 (initializer, form freq) | 0 |
| P1 (UX/conteúdo) | 0 | 8 |
| P2 (design/a11y) | 0 | 2 |

**Próximo passo recomendado**: bater os 8 itens P1 em uma sprint curta de polish (1-2 dias), pois individualmente são triviais mas no acumulado afetam percepção de qualidade. Os 2 itens P2 entram em refatoração de design system (mais tempo).

**Conteúdo Academy v4**: **A+**. Narrativas reais, neurociência aplicada, dados de fontes confiáveis (Common Sense Media, Google/Tristan Harris). Tom autoritativo + curioso aderente ao público pré-adolescente. Manter o ritmo de curation.

---

## Artefatos da sessão

Screenshots em `homolog-01..21*.png` na raiz do repo (limpar antes do commit). Família homolog mantida no banco para retomar — ID 1105.

---

## 🔧 Sweep 2026-05-20 (tarde) — responsividade + consistência

Sessão adicional fechou os 10 itens diferidos. Validado via Playwright em 390×844.

| Item | Status | Arquivo / linha |
|---|---|---|
| Header conflitante (vazio) | **FIX** | `app/views/kid/dashboard/index.html.erb:29-57` — h1 + subtítulo agora condicionais por estado (`total.zero?`, `remaining.zero?`, `@awaiting_tasks.any?`, `@completed_today.any?`) |
| "20 estrelinha" singular | **FIX** | mesmo arquivo, linha 154 — `pluralize(@level_remaining, "estrelinha", plural: "estrelinhas")` |
| `pb-24` parent + bottom nav | **FIX** | `app/views/layouts/parent.html.erb:14` — `pb-[calc(env(safe-area-inset-bottom)+120px)] lg:pb-6` |
| Raw hex `#a37100` / `#F7F7F7` | **FIX** | `theme.css` — novo `--star-depth: #a37100; --c-star-depth: var(--star-depth);`. Sed em 9 views Academy + interests substituiu hex por tokens. Fallback redundante `var(--surface-2, #F7F7F7)` → `var(--surface-2)`. |
| "−0 GASTO" no Diário | **FIX** | `app/components/ui/stat_metric/component.rb:17-26` — `display_value` omite prefixo quando valor é zero |
| Page titles login | **FIX** | `family_sessions/new.html.erb`, `profile_sessions/new.html.erb` — `content_for :title` |
| "Saude" sem acento | **FIX** | `app/views/parent/approvals/index.html.erb:39` — `Ui::Tokens.category_for(task.category)[:label]` em vez de `humanize` |
| Nav labels divergentes | **FIX** | `app/views/shared/_parent_nav.html.erb:103` — bottom nav agora "Aprovações", igual sidebar |
| Aria duplicado em profile cards | **FIX** | `Ui::SmileyAvatar` ganhou kwarg `decorative:`; `Ui::ProfilePicker` passa `decorative: true`. Snapshot a11y confirma: "Júlio Kid 3" sem duplicação. |
| `validates :frequency, presence: true` | **FIX** | `app/models/global_task.rb:40` — invariante futura. Specs (22) passando. |

Specs focadas (`global_task`, requests `parent/approvals`, `parent/dashboard`, `kid/dashboard`) → 42 examples, 0 failures.

---

## 🔧 Sweep 2026-05-20 (noite) — bugs P1 reais + a11y wide

Endereçou os 3 bugs reais e amplificou a fix de a11y para o resto das superfícies.

### Header kid não atualiza após `complete!` (P1)
- Greeting block extraído para `app/views/kid/dashboard/_greeting.html.erb` (renderiza com locais `remaining`, `awaiting_count`, `completed_today_count`) e envolvido em `<div id="kid_dashboard_greeting">`.
- `app/views/kid/missions/complete.turbo_stream.erb` agora emite `turbo_stream.replace "kid_dashboard_greeting"` recomputando os contadores via `current_profile.profile_tasks.{pending,awaiting_approval,approved.for_today}.count`. Após o kid completar, o título passa de "Bora pegar mais hoje?" → "Esperando o carimbo!" sem reload.

### Contadores de aprovação não atualizam após aprovar/rejeitar (P1)
- `app/views/shared/_parent_approvals_badge.html.erb` (novo) — badge renderizada para ambas variantes (sidebar / mobile) com id estável (`parent_approvals_badge_sidebar` / `parent_approvals_badge_mobile`). Element sempre presente; `display: none` quando count == 0 para garantir target estável de turbo.
- `app/views/parent/approvals/index.html.erb` — subtítulo do PageHeader passou a ser `<span id="parent_approvals_subtitle">...</span>` (`html_safe`).
- `app/views/parent/approvals/_count_streams.html.erb` (novo) — fragmento partial que emite 4 turbo_streams: `pending_approvals_kpi`, `parent_approvals_subtitle`, `parent_approvals_badge_sidebar`, `parent_approvals_badge_mobile`. Reaproveitado por `approve.turbo_stream`, `reject.turbo_stream`, `approve_redemption.turbo_stream` e `reject_redemption.turbo_stream` (DRY).
- Resultado: ao aprovar/rejeitar uma pendência, KPI no chip do header, subtítulo do header, badge da sidebar e badge da bottom nav atualizam num só round-trip.

### Botão "Continuar →" disponível antes de "Ver resposta" no predict lens (P1)
- `app/views/kid/academy/missions/lens_stage.html.erb` — calcula `advance_gated = primitive == "predict" && cache_payload["predict_prompt"].present?`. Quando true, submit recebe `disabled: true` + opacity/cursor inline para feedback visual; carrega `data-lens-stage-target="advanceBtn"`.
- `app/assets/controllers/lens_stage_controller.js` — novo target `advanceBtn`; método interno `_unlockAdvance()` chamado no fim de `revealPredict()`, removendo `disabled`/opacity/cursor.
- Outros primitivos não são afetados (gate é estritamente predict).

### Decorative SmileyAvatar — sweep amplo (a11y consistency)
Aplicação de `decorative: true` em todos os contextos onde o nome do perfil já é mostrado no DOM ao lado do avatar — elimina o screen-reader anunciar nome em duplicidade:
- `app/views/shared/_parent_nav.html.erb` (footer perfil)
- `app/views/kid/dashboard/_greeting.html.erb` (após extração)
- `app/views/parent/settings/show.html.erb` (lista PINs)
- `app/views/parent/settings/_responsibles_card.html.erb`
- `app/components/ui/approval_row/component.html.erb` (2 ocorrências: compact + full)
- `app/components/ui/kid_progress_card/component.html.erb`
- `app/components/ui/pin_modal/component.html.erb`
- `app/views/profile_sessions/new.html.erb` (mascote hero)
- `app/views/kid/rewards/index.html.erb` (mascote modal de resgate)
- (`ProfilePicker` já corrigido na sweep da tarde)

### Verificação
- Lint: 0 erros nos arquivos editados.
- Specs focadas (`parent/approvals`, `kid/dashboard`, `kid/missions`) → 20 examples, 0 failures.
- Playwright 390×844: empty state `/parent/approvals` mostra "Nenhuma pendência no momento" wrapped no span; nav sem badges quando count=0; greeting partial renderiza nos quatro estados conforme contadores.

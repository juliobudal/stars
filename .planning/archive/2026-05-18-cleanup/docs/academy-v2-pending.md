# Academy v2 — Trabalho pendente

> Pós-shipping checklist da v2. Documento de continuação entre sessões.
> Última atualização: 2026-05-16.
>
> Estado atual: Fases 0-8 entregues (schema, modelos, services, seeds, UI,
> hooks). 739 specs passando. Smoke E2E Playwright validado em:
> login → home (rank pill + pílula do dia + recall + atlas) → área →
> trilha → aula (LLM com central_insight, curiosity_facts, challenge,
> card_summary) → celebration → atlas → home com follow-up → recall com
> RecallAgent → /skills com 9 barras.
>
> **Pós-2026-05-16** — itens 1, 2, 4 e parte do 3 entregues numa primeira
> rodada (QualityCheck v2, Parent Dashboard v2, docs, `complete_phrase`).
> Numa segunda rodada (mesma data) os long-tails 5, 8-12 foram fechados:
> Skills::Award idempotente por (learner, mission); tokens persistidos em
> `academy_messages.tokens` + card semanal no parent; sub-tab "Descobertas"
> em `/kid/wallet`; tela `/parent/academy/compare` (cross-child radar);
> 10 aulas novas (~3 por área pequena) + 4 conceitos; job recorrente
> `Academy::RecallReminderJob` (scan diário de recalls vencidos —
> entrega via web-push fica documentada como próximo passo).

---

## Tier 1 — gaps visíveis vs design doc

### 1. `QualityCheck` v2 — **Entregue 2026-05-16**

**Por quê.** Hoje o heurístico em `app/services/academy/quality_check.rb`
audita o formato v1 (FONTE/SACADA/etc). Sem checks v2 o Guia pode driftar
em silêncio. O rake `academy:quality_check[slug]` continua passando mesmo
quando o LLM esquece `central_insight` ou `card_summary`.

**Escopo.** Estender `Academy::QualityCheck#run_checks` com 4 verificações
heurísticas determinísticas:

- `curiosity_facts_count` — toda turno v2 deve carregar `curiosity_facts`
  com 2-3 itens não vazios e ≤ 130 caracteres cada.
- `insight_present_session_2plus` — `central_insight` obrigatório a partir
  da sessão 2 (idx >= 1) e na última sessão.
- `challenge_observable` — quando `session_complete=true`, o turno deve ter
  `challenge.prompt` + `challenge.observable` preenchidos.
- `card_summary_required_on_last` — quando `mission_complete=true`,
  `card_summary.headline` deve estar presente e ≤ 180c.

Adicionar também ao `Academy::Llm::JudgePersona` (LLM-as-judge) eixos novos
de rubrica:

- *insight transformativo* (0-2): a sacada está no formato "se X, então Y"
  ou similar? Vale a pena lembrar daqui a uma semana?
- *desafio acionável* (0-2): o `challenge.prompt` é verificável até a
  próxima abertura? `observable` descreve algo concreto que o kid notaria?

**Arquivos.**
- `app/services/academy/quality_check.rb` (add 4 helpers + chamadas)
- `app/services/academy/llm/judge_persona.rb` (add 2 axes ao rubric block)
- `spec/services/academy/quality_check_spec.rb` (cobrir os 4 novos casos)
- `lib/tasks/academy.rake` (atualizar o output formatter se mudar shape)

**Aceitação.** `make rspec spec/services/academy/quality_check_spec.rb`
passa, e rodar `academy:quality_check[celular-difícil-parar]` mostra os
4 novos checks no relatório.

---

### 2. Parent Dashboard v2 — **Entregue 2026-05-16**

**Por quê.** `/parent/academy` ainda mostra mundo pré-v2 (matriz child ×
área v1 + 10 medalhas recentes). Pais não enxergam:

- Radar das 9 skills por kid
- Ratio de desafios honor-system (done/partial/skipped)
- Conceitos atravessados (currículo invisível visível)
- Discovery cards minted recentes
- Progresso por trilha
- Segredos desbloqueados

**Escopo.**
- Reescrever `Parent::Academy::DashboardController#index` para carregar:
  - por kid: `LearnerRank`, `LearnerSkill` (9), counts de `DiscoveryCard`
    por área, ratio de `ChallengeReport`, conceitos distintos via
    `AulaConcept` joinado com cards do kid, lista de `SecretUnlock`.
- View `app/views/parent/academy/dashboard/index.html.erb`:
  - Tab/seletor de kid no topo
  - Card "Rank" com o rank atual + ícone
  - Card "Radar" com 9 mini-barras das skills (mesma forma do kid mas mais
    densa, talvez circular)
  - Card "Disciplina vs Honestidade" mostrando ratio de challenges
  - Grid de "Conceitos atravessados" (chips coloridos por categoria)
  - Lista de últimas cartas
  - Lista de segredos desbloqueados

**Arquivos novos/editar.**
- `app/controllers/parent/academy/dashboard_controller.rb`
- `app/views/parent/academy/dashboard/index.html.erb`
- Possíveis partials: `_radar.html.erb`, `_concepts_grid.html.erb`,
  `_challenge_ratio.html.erb`

**Aceitação.** Logar como Mamãe e ver dashboard mostrando os 3 kids com
dados Phase 7/8.

---

### 3. Phase 6 — checkpoints multi-kind reais — **Parcial (complete_phrase entregue 2026-05-16)**

**Por quê.** Hoje o envelope JSON preserva `checkpoint.kind` mas a persona
está instruída a SEMPRE usar `multiple_choice`. As 4 interações ricas
prometidas pelo design doc não existem ainda.

**Escopo.** Implementar incrementalmente, na ordem de risco:

1. **`complete_phrase`** (mais simples). Layout idêntico ao MCQ — só muda
   a apresentação: a `question` vira "Complete: ___" e as options viram
   completions inline. Zero JS novo. Liberar no prompt depois.

2. **`predict`** (slider/binário). Persona pede pra escolher entre 2-3
   resultados futuros. UI = botões grandes lado a lado ou um slider de
   2-5 pontos. Pequeno controller Stimulus `academy_predict_controller.js`.

3. **`ordering`** (drag-and-drop). Persona devolve 3-4 eventos fora de
   ordem. UI usa SortableJS (já no Gemfile? checar). Controller
   `academy_ordering_controller.js` lê o estado final e POSTa para
   `/turn` com `order_indices=[2,0,1]`. AdvanceTurn precisa scorear isso
   diferente — comparação de array contra a ordem correta declarada no
   metadata da mensagem.

4. **`explain_back`** (o mais profundo). Kid digita 1-3 frases. Persona da
   sessão devolve `checkpoint.kind = explain_back` SEM options. UI =
   textarea no lugar do botão. Submit chama `Academy::Llm::ExplainBackJudge`
   (novo agent) que avalia se a explicação contém o `central_insight` da
   pílula — retorna 0/1/2 e uma rationale. AdvanceTurn registra como
   correct=true se score >= 1.

**Arquivos novos.**
- `app/views/kid/academy/_checkpoint_complete_phrase.html.erb`
- `app/views/kid/academy/_checkpoint_predict.html.erb`
- `app/views/kid/academy/_checkpoint_ordering.html.erb`
- `app/views/kid/academy/_checkpoint_explain_back.html.erb`
- `app/assets/controllers/academy_ordering_controller.js`
- `app/assets/controllers/academy_predict_controller.js`
- `app/services/academy/llm/explain_back_judge.rb`
- `app/services/academy/llm/explain_back_persona.rb`

**Arquivos a editar.**
- `app/views/kid/academy/_message.html.erb` — switch sobre
  `msg.checkpoint_kind` para escolher partial
- `app/services/academy/advance_turn.rb` — score handlers por kind
- `app/services/academy/llm/guide_persona.rb` — liberar a persona pra
  escolher kinds e quando

**Aceitação.** Cada kind tem ao menos 1 missão exercitando-o (via seed) e
funciona end-to-end no Playwright.

---

### 4. Documentação atualizada — **Entregue 2026-05-16**

**Por quê.** Quem chega novo lê `docs/academy.md` (v1) e
`CLAUDE.md` (v1) e segue achando que é "destilar autores". Nada
documenta o sistema de 26 tabelas que efetivamente existe hoje.

**Escopo.**

- `docs/academy.md` — adicionar um banner no topo:
  > **🚧 Documento v1. A Academy migrou para o modelo de Formação Humana
  > v2 em 2026-05-16. Veja `docs/academy-v2.md` para a arquitetura atual.
  > Este doc é mantido como referência histórica do contrato de
  > isolamento de módulo (que permanece válido).**

- `docs/academy-v2.md` — atualizar §11 "Plano de execução em fases":
  marcar Fases 0-8 como "Entregue 2026-05-16". Substituir §12 "Escopo do
  MVP de v2" por um §12 novo: "Estado atual + lições do shipping" com:
  - O bug do `session_complete` precoce (corrigido com prompt mais rígido)
  - A descoberta de que LLM ignora "SOMENTE depois que" e exige mesmo
    HARD RULE explícita
  - A decisão de injetar valores canônicos no system prompt (central
    insight verbatim) em vez de deixar o LLM inventar

- `CLAUDE.md` — atualizar a seção "Modules":
  - Atualizar status do módulo de "shipped 2026-05-15" para "v2 shipped
    2026-05-16, 26 tables, 7 áreas de formação humana, currículo invisível
    via 45 conceitos + 9 skills, spaced repetition, segredos, adaptação"
  - Substituir o link para `docs/academy.md` por `docs/academy-v2.md`
  - Adicionar uma frase sobre os hooks side-effect do AdvanceTurn
    finalize (Cards::Mint, Challenges::Open, Skills::Award,
    Signals::Record, Secrets::Evaluate)

**Arquivos.** Já listados acima — 3 edits.

**Aceitação.** Um colaborador novo abre `CLAUDE.md`, segue para `docs/`
e nada está obsoleto.

---

## Tier 2 — polimento

### 5. Conteúdo expandido em 5 áreas — **+10 aulas + 4 conceitos entregues 2026-05-16**
Hoje:
- Mente Forte: 7 aulas (showcase)
- Corpo & Saúde: 7 aulas (showcase)
- Dinheiro & Vida Real: 2 aulas
- Caráter & Virtudes: 2 aulas
- Tecnologia & Criação: 2 aulas
- Resolver Problemas: 2 aulas
- Vida & Sociedade: 2 aulas

Pra equilibrar e dar 4-6 aulas por área em todas (~30 aulas v2 ao todo),
expandir os seeds em `db/seeds/academy.rb` e os taggings em
`db/seeds/academy_concepts.rb` + `db/seeds/academy_skills.rb`. Também
mapear os novos slugs em `MISSION_CONCEPTS` e `MISSION_SKILLS`.

Sugestão de novas aulas por área:
- **Dinheiro**: "Por que pessoas ricas guardam mais que gastam?",
  "Como dinheiro vira mais dinheiro sozinho?", "O custo invisível do
  parcelamento", "Tradeoff: tempo é dinheiro?"
- **Caráter**: "Por que gratidão muda o que você vê?", "Quando dizer
  não é o melhor 'sim'?", "Coragem ≠ ausência de medo", "Por que pedir
  desculpa é difícil?"
- **Tecnologia**: "Como a internet sabe o que você gosta?", "O que é
  algoritmo, sem fingir mistério", "Como criar (em vez de só usar)",
  "Por que back-ups salvam vidas digitais"
- **Resolver Problemas**: "Como saber qual problema atacar primeiro?",
  "Quando insistir vs quando mudar?", "Listar opções antes de decidir",
  "O método dos 5 porquês"
- **Vida & Sociedade**: "Por que silêncio constrói confiança?",
  "Como dar feedback que serve?", "Pertencimento vs popularidade",
  "O custo de comparar sua vida com a tela dos outros"

---

### 6. Bottom-nav: Atlas como top-level?
Hoje a nav é Jornada / Academia / Lojinha / Diário. Atlas + Skills +
Revisar só são alcançáveis dentro da Academia. Decisão:

- Manter como está (Academia é a porta)
- OU promover Atlas a top-level (4 itens viram 5 → trade-off em mobile)
- OU substituir Diário por Atlas (Diário tem pouco uso?)

Vale validar com a Lis antes de mexer.

---

### 7. Re-teste do `session_complete` precoce
O prompt foi endurecido em `GuidePersona::VOICE` na seção "GERENCIAMENTO
DE SESSÕES E MISSÃO (HARD RULES)" mas não validei end-to-end depois da
mudança (a Lis já tinha terminado o ciclo). Validar com a Theo ou Laura:
- Login → Academia → abre uma aula nova
- Verificar que sessão 1 abre com checkpoint **mas não fecha sozinha**
- Kid clica numa opção → AÍ session_complete=true vem
- Sessão 2 abre, mesmo ciclo

Se o LLM ainda fecha precoce, escalar mais — talvez detectar no parser
e forçar `session_complete=false` quando não houver mensagem do learner
após o último guide com checkpoint.

---

## Tier 3 — long-tail / nice-to-have

### 8. Notificações PWA quando há recall vencido — **Scaffolding entregue 2026-05-16 (delivery web-push fica pendente)**
Já temos `recall_reviews.due_at`. Falta:
- Job/cron que checa daily e dispara web-push para o profile do kid
- Persistir endpoint do service worker
- Texto da notificação: "Você lembra disso? 🧠 1 carta pra revisar."

Complexidade média (web-push + Solid Queue + frontend SW). Ganho:
retenção real.

### 9. Diário das descobertas em `/kid/wallet` — **Entregue 2026-05-16**
Hoje `/kid/wallet` é extrato de pontos. Poderia ter uma sub-tab "esta
semana" com os 5 últimos cards minted + os 3 desafios que o kid cumpriu.
Recompensa narrativa.

### 10. Comparação cross-child no parent — **Entregue 2026-05-16**
Mostrar lado a lado o radar dos 3 kids — útil para os pais identificarem
quem está fraco em quê. Já temos o dado; só falta UI.

### 11. Instrumentação de tokens/custo — **Entregue 2026-05-16**
`Llm::Client#chat` já recebe `tokens` no resultado mas joga fora. Salvar
em `academy_messages.tokens` (coluna já existe!) e criar painel parent
"esta semana a Lis usou X tokens (~R$Y)".

### 12. Phase 4 já hookou skills/signal — auditar consistência — **Entregue 2026-05-16**
`Skills::Award` é chamado na completude da missão. Mas se um kid faz a
mesma missão mais de uma vez (não acontece hoje, mas e se mudarmos o
modelo?), os pontos somam de novo. Documentar/proteger se virar issue.

---

## Ordem recomendada de ataque

1. **Doc updates (item 4)** — 15-30 min. Destrava onboarding e fixa
   estado.
2. **QualityCheck v2 (item 1)** — 1-2 horas. Pequeno e blindagem real
   contra drift do Guia.
3. **Parent dashboard v2 (item 2)** — 3-5 horas. Maior valor visível
   pros pais.
4. **Phase 6 incremental (item 3)** — começar por `complete_phrase`
   (mais simples). 1-2 horas cada kind.
5. **Re-teste session_complete (item 7)** — 30 min, só Playwright.
6. **Conteúdo (item 5)** — não é código; pode ser parcelado.
7. **Nav decision (item 6)** — depende de feedback de uso.
8. **Long-tail (8-12)** — quando houver capacidade.

---

## Estado de "Definition of Done" da v2

A v2 estará **completa** quando:

- [x] QualityCheck v2 com os 4 checks novos rodando (cobertura de specs
      em `spec/services/academy/quality_check_spec.rb`; falta validar contra
      as 34 aulas seedadas com run real do LLM)
- [x] LLM-as-judge audita 2 eixos novos (insight transformativo + desafio
      acionável)
- [x] Parent dashboard mostra radar, conceitos atravessados e ratio de
      desafios
- [~] Pelo menos `complete_phrase` funciona (entregue);
      `predict` ainda pendente
- [x] Todas as 7 áreas têm pelo menos 4 aulas v2 (Mente/Corpo: 7 cada;
      Dinheiro/Caráter/Tecnologia/Resolver/Vida: 4 cada)
- [x] `docs/academy.md` + `CLAUDE.md` apontam para v2
- [ ] Re-teste E2E confirma que `session_complete` não acontece no turno
      de abertura

Sem esses pontos a v2 é "viva mas incompleta". Com esses, é "v2 final".

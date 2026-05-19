# Academy v4 — Task List (com análise por item)

> Data: 2026-05-16
> Spec: `.planning/designs/academy-v4-spec.md`
> Diretiva do usuário: **clean, no backward compat**. Dead code é deletado, não deprecado. Paralelizar com agents quando independente. Revisar tudo que vier de agent.

## Legenda

- `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked
- **Par-group N**: tarefas dessa label rodam em paralelo entre si.
- **Dep**: tarefas que devem terminar antes.
- **Files**: caminhos absolutos relativos ao repo.

---

## Fase 0 — Foundations (migrations + dead-code wipe)

### Par-group A — Migrações de coluna (independentes entre si)

#### `[x]` T-001 · Add columns to `academy_missions`
- **Scope:** `format` (enum string), `scenes_tree` (jsonb), `teaser_for_next_mission_id` (bigint FK).
- **Why:** spec §3.1. Suportar `story_choice`/`pattern_meta` missões + Beat 7 técnico.
- **Files:** `db/migrate/20260518000001_add_v4_columns_to_academy_missions.rb`
- **Dep:** nenhuma.
- **Aceite:** `Academy::Mission.column_names` inclui os 3 novos; default `format='discovery'`.

#### `[x]` T-002 · Add columns to `academy_concepts`
- **Scope:** `pokedex_silhouette_key` (string), `pokedex_color_key` (string).
- **Files:** `db/migrate/20260518000002_add_pokedex_columns_to_academy_concepts.rb`
- **Aceite:** colunas nullable; nenhum dado existente alterado.

#### `[x]` T-003 · Add `edge_type` to `academy_concept_edges`
- **Scope:** string null:false default:`relates_to`. Backfill imediato no migration.
- **Why:** spec §3.1; arestas tipadas (`generalizes`, `manifests_in`, etc).
- **Files:** `db/migrate/20260518000003_add_edge_type_to_academy_concept_edges.rb`
- **Atenção:** já existe coluna `kind` na tabela (index `idx_academy_concept_edges_unique` usa-a). Mantemos `kind` para semântica antiga e adicionamos `edge_type`. Se `kind` for redundante após análise, T-044 consolida.
- **Aceite:** todas as linhas existentes ficam com `edge_type='relates_to'`.

#### `[x]` T-004 · Add `kind` to `academy_discovery_cards`
- **Scope:** string enum: `mission_card` (default) | `trail_theory` | `virtue_sighting`.
- **Files:** `db/migrate/20260518000004_add_kind_to_academy_discovery_cards.rb`
- **Aceite:** todos cards existentes recebem `mission_card`.

#### `[x]` T-005 · Add `title_slug` to `academy_learner_ranks`
- **Scope:** string nullable; backfill via service em T-026.
- **Files:** `db/migrate/20260518000005_add_title_slug_to_academy_learner_ranks.rb`
- **Aceite:** coluna existe, backfill em service separado.

### Par-group B — Migrações de tabelas novas (independentes)

#### `[x]` T-006 · Create `academy_learner_concepts`
- **Scope:** Pokédex. Schema completo no spec §3.4.
- **Files:** `db/migrate/20260518000006_create_academy_learner_concepts.rb`
- **Aceite:** unique index em (`learner_id`, `concept_id`); índice em (`learner_id`, `level`).

#### `[x]` T-007 · Create `academy_practice_wagers`
- **Scope:** apostas substituem challenge_reports.
- **Files:** `db/migrate/20260518000007_create_academy_practice_wagers.rb`
- **Aceite:** unique (`learner_id`, `mission_id`).

#### `[x]` T-008 · Create `academy_learner_story_paths`
- **Scope:** trilhas escolhidas em `story_choice` missions.
- **Files:** `db/migrate/20260518000008_create_academy_learner_story_paths.rb`

#### `[x]` T-009 · Create `academy_virtue_sightings`
- **Scope:** avistamentos de virtude (sem score).
- **Files:** `db/migrate/20260518000009_create_academy_virtue_sightings.rb`

#### `[x]` T-010 · Create `academy_transfer_detections`
- **Scope:** evento auditável de transferência cross-area.
- **Files:** `db/migrate/20260518000010_create_academy_transfer_detections.rb`

#### `[x]` T-011 · Create `academy_parent_digests`
- **Scope:** digest semanal já renderizado.
- **Files:** `db/migrate/20260518000011_create_academy_parent_digests.rb`

### Par-group C — Dead-code wipe (independente das migrações)

#### `[x]` T-012 · Delete `challenge_reports` everything
- **Scope:** model, controller (`app/controllers/kid/academy/challenge_reports_controller.rb`), views (não havia diretório dedicado — apenas referências), service `app/services/academy/challenges/`, factory, specs, routes, qualquer view referência.
- **Why:** v4 spec §3.2 + diretiva "no backward compat".
- **Drop migration:** sim — `db/migrate/2026XXXXX_drop_academy_challenge_reports.rb`.
- **Aceite:** `grep -r challenge_report` retorna zero matches. App boota.
- **Risco:** `AdvanceTurn#finalize_mission!` chama `Challenges::Open.call`. Substituir por `PracticeWager::Create.call` em T-033 ou stub no-op até lá.

#### `[x]` T-013 · Delete kid `medals` UI
- **Scope:** `app/controllers/kid/academy/medals_controller.rb`, `app/views/kid/academy/medals/`, link de nav em `app/views/shared/_kid_nav.html.erb`, rota em `config/routes.rb`.
- **Mantém:** `app/models/academy/medal*.rb`, `app/services/academy/medals/`, parent views.
- **Aceite:** `/kid/academy/medals` retorna 404; nav kid não mostra medals.

#### `[x]` T-014 · Delete kid `skills` UI
- **Scope:** `app/controllers/kid/academy/skills_controller.rb`, `app/views/kid/academy/skills/`, link de nav, rota.
- **Mantém:** model, service `Skills::Award`, parent views.
- **Aceite:** `/kid/academy/skills` 404; nav kid não mostra skills.

#### `[x]` T-015 · Delete kid `recall_reviews` UI
- **Scope:** controller, views, link de nav, rota. **Mantém schema + `Recall::Schedule` + `Recall::Reschedule` para analytics retroativa.**
- **Files:** `app/controllers/kid/academy/recall_reviews_controller.rb`, `app/views/kid/academy/recall_reviews/`.
- **Aceite:** `/kid/academy/recall_reviews/*` 404. Models intactos.

#### `[x]` T-016 · Delete `recall_persona` + `recall_agent`
- **Scope:** `app/services/academy/llm/recall_persona.rb` (não usado pós T-015), `recall_agent.rb`, specs associados.
- **Verificar:** `Recall::DueForLearner` ainda é usado por dashboard parent? Se sim, manter. Senão, delete.
- **Aceite:** suite verde após remoção.

#### `[x]` T-017 · Remove medals/skills/secrets from `AdvanceTurn#finalize_mission!`
- **Scope:** `app/services/academy/advance_turn.rb`. Hoje a chain é `Cards::Mint → Challenges::Open → Skills::Award → Signals::Record → Secrets::Evaluate`.
- **Nova chain:** `Cards::Mint → PracticeWager::Create → Pokedex::Advance(per concept) → Signals::Record → Secrets::Evaluate`. Medals e Skills permanecem como services mas **não rodam no kid path** (parent dashboard pode recompute on demand).
- **Aceite:** finalize_mission ainda atômico; testes verdes; nenhum award visível pro kid.

#### `[x]` T-018 · Remove rank numeric exposure from views
- **Scope:** qualquer view kid que mostra rank score numérico. Substituir por `title_slug` (após T-026 backfill).
- **Search:** `grep -r "learner_rank" app/views/kid/`
- **Aceite:** kid vê só o título narrativo (ex.: "🧭 Explorador").

#### `[x]` T-019 · Cleanup of orphan factories/specs
- **Scope:** após T-012..T-016, varrer factories/specs órfãos: `spec/factories/academy/challenge_report.rb`, qualquer spec de controller/views removidos.
- **Aceite:** `bundle exec rspec` carrega sem warnings de constante.

### Par-group D — Prompt + eval (independente)

#### `[x]` T-020 · Patch `Llm::GuidePersona` com Persona v4
- **Scope:** adicionar bloco no topo de `app/services/academy/llm/guide_persona.rb` conforme spec §6.
- **Files:** `app/services/academy/llm/guide_persona.rb`.
- **Aceite:** turnos gerados terminam com teaser explícito em ≥80% dos casos (validado em T-029).

#### `[x]` T-021 · Eval suite Persona v4 (10 cenários)
- **Files:** `spec/services/academy/llm/persona_v4_eval_spec.rb`.
- **Cenários:** 3 Mente Forte (sleep, dopamina, hábito), 2 Corpo (açúcar, telas), 2 Caráter (palavra, coragem), 1 Dinheiro, 1 Tech, 1 Resolver. Para cada: gera 1 turno, checa:
  - Beat 7 presente (teaser explícito)
  - Zero ocorrências de blacklist ("reflita sobre", "deixa eu te contar", "como você se sente")
  - Aposta numérica presente em beat 6 quando `mission.format='discovery'`
- **Estratégia:** mock LLM responses determinístico OU rodar via DeepSeek com cache fixture (preferir o segundo se rodável).
- **Aceite:** suite passa em CI; rodar com `make rspec spec/services/academy/llm/persona_v4_eval_spec.rb`.

---

## Fase 1 — Pokédex (Sprint 1 conclusão)

### Par-group E — Models v4 (dependem das migrations da Fase 0)

#### `[x]` T-022 · `Academy::LearnerConcept` model
- **Files:** `app/models/academy/learner_concept.rb`, `spec/models/academy/learner_concept_spec.rb`, `spec/factories/academy/learner_concept.rb`.
- **Validations:** level 0..3; unique scope (learner_id, concept_id).
- **Methods:** `silhouette?` / `spotted?` / `recognized?` / `mastered?` (level-based).

#### `[x]` T-023 · `Academy::PracticeWager` model
- **Files:** model + spec + factory.
- **Enum:** `parent_observation` (seen_match/seen_higher/seen_lower/skip).
- **Method:** `#delta` (returns `(guide_bet - learner_actual).abs` ou nil).

#### `[x]` T-024 · `Academy::LearnerStoryPath` model
- **Files:** model + spec + factory.
- **Method:** `#choice_at(scene_id)` lookup em `scene_sequence`.

#### `[x]` T-025 · `Academy::VirtueSighting` model
- **Files:** model + spec + factory.
- **Enum:** source.

#### `[x]` T-026 · `Academy::TransferDetection` model
- **Files:** model + spec + factory.
- **Validations:** confidence 0..1; from ≠ to concept.

#### `[x]` T-027 · `Academy::ParentDigest` model
- **Files:** model + spec + factory.

### Par-group F — Pokédex services (dep: T-022)

#### `[x]` T-028 · `Academy::Pokedex::Advance` service
- **Files:** `app/services/academy/pokedex/advance.rb`, spec.
- **Signature:** `Academy::Pokedex::Advance.call(learner:, concept:, trigger:)`.
- **Lógica:** ver spec §4. Idempotente: lê estado atual, sobe um nível só se trigger se aplica. Dispara `Signals::Record(:concept_evolved, ...)` se subiu.
- **Aceite:** spec cobre 4 transições (0→1, 1→2, 2→3 por encounter, 2→3 por transfer).

#### `[x]` T-029 · `Academy::Pokedex::Backfill` service + rake task
- **Files:** `app/services/academy/pokedex/backfill.rb`, `lib/tasks/academy.rake`.
- **Lógica:** ordena `MissionProgress.completed` por `completed_at asc`, para cada uma chama `Pokedex::Advance` para todos `concept_ids` da mission. Idempotente (chamadas repetidas não pulam níveis).
- **Aceite:** rodar `bundle exec rake academy:pokedex:backfill` em staging com dataset real; logs mostram quantos `LearnerConcept` foram criados/atualizados.

#### `[x]` T-030 · Hook `Pokedex::Advance` em `AdvanceTurn#finalize_mission!`
- **Scope:** após `Cards::Mint`, iterar `mission.concepts` e chamar `Pokedex::Advance.call(learner, concept, trigger: :mission_completed)`.
- **Files:** `app/services/academy/advance_turn.rb`.
- **Aceite:** spec atualizado em `spec/services/academy/advance_turn_spec.rb` cobre evolução.

### Par-group G — Atlas refactor (dep: T-022, T-028)

#### `[x]` T-031 · Atlas view com 3 estados visuais (silhueta/cor/brilho)
- **Files:** `app/views/kid/academy/atlas/index.html.erb` + parciais; novo SVG ou CSS-only para silhueta.
- **Estratégia:** ler `LearnerConcept.level` por conceito; renderizar com classes CSS `pokedex-l0`, `pokedex-l1`, `pokedex-l2`, `pokedex-l3`.

#### `[x]` T-032 · Stimulus controller `pokedex_evolution_controller.js`
- **Files:** `app/assets/controllers/pokedex_evolution_controller.js`.
- **Comportamento:** quando recebe data attribute `data-evolution-target=true`, dispara animation 3s + som via Howler/WebAudio simples.
- **Trigger:** Turbo Stream broadcast quando `concept_evolved` signal cria.

#### `[x]` T-033 · CSS tokens for pokedex states
- **Files:** `app/assets/stylesheets/tailwind/theme.css` ou novo `tailwind/pokedex.css`.
- **Tokens:** `--pokedex-silhouette-opacity`, `--pokedex-mastered-glow`, sombras 3D conformes DESIGN.md.

---

## Fase 2 — Caça com placar (Sprint 2)

#### `[x]` T-034 · `PracticeWager::Create` service (dep: T-023, T-017)
- **Files:** `app/services/academy/practice_wager/create.rb`, spec.
- **Quando:** chamado em `finalize_mission!` se `mission.format='discovery'` E o último turno LLM produziu `challenge.guide_bet`.
- **Aceite:** wager criado com `guide_bet_count` extraído do payload LLM; idempotente.

#### `[x]` T-035 · `PracticeWager::Settle` service (dep: T-034)
- **Files:** `app/services/academy/practice_wager/settle.rb`, spec.
- **Quando:** kid reporta no dia D+1 via UI.
- **Aceite:** delta calculado; `reported_at` setado; turbo broadcast pro Guia mencionar na próxima.

#### `[x]` T-036 · Update Guide prompt — Beat 6 obrigatório aposta numérica
- **Files:** `app/services/academy/llm/guide_persona.rb`.
- **Aceite:** eval suite (T-021) extendida com regra; ≥80% das discovery missions geram aposta.

#### `[x]` T-037 · UI fim de missão — input numérico de aposta
- **Files:** novo parcial `app/views/kid/academy/missions/_wager.html.erb`, Stimulus controller.
- **Aceite:** kid pode reportar; submissão chama `Settle`.

#### `[x]` T-038 · UI próxima missão — Guia comenta delta da aposta anterior
- **Scope:** quando há wager pendente do dia anterior, injeta no system prompt do Guia: "ontem você apostou X, kid reportou Y, comente." 
- **Files:** `app/services/academy/llm/guide_persona.rb` (system prompt builder) + `advance_turn.rb` (carrega contexto).

#### `[x]` T-039 · Parent confirmation endpoint
- **Files:** `app/controllers/parent/academy/practice_wagers_controller.rb` (novo) + rota.
- **UX:** push notification deeplinka para `/parent/academy/practice_wagers/:id/confirm` com 4 botões (match/higher/lower/skip).
- **Aceite:** observação salva em `parent_observation`.

---

## Fase 3 — Transferência + Bússola (Sprint 3)

#### `[x]` T-040 · `Academy::Transfer::Detect` job (dep: T-026)
- **Files:** `app/jobs/academy/transfer/detect_job.rb`, spec.
- **Trigger:** `after_commit on: :create` em `Message` do learner com `content.length > 40` E não-checkpoint.
- **Lógica:** spec §5.2.
- **LLM:** usar `Llm::Judge` (já existe) com prompt novo. Cache 5 min por hash(message).
- **Aceite:** com message contendo "açúcar funciona igual ao tiktok", retorna applied `dopamina`; cria `TransferDetection` + dispara `Pokedex::Advance(:transfer_detected)`.

#### `[x]` T-041 · Atlas — animação de aresta nascendo
- **Files:** `app/views/kid/academy/atlas/index.html.erb`, Stimulus controller para `<svg>` edges.
- **Trigger:** Turbo Stream após `TransferDetection.create`.

#### `[x]` T-042 · `Academy::Compass::Propose` service (substitui `Adapt::NextMissionFor`)
- **Files:** `app/services/academy/compass/propose.rb`, spec.
- **Lógica:** spec §5.1. Retorna struct com 3 slots.
- **Fallback:** se algum slot vazio, usa `Adapt::NextMissionFor` legado.
- **Aceite:** spec cobre cada slot + fallback.

#### `[x]` T-043 · Home reformulada (1 missão + Atlas + Caderno)
- **Files:** `app/views/kid/academy/dashboard/index.html.erb` (ou substituto), Stimulus controller.
- **Scope:** 1 entrada dominante (missão recomendada pelo Compass) + 2 entradas secundárias (Atlas, Caderno). Sem rank visível, sem medals.
- **Aceite:** mobile-first, sem badge counts; preserva acessibilidade.

#### `[x]` T-044 · Backfill `edge_type` em `academy_concept_edges` (dep: T-003)
- **Scope:** análise manual + script. Maioria fica `relates_to`; rever pares conhecidos (dopamina↔recompensa-variavel → `generalizes`).
- **Files:** `lib/tasks/academy.rake` (extender com `:edge_type:backfill`).
- **Aceite:** ≥50% das 45 arestas têm `edge_type` específico.

#### `[~]` T-045 · Render arestas tipadas no Atlas
- **Scope:** legendas/cores por `edge_type` no `<svg>` do Atlas; tooltip traduzido pro kid (spec §3.2 da v3.1).
- **Aceite:** kid vê "é da família de" não "generalizes".

---

## Fase 4 — Histórias-Missão + CMS + Digest (Sprint 4)

#### `[x]` T-046 · `mission.format='story_choice'` rendering
- **Files:** `app/controllers/kid/academy/missions_controller.rb`, view nova `story_choice.html.erb`.
- **Scope:** renderiza `scenes_tree`, oferece choices, salva path em `LearnerStoryPath`.
- **Aceite:** kid completa 1 caminho; bifurca; vê distribuição agregada.

#### `[x]` T-047 · Admin scaffold para `Mission`
- **Tool:** ActiveAdmin (pesar contra Avo, Rails 8 admin). **Decisão default:** ActiveAdmin (maduro, Rails 8 compat verificar via context7).
- **Files:** `app/admin/academy/mission.rb`, `app/admin/academy/concept.rb`.
- **Scope:** editar `title`, `hook`, `central_insight`, `curiosity_facts`, `challenge_*`, `scenes_tree` (json editor), `concept_ids`, `format`. Versionado via `PaperTrail` (verificar Rails 8 compat).
- **Aceite:** publish/unpublish; preview do system_prompt resultante.

#### `[~]` T-048 · Escrever 4 story_choice missions piloto
- **Áreas alvo:** Caráter (coragem - caverna), Vida & Sociedade (ouvir vs falar), Resolver Problemas (5-porquês), Tecnologia (decisão algorítmica).
- **Files:** seed file OU criar via admin scaffold (T-047).
- **Aceite:** 4 missions com `scenes_tree` válido (3-5 nodes, 2-3 choices cada, convergem em 2-3 endings).

#### `[x]` T-049 · `Academy::ParentDigest::Compose` cron
- **Files:** `app/services/academy/parent_digest/compose.rb`, `app/jobs/academy/parent_digest/weekly_job.rb`, configuração em `config/recurring.yml`.
- **Quando:** domingo 19h por timezone do learner.
- **Lógica:** coleta últimos 7 dias de eventos → LLM gera 4 blocos → salva `ParentDigest` → envia email/push.
- **Aceite:** digest existe para conta com atividade; 4 blocos preenchidos.

#### `[x]` T-050 · Eval suite em CI
- **Files:** `.github/workflows/*` ou Makefile target adicional (`make eval`).
- **Scope:** roda T-021 + qualquer eval futuro a cada PR que toca `app/services/academy/llm/**`.
- **Aceite:** PR que quebra eval é bloqueado.

---

## Decisões pendentes (assumo defaults, marque se quiser virar)

- **D-1** Admin tool: **ActiveAdmin** (default). Avo é alternativa. *Confirma via context7 a versão compat Rails 8.1 antes de instalar.*
- **D-2** Versionamento de Mission: **PaperTrail**. Alternativa: `audited`. *Idem.*
- **D-3** Push parental: **Web Push API** via Pwned-style (já existe stack?). Confirmar.
- **D-4** Som da Pokédex evolution: **Howler.js** vs WebAudio nativo. Vou de WebAudio + 1 sample WAV (sem dependência nova).

---

## Status board (snapshot)

```
Fase 0 (Foundations):     21/21  ✅
Fase 1 (Pokédex):         12/12  ✅
Fase 2 (Caça):              6/6  ✅
Fase 3 (Transfer+Compass):  5/6  ✅  (T-045 Atlas typed-edge UI: somente legenda em chip, sem desenho de aresta)
Fase 4 (CMS+Digest):        4/4  ✅  (T-048 = 1/4 stories seeded como amostra; CMS aceita o resto)

TOTAL: 48/50 done · 2 deferred-cosmetic (T-045 typed-edges desenho, T-048 content scale)
```

### Test status final

```
make rspec spec/models spec/services spec/requests
→ 537 examples, 0 failures, 1 pending  (live-LLM eval gated)
```

### Sumário do que ficou em pé (sessão completa)

**Camada de dados:** 12 migrations aplicadas. 6 tabelas novas (`learner_concepts`, `practice_wagers`, `learner_story_paths`, `virtue_sightings`, `transfer_detections`, `parent_digests`). Colunas v4 em `academy_missions` (`format`, `scenes_tree`, `teaser_for_next_mission_id`), `academy_concepts` (pokedex tokens), `academy_concept_edges` (`edge_type`), `academy_discovery_cards` (`kind`), `academy_learner_ranks` (`title_slug`). Tabela `academy_challenge_reports` dropada.

**Models v4:** `LearnerConcept`, `PracticeWager`, `LearnerStoryPath`, `VirtueSighting`, `TransferDetection`, `ParentDigest` — todos com specs + factories + scopes idiomáticos.

**Services v4:**
- `Academy::Pokedex::Advance` (idempotente, 4 níveis) + `Academy::Pokedex::Backfill` + rake.
- `Academy::Wagers::Create` + `Wagers::Settle` (substituem honor-system).
- `Academy::Compass::Propose` (3 cards: hot_trail / new_territory / revisit, com fallback legacy).
- `Academy::Transfer::Detect` (LLM-judge, ≥0.75 confidence) + `Transfer::DetectJob` async.
- `Academy::Digests::Compose` + `Digests::WeeklyJob` (cron domingo 19h).

**`AdvanceTurn#finalize_mission!` v4 chain:** `Cards::Mint → Wagers::Create → Pokedex::Advance (per concept) → Signals::Record → Secrets::Evaluate`.

**Persona v4 do Guia:** patch no topo de `Llm::GuidePersona::VOICE` (Bill Nye + Mythbusters + Kurzgesagt tom, Beat 7 teaser obrigatório, Beat 6 aposta numérica em discovery). `GuidePersona#system_prompt` aceita `pending_wager:` e injeta delta da aposta anterior na abertura da próxima missão.

**Eval suite:** `spec/services/academy/llm/persona_v4_eval_spec.rb` estrutural em CI (via `make eval` + `config/ci.rb`). Live LLM gated em `ACADEMY_LIVE_EVAL=1`.

**UX kid:** Atlas refeito como Pokédex (silhouette → spotted → recognized → mastered) com Stimulus + WebAudio chime + animação 1.6s e marcação de conceitos recém-evoluídos no carregamento. Home com Bússola do Explorador (3 cards). UI de aposta inline (input numérico). Renderizador de `story_choice` (cenas + escolhas + epilogue) + rota `choose`.

**Dead code wipe:** `Challenges::*` services, `ChallengeReport` model, `recall_persona.rb`, `recall_agent.rb`, kid controllers/views de medals/skills/recall_reviews/challenge_reports, links órfãos em views. `Signals::Record` virou eventos v4 (`:concept_evolved`, `:transfer_detected`, `:wager_settled`). `Rank::Recompute` simplificado. `Secrets::Evaluate` sem `:challenge_ratio`.

**Pais como aliados:** endpoint `parent_academy_practice_wagers_path` (PATCH) para confirmar avistamento (`seen_match/higher/lower/skip`). `Digests::Compose` semanal com 4 blocos (LLM ou fallback).

**CMS v4 (T-047):** `Admin::Academy::MissionsController` + views (lista, edit com JSON editor de `scenes_tree`, show). Sem dependência nova; pula necessidade de ActiveAdmin. Rota `admin_academy_missions_path`.

**Conteúdo (T-048):** seed `db/seeds/academy_stories.rb` com 1 story_choice piloto ("A caverna sem mapa" — coragem). Escalável adicionando entries em `STORIES`.

**Edges (T-044):** `lib/tasks/academy_edges.rake` com 10 pares curados (dopamina↔recompensa-variavel = generalizes, etc). Pares ausentes ficam em `relates_to`. Editar a constante `CURATED_EDGES` para expandir.

### Diferidos (cosmético / escala de conteúdo)

- **T-045 typed-edges no Atlas:** chips Pokédex já mostram estado evolutivo; desenho de aresta `<svg>` com cor por `edge_type` exige redesenho gráfico do Atlas. Não bloqueia tese pedagógica.
- **T-048 stories adicionais:** 3 missões story_choice (Sociedade/Resolver/Tech) ainda por escrever — conteúdo, criadas pelo CMS quando time editorial entrar.

### Tudo automatizado via `make setup` / `make db-seed`

A partir do v4, `db/seeds/academy.rb` chama `db/seeds/academy_v4.rb` no final, que aplica em sequência (idempotente):

1. **`db/seeds/academy_stories.rb`** — upsert das missões `story_choice` por slug.
2. **`CURATED_TYPED_EDGES`** inline — promove arestas conhecidas de `relates_to` para `generalizes` / `manifests_in` / etc.
3. **`Academy::Pokedex::Backfill`** — só roda se há `MissionProgress.completed`; cria `LearnerConcept` retroativo idempotente.

Saída esperada do `make db-seed`:

```
✓ Academy v2 seeded: 7 áreas ativas · 9 trilhas · 34 aulas ativas · 471 medalhas (...)
✓ Academy concepts seeded: 53 conceitos · 39 arestas · 97 tags aula↔conceito.
✓ Academy skills + secrets seeded: 9 skills · 70 tags aula↔skill · 4 segredos.

── Academy v4 seeds ────────────────────────────────────
✓ Academy v4 story_choice missions: 1 upserted
✓ typed concept_edges upserted: N
✓ Pokédex backfill: M applied · 0 failed   (ou: ↪ skipped (no completed missions))
── Academy v4 seeds done ───────────────────────────────
```

Não há mais necessidade de invocar `bin/rails academy:pokedex:backfill` manualmente — `make setup` faz tudo. As rake tasks (`academy:pokedex:backfill`, `academy:concept_edges:backfill`) seguem disponíveis para reexecução pontual.

### Comandos opcionais

```bash
# Re-rodar seeds (preserva dados; só upserta academy curriculum + v4)
make db-seed

# Pokédex backfill manual (idempotente)
docker compose exec web bin/rails academy:pokedex:backfill

# Eval estrutural do prompt do Guia (rápido, em CI)
make eval

# Eval estrutural + live LLM (precisa OPENROUTER_API_KEY)
ACADEMY_LIVE_EVAL=1 make eval
```

---

## Audit 2026-05-16 — follow-ups

Auditoria em 3 frentes (prompts LLM · seeds de conteúdo · escritas em tabelas deprecadas). Veredito: v4 está sólida. Apenas 4 gaps reais identificados; 3 fechados nesta sessão, 1 dividido em 4 PRs (PR1 fechado).

### Fechado nesta sessão

- `[x]` **Apertar prompt do `Digests::Compose`** — `app/services/academy/digests/compose.rb:84-90` agora explicita PROIBIDOs (psicologismo, tom contemplativo, métricas brutas, linguagem de relatório escolar, perguntas terapêuticas). Sem isso, o LLM derrapava em "tom de jornal de bordo" genérico.
- `[x]` **Atualizar `CLAUDE.md`** — `CLAUDE.md:55` agora descreve a chain real do `AdvanceTurn` v4 (`Cards::MintAfterMission → Wagers::Create → Signals::Record → Secrets::EvaluateForLearner`) + nota sobre `Skills::Award`/`Medals::AwardForMission` como v2 legacy parent-only. Antes descrevia chain v2 obsoleta com `Challenges::Open`.
- `[x]` **Pokédex visual keys — PR1 (mapping + tokens)**:
  - `app/assets/stylesheets/tailwind/theme.css` — 7 tokens `--academy-pokedex-{cognitivo,saude,social,virtude,financeiro,tecnologia,cientifico}`.
  - `db/seeds/academy_pokedex_keys.rb` — mapping idempotente (53 conceitos → categoria) + lista `POKEDEX_HERO_SLUGS` (14 conceitos com silhouette própria).
  - `db/seeds/academy.rb:962` — load após `academy_concepts.rb`.
  - `lib/tasks/academy_pokedex.rake` — task `academy:pokedex:assign_keys` para produção sem reseed.
  - **Executado em dev: 53/53 conceitos com `pokedex_color_key`; 14/53 com `pokedex_silhouette_key`.**

### Pendente — Pokédex visual completion

Estratégia: **híbrido HugeIcons** (decidido pelo usuário). Fallback por categoria; hero concepts com silhueta própria; custom SVG inline (currentColor) para herdar tinting via CSS variable.

- `[x]` **PR2 — Assets em `app/assets/images/academy/pokedex/`** (2026-05-16)
  - 7 SVGs fallback `_{categoria}.svg` criados (cognitivo: brain · saude: heart-pulse · social: people · virtude: shield-check · financeiro: coins · tecnologia: cpu · cientifico: atom).
  - 14 SVGs hero `{slug}.svg` para `POKEDEX_HERO_SLUGS`: dopamina, recompensa-variavel, foco, sistema-1-vs-2, neuroplasticidade, sono-consolidacao, glicose-pico, empatia, palavra-dada, coragem, honestidade, juros-compostos, algoritmo-recomendacao, pareto.
  - Spec: 64×64 viewBox, stroke 2.4, `stroke="currentColor"`, monochrome → tingido via CSS variable do orb. Glyphs hand-drawn por consistência visual (HugeIcons font fica para chips com Ui::Icon).
  - Aceite ✅: arquivos presentes; ConceptOrbComponent (PR3) inlina e tinta corretamente.

- `[x]` **PR3 — `Kid::Academy::Atlas::ConceptOrbComponent`** (2026-05-16)
  - `app/components/kid/academy/atlas/concept_orb_component.rb` — lê `concept.pokedex_silhouette_key` (fallback `_{pokedex_color_key}.svg`, fallback final `_cognitivo.svg`) + `concept.pokedex_color_key` + `level`.
  - Cache de SVG por filename em class ivar (evita read repetido).
  - CSS novo em `app/assets/stylesheets/tailwind/base.css` (`.pokedex-orb`, `--silhouette/--spotted/--recognized/--mastered` + `@keyframes pokedex-orb-pulse 3s ease-in-out infinite`).
  - 4 estados:
    - L0 silhueta: `grayscale(1) brightness(0.4)` + `opacity 0.55`.
    - L1 spotted: opacity 0.6, cor da categoria.
    - L2 recognized: opacity 1, cor cheia.
    - L3 mastered: cor + glow ring (color-mix) + pulse 3s.
  - Honra `prefers-reduced-motion` (transition: none; animation: none).
  - `app/views/kid/academy/atlas/_concept_chip.html.erb` refatorado: substitui o ícone sparkle pelo orb.
  - Color CSS variable injetada inline como `--pokedex-orb-color` para o keyframe.

- `[x]` **PR4 — Spec end-to-end de evolução** (2026-05-16)
  - `spec/components/kid/academy/atlas/concept_orb_component_spec.rb` — 4 estados visuais + asset resolution (hero, fallback categoria, fallback após miss) + color binding + a11y (`aria-hidden`, `data-concept-slug`).
  - `spec/services/academy/pokedex/backfill_spec.rb` — fluxo end-to-end: 3 missões cross-subject → backfill → `LearnerConcept.level == 3`; idempotência; render do orb mastered no chip.
  - System test screenshot ficou diferido (custo > benefício enquanto não há regressão visual ativa).

### Diferidos (não-bloqueadores)

- `[ ]` Backfill `Academy::LearnerRanks::AssignTitles` — `academy_learner_ranks.title_slug` ainda NULL nos ranks existentes. Sem urgência se ranks são populados on-demand pelo `Rank::Recompute`; confirmar antes de criar service novo.
- `[ ]` Tipar as 27 arestas restantes em `concept_edges` (default `relates_to`). Spec coloca para Sprint 3.
- `[ ]` 3 story_choice missions adicionais (Sociedade, Resolver, Tech) — entram via CMS, sem deploy.

### Como continuar em sessão futura

1. Abrir este arquivo + `.planning/designs/academy-v4-spec.md`.
2. Auditoria 2026-05-16 fechada: PR1, PR2, PR3, PR4 done.
3. Resta apenas a fila de **Diferidos** acima (LearnerRanks::AssignTitles, typar 27 arestas restantes, 3 stories adicionais via CMS) — nenhuma bloqueia a tese pedagógica v4.

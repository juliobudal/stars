# Academy v5 — Missões por Lentes · Task List

> Data: 2026-05-16
> Proposal: `openspec/changes/academy-v5-lens-missions/proposal.md`
> Diretiva do usuário: **clean refoundation, no backward compat**. Dead code é deletado, não deprecado. Paralelizar com agents quando independente. Revisar tudo que vier de agent.

## Legenda

- `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked
- **Par-group N**: tarefas dessa label rodam em paralelo entre si.
- **Dep**: tarefas que devem terminar antes.
- **Files**: caminhos absolutos relativos ao repo.
- **Verificação**: comandos `grep`/`rg` a rodar antes de deleção destrutiva.

## Decisões de produto (fixadas)

1. Unidade pedagógica = missão; **1 missão ↔ 1 conceito-foco** (cardinalidade 1:1).
2. Lentes são **geradas por LLM** com prompts altamente curados por tipo (sem autoria manual).
3. **Sistema** escolhe a ordem das lentes (serviço algorítmico); aprendiz não escolhe próximo.
4. Lentes estão **sempre presentes** (não há unlock-gate); revisita via Pokédex.
5. **Pontos parentais por aprender** → fora deste escopo (v5.1 ou v6).
6. v5 = **refundação limpa**; conteúdo v4 migrado por backfill, código v4 do chat **deletado**.

---

## Fase 0 — Foundations (migrations + dead-code wipe)

### Par-group A — Migrações destrutivas em `academy_missions` (sequenciadas entre si)

#### `[ ]` T-V5-001 · Add `concept_id` FK to `academy_missions`
- **Scope:** adicionar `concept_id bigint` FK → `academy_concepts(id)`, nullable inicialmente. Index simples.
- **Why:** missão 1:1 com conceito; substitui M:N de `academy_aula_concepts`.
- **Files:** `db/migrate/20260520000001_add_concept_id_to_academy_missions.rb`
- **Dep:** nenhuma.
- **Aceite:** `Academy::Mission.column_names.include?("concept_id")`; FK criada; coluna nullable.

#### `[ ]` T-V5-002 · Backfill `mission.concept_id` from primary `aula_concept`
- **Scope:** rake/migration data step. Para cada `Mission`, pega `aula_concepts.order(:weight desc).first` (ou primeiro conceito tagueado) e seta `concept_id`. Loga missões sem conceito-foco para curadoria.
- **Files:** `db/migrate/20260520000002_backfill_mission_concept_id.rb` (`disable_ddl_transaction!`).
- **Dep:** T-V5-001.
- **Aceite:** 100% das missions ativas com `concept_id` preenchido; missões sem concept ficam unpublished e logadas.

#### `[ ]` T-V5-003 · Make `mission.concept_id` NOT NULL
- **Scope:** alter column to `null: false`.
- **Files:** `db/migrate/20260520000003_require_mission_concept_id.rb`
- **Dep:** T-V5-002.
- **Aceite:** schema mostra `concept_id NOT NULL`; suite verde.

#### `[ ]` T-V5-004 · Drop dead columns from `academy_missions`
- **Scope:** dropar `format`, `scenes_tree`, `sessions_count`, `teaser_for_next_mission_id`.
- **Verificação:** `rg "mission\.(format|scenes_tree|sessions_count|teaser_for_next_mission_id)" app spec lib` precisa retornar zero **antes** desta migração rodar.
- **Files:** `db/migrate/20260520000004_drop_v4_columns_from_academy_missions.rb`
- **Dep:** T-V5-003, T-V5-031 (dead-code wipe que remove uso dessas colunas).
- **Aceite:** `schema.rb` sem as 4 colunas; `Academy::Mission` boota.

### Par-group B — Drop M:N table (dep da Fase 0 Par-group A)

#### `[ ]` T-V5-005 · Drop `academy_aula_concepts` table
- **Scope:** drop M:N (substituído por `mission.concept_id`). Reversal cria tabela vazia (não restaura dados).
- **Verificação:** `rg "AulaConcept|aula_concepts" app spec` → zero matches antes de aplicar.
- **Files:** `db/migrate/20260520000005_drop_academy_aula_concepts.rb`
- **Dep:** T-V5-003, T-V5-031.
- **Aceite:** tabela inexistente; specs verdes.

### Par-group C — Tabelas novas para lentes (independentes entre si)

#### `[ ]` T-V5-006 · Create `academy_lens_cache`
- **Scope:** cache global de lentes geradas por LLM. Colunas: `concept_id` FK, `lens_type` string, `age_band` string (`6-8|9-11|12-14`), `locale` string (`pt-BR`), `payload` jsonb, `generated_at`, `prompt_version` string, `model` string, `tokens_in`/`tokens_out` int.
- **Indexes:** unique `(concept_id, lens_type, age_band, locale, prompt_version)`; index em `lens_type`.
- **Files:** `db/migrate/20260520000006_create_academy_lens_cache.rb`
- **Dep:** nenhuma.
- **Aceite:** unique index criado; payload nullable false default `'{}'`.

#### `[ ]` T-V5-007 · Create `academy_learner_lens_visits`
- **Scope:** registro per-aprendiz-per-missão-per-lente. Colunas: `mission_progress_id` FK, `learner_id` FK, `concept_id` FK (denormalizado p/ query), `lens_type`, `lens_cache_id` FK (qual versão foi servida), `opened_at`, `completed_at`, `abandoned_at`, `signal_payload` jsonb (resultados de micro-checks), `legacy` bool default false.
- **Indexes:** `(mission_progress_id, lens_type)` unique parcial onde `legacy=false`; `(learner_id, opened_at)` para histórico.
- **Files:** `db/migrate/20260520000007_create_academy_learner_lens_visits.rb`
- **Aceite:** uma visita por (mission_progress, lens_type) salvo modo legacy.

#### `[ ]` T-V5-008 · Create `academy_lens_signals`
- **Scope:** stream append-only para o `ChooseNext` adaptativo. Colunas: `mission_progress_id` FK, `lens_visit_id` FK nullable, `learner_id` FK, `lens_type`, `signal_type` string (enum: `time_on_lens|micro_check_correct|micro_check_wrong|abandoned|self_report_easy|self_report_hard|transfer_hint`), `value` numeric (segundos, score, etc), `recorded_at`.
- **Indexes:** `(mission_progress_id, recorded_at)`; `(learner_id, signal_type, recorded_at)`.
- **Files:** `db/migrate/20260520000008_create_academy_lens_signals.rb`
- **Aceite:** insert puro (no update); migration cria a tabela com particionamento futuro em mente (índice já adequado).

### Par-group D — Dead-code wipe (independente das migrations, mas pré-requisito de T-V5-004/005)

#### `[ ]` T-V5-031 · Delete `Academy::AdvanceTurn` + `Academy::StartMission`
- **Scope:** services `app/services/academy/advance_turn.rb`, `app/services/academy/start_mission.rb` e specs correspondentes. Controllers que chamavam (`kid/academy/missions_controller#advance` e `#start`) também removem ação.
- **Verificação:** `rg "AdvanceTurn|StartMission" app spec` → confirmar que só caem em arquivos a serem deletados; quebras restantes apontam para refactor T-V5-050/051.
- **Files:** deletar `app/services/academy/advance_turn.rb`, `app/services/academy/start_mission.rb`, specs irmãos.
- **Dep:** nenhuma (mas T-V5-050/051 substituem o uso).
- **Aceite:** `rg AdvanceTurn` zero matches; app boota com controllers stub.

#### `[ ]` T-V5-032 · Delete `Academy::Llm::GuidePersona` + `Llm::GuideAgent`
- **Scope:** `app/services/academy/llm/guide_persona.rb`, `app/services/academy/llm/guide_agent.rb`, specs e fixtures.
- **Verificação:** `rg "GuidePersona|GuideAgent" app spec` → só nos próprios arquivos.
- **Files:** deletar os 2 services + specs.
- **Aceite:** suite carrega sem `NameError`.

#### `[ ]` T-V5-033 · Delete chat views (mission show + parciais)
- **Scope:** `app/views/kid/academy/missions/show.html.erb` (versão chat), parciais `_message.html.erb`, `_typing.html.erb`, `_composer.html.erb`, `_checkpoint*.html.erb`, `_next_session.html.erb`, `_wager.html.erb` (será reescrita como lens).
- **Verificação:** `rg "messages/_message\|_typing\|_composer\|_checkpoint" app/views` → após remoção, render referenciando-os falha em compile-time.
- **Files:** deletar arquivos acima.
- **Dep:** T-V5-031 (controller não pode mais renderizar essas partials).
- **Aceite:** `find app/views/kid/academy/missions -name '_*.html.erb'` retorna conjunto vazio ou só novos lens partials.

#### `[ ]` T-V5-034 · Delete Stimulus chat controllers
- **Scope:** `app/assets/controllers/academy_chat_controller.js` (e qualquer companion como `academy_typing_controller.js`).
- **Verificação:** `rg "academy-chat\|academy_chat" app` → vazio antes do delete.
- **Files:** deletar arquivos JS + qualquer registro em `app/assets/controllers/index.js` (auto-registrado, então só apagar).
- **Aceite:** Vite build sem warnings.

#### `[ ]` T-V5-035 · Delete persona v4 eval suite
- **Scope:** `spec/services/academy/llm/persona_v4_eval_spec.rb` + Makefile target `eval` se ele só rodava esse spec (renomear para `eval-v4-legacy` ou apagar).
- **Files:** delete spec; ajustar `Makefile` / `config/ci.rb`.
- **Dep:** T-V5-032.
- **Aceite:** `make eval` ou continua passando com novos specs (T-V5-080+) ou foi removido até reintroduction em Fase 7.

#### `[ ]` T-V5-036 · Review `Academy::Cards::MintAfterMission` (KEEP)
- **Scope:** auditar uso; missão completa ainda deve cunhar discovery card. Manter mas confirmar invariante (`mission_progress.completed_at` presente).
- **Files:** `app/services/academy/cards/mint_after_mission.rb`, spec.
- **Aceite:** spec dedicado roda contra novo lifecycle (chamado por `Mission::Finalize` em T-V5-054).

#### `[ ]` T-V5-037 · Review `Academy::Llm::Parser` (delete if unused)
- **Verificação:** `rg "Llm::Parser" app spec`. Se única referência for em `GuidePersona`/`AdvanceTurn` já deletados, remover.
- **Files:** `app/services/academy/llm/parser.rb` (deletar se órfão).
- **Dep:** T-V5-031, T-V5-032.
- **Aceite:** `rg Llm::Parser` zero matches OU spec ainda passa com novo consumidor.

#### `[ ]` T-V5-038 · Cleanup factories/specs órfãos
- **Scope:** após T-V5-031..037, varrer `spec/factories/academy/` e `spec/services/academy/` por arquivos referenciando constantes mortas.
- **Files:** ajustes pontuais.
- **Dep:** T-V5-031..037.
- **Aceite:** `bundle exec rspec --dry-run` sem `NameError`.

---

## Fase 1 — Lens catalog + generation pipeline

### Par-group E — Catalog + schemas (independente)

#### `[ ]` T-V5-040 · `Academy::Lens::Catalog` constant
- **Scope:** módulo com hash congelado `TYPES = { scientific: { ui_primitive: :predict_reveal, prompt_template: "scientific.md.erb", schema: "scientific.json" }, narrative: {...}, ... }`. 8 tipos: `scientific`, `narrative`, `ethical`, `statistical`, `engineering`, `historical`, `first_person`, `analogy_bridge`.
- **Files:** `app/services/academy/lens/catalog.rb`, spec.
- **Dep:** nenhuma.
- **Aceite:** `Catalog.types` retorna 8 símbolos; `Catalog.fetch(:scientific)` retorna struct com ui_primitive + paths.

#### `[ ]` T-V5-041 · JSON output schemas per lens type (8 files)
- **Scope:** schemas JSON Schema draft-7 que validam payload retornado pela LLM por tipo (e.g. `scientific` exige `prediction_prompt`, `reveal_text`, `micro_check { prompt, options[], correct_index }`).
- **Files:** `app/services/academy/lens/schemas/{scientific,narrative,ethical,statistical,engineering,historical,first_person,analogy_bridge}.json`.
- **Dep:** T-V5-040.
- **Aceite:** cada schema valida 1 fixture canônico; spec roda `JSON::Validator.fully_validate`.

### Par-group F — Prompt templates (independente, par com E)

#### `[ ]` T-V5-042 · Prompt template — `scientific.md.erb`
- **Scope:** template ERB com instruções para gerar lente de predição→revelação científica. Inputs: `concept`, `learner_name`, `age_band`, `locale`. Output: JSON aderente ao schema.
- **Files:** `app/services/academy/lens/prompts/scientific.md.erb`.
- **Aceite:** template renderiza com fixture sem erro; LLM gera output válido ≥80% em eval estrutural T-V5-080.

#### `[ ]` T-V5-043 · Prompt template — `narrative.md.erb`
- **Files:** `app/services/academy/lens/prompts/narrative.md.erb`.
- **Aceite:** idem.

#### `[ ]` T-V5-044 · Prompt template — `ethical.md.erb`
- **Files:** `app/services/academy/lens/prompts/ethical.md.erb`.

#### `[ ]` T-V5-045 · Prompt template — `statistical.md.erb`
- **Files:** `app/services/academy/lens/prompts/statistical.md.erb`.

#### `[ ]` T-V5-046 · Prompt template — `engineering.md.erb`
- **Files:** `app/services/academy/lens/prompts/engineering.md.erb`.

#### `[ ]` T-V5-047 · Prompt template — `historical.md.erb`
- **Files:** `app/services/academy/lens/prompts/historical.md.erb`.

#### `[ ]` T-V5-048 · Prompt template — `first_person.md.erb`
- **Files:** `app/services/academy/lens/prompts/first_person.md.erb`.

#### `[ ]` T-V5-049 · Prompt template — `analogy_bridge.md.erb`
- **Files:** `app/services/academy/lens/prompts/analogy_bridge.md.erb`.

### Par-group G — Generators (dep: E + F)

#### `[ ]` T-V5-050 · `Academy::Lens::Generators::Base`
- **Scope:** classe abstrata com `#call`: monta prompt via template do Catalog, chama `Academy::Llm::Client`, parseia JSON, valida contra schema, retorna payload. Falha → `Result.fail_with(:llm_invalid_output)`.
- **Files:** `app/services/academy/lens/generators/base.rb`, spec.
- **Dep:** T-V5-040, T-V5-041.
- **Aceite:** spec com mock LLM cobre happy path + 3 erros (timeout, JSON inválido, schema fail).

#### `[ ]` T-V5-051 · Generators subclasses (8 tipos)
- **Scope:** 1 classe por tipo herdando `Base`, indicando `lens_type` e overrides mínimos (tweak de parsing se necessário). Maioria é só `class Scientific < Base; self.lens_type = :scientific; end`.
- **Files:** `app/services/academy/lens/generators/{scientific,narrative,ethical,statistical,engineering,historical,first_person,analogy_bridge}.rb` + spec curto cada.
- **Dep:** T-V5-050.
- **Aceite:** `Catalog.types.each { |t| Generators.for(t) }` instancia tudo.

### Par-group H — Cache + entry-point (dep: G + T-V5-006)

#### `[ ]` T-V5-052 · `Academy::Lens::Generate` (cache-aware entry point)
- **Scope:** `Generate.call(concept:, lens_type:, age_band:, locale:)`. Lookup em `LensCache` por chave unique; hit → retorna cached `payload`; miss → chama generator → grava em cache → retorna.
- **Files:** `app/services/academy/lens/generate.rb`, spec (mock generator + cache hit/miss).
- **Dep:** T-V5-006, T-V5-051.
- **Aceite:** segunda chamada com mesmos args **não invoca LLM** (asserção via spy).

#### `[ ]` T-V5-053 · `Academy::Lens::WarmCacheJob`
- **Scope:** job idempotente; pega N aprendizes ativos (últimos 7 dias) → para cada, próximas missões prováveis (top-3 do `Compass` ou trilha ativa) → para cada concept-foco, gera todas as 8 lentes em cache se ausentes. Throttle: ≤ 50 LLM calls / job run.
- **Files:** `app/jobs/academy/lens/warm_cache_job.rb`, spec; entry em `config/recurring.yml` (nightly 03:00).
- **Dep:** T-V5-052.
- **Aceite:** rodar manualmente popula cache para conceitos esperados; respeita throttle.

---

## Fase 2 — Ordering service

#### `[ ]` T-V5-060 · `Academy::Lens::ChooseNext` service
- **Scope:** entrada: `mission_progress` (com histórico de `learner_lens_visits` + `lens_signals`); saída: `{ lens_type:, payload: }` ou `{ done: true }`. Heurística:
  - opener: **concreto-first** (preferir `first_person` ou `narrative`);
  - regra de variedade: nunca repetir mesmo tipo consecutivo;
  - regra de cobertura: minimum 4 tipos distintos antes de `done`;
  - regra de cap: máximo 7 lentes na missão;
  - transfer-closer: última lente preferencialmente `analogy_bridge` ou `historical`;
  - adaptação: se ≥2 sinais `micro_check_wrong` consecutivos, intercala `analogy_bridge` antes do próximo conceito formal.
- **Files:** `app/services/academy/lens/choose_next.rb`, spec.
- **Dep:** T-V5-007, T-V5-008, T-V5-052.
- **Aceite:** spec com 8 cenários determinísticos cobre todas as regras acima.

#### `[ ]` T-V5-061 · `Academy::Lens::ScoreVisit` service
- **Scope:** ao fechar uma visit, calcula sinais e insere em `lens_signals`: `time_on_lens` (segundos), `micro_check_correct/wrong` (se aplicável), `abandoned` (sem `completed_at` > 5min). Salva `signal_payload` na visit.
- **Files:** `app/services/academy/lens/score_visit.rb`, spec.
- **Dep:** T-V5-007, T-V5-008.
- **Aceite:** spec gera signals esperados para 3 cenários (rápido-correto, lento-correto, abandonado).

#### `[ ]` T-V5-062 · Ordering integration spec (state-based)
- **Scope:** spec end-to-end: dado um learner sintético e um concept, simula 7 visits chamando `ChooseNext` → `ScoreVisit` em loop, asserta sequência de lens_types corresponde ao planejado.
- **Files:** `spec/services/academy/lens/ordering_integration_spec.rb`.
- **Dep:** T-V5-060, T-V5-061.
- **Aceite:** sequência determinística; sem flakiness; ≤ 200ms.

---

## Fase 3 — Mission lifecycle services

#### `[ ]` T-V5-070 · `Academy::Mission::Begin`
- **Scope:** substitui `StartMission`. Inputs: `learner, mission`. Cria `MissionProgress` (idempotente — retorna existente se ativo). Chama `Lens::ChooseNext` para materializar primeira lente; cria `LearnerLensVisit` aberta. Retorna `{ progress, lens }`.
- **Files:** `app/services/academy/mission/begin.rb`, spec.
- **Dep:** T-V5-007, T-V5-060.
- **Aceite:** chamada dupla não cria 2 progresses; primeira visit aberta com `opened_at`.

#### `[ ]` T-V5-071 · `Academy::Mission::AdvanceLens`
- **Scope:** substitui `AdvanceTurn`. Fecha visit atual via `ScoreVisit`; chama `ChooseNext`; se `done: true` → invoca `Mission::Finalize`; senão cria nova visit aberta. Retorna `{ lens: }` ou `{ mission_complete: true }`. Transacional.
- **Files:** `app/services/academy/mission/advance_lens.rb`, spec.
- **Dep:** T-V5-060, T-V5-061, T-V5-073.
- **Aceite:** spec cobre 3 caminhos (advance, complete, idempotent on already-closed visit).

#### `[ ]` T-V5-072 · `Academy::Mission::Finalize` chain
- **Scope:** orquestrador (substitui `AdvanceTurn#finalize_mission!`). Ordem fixa:
  1. `DiscoveryCards::MintAfterMission`
  2. `Pokedex::Advance` (com novo ladder — ver T-V5-075)
  3. `Signals::Record` (`:mission_completed`)
  4. `Digests::AccumulateWeek` (incremento em buffer semanal)
  5. `Secrets::EvaluateForLearner` (último: lê estado pós-passos)
- **Files:** `app/services/academy/mission/finalize.rb`, spec.
- **Dep:** T-V5-036, T-V5-075.
- **Aceite:** ordem observável via spy; transação única; rollback se qualquer passo falhar.

#### `[ ]` T-V5-073 · Wire controller `kid/academy/missions_controller`
- **Scope:** ações `start` → chama `Mission::Begin`; `advance` → chama `Mission::AdvanceLens`. Render Turbo Stream com novo lens stage.
- **Files:** `app/controllers/kid/academy/missions_controller.rb`, request specs.
- **Dep:** T-V5-070, T-V5-071, T-V5-090 (view).
- **Aceite:** request spec: POST `/kid/academy/missions/:id/start` retorna 200 com lens render; POST `/advance` avança ou finaliza.

---

## Fase 4 — UI: lens stages

### Par-group I — Shared scaffolding (dep: T-V5-073)

#### `[ ]` T-V5-090 · Layout `_lens_stage.html.erb`
- **Scope:** novo parcial unificado para mission show. Renderiza header com `Lens::ProgressRing` (visited / current / locked counters), então delega para parcial específico por `lens.type`.
- **Files:** `app/views/kid/academy/missions/_lens_stage.html.erb`, `app/views/kid/academy/missions/show.html.erb` (reescrito).
- **Dep:** T-V5-033 (chat views deletadas).
- **Aceite:** sem referência a `_message`, `_composer` etc.

#### `[ ]` T-V5-091 · `Kid::Academy::LensProgressRingComponent`
- **Scope:** ViewComponent que mostra anel de N pontos (lentes visitadas em cor cheia, atual em destaque pulsante, restantes em outline). Honra `prefers-reduced-motion`.
- **Files:** `app/components/kid/academy/lens_progress_ring_component.rb` + sidecar.
- **Aceite:** spec de componente cobre 3 estados; design tokens via CSS vars.

### Par-group J — Per-type partials (independentes, dep de I)

#### `[ ]` T-V5-092 · `_lens_predict.html.erb` (scientific UI primitive)
- **Files:** `app/views/kid/academy/missions/_lens_predict.html.erb`.
- **Aceite:** input de palpite → reveal animado → micro_check.

#### `[ ]` T-V5-093 · `_lens_narrative.html.erb`
- **Files:** idem.

#### `[ ]` T-V5-094 · `_lens_compare.html.erb` (statistical / ethical compare cases)
- **Files:** idem.

#### `[ ]` T-V5-095 · `_lens_reconstruct.html.erb` (engineering / historical sequencing)
- **Files:** idem.

#### `[ ]` T-V5-096 · `_lens_pattern_hunt.html.erb` (analogy_bridge — 3 scenes)
- **Files:** idem.

#### `[ ]` T-V5-097 · `_lens_teach_back.html.erb` (first_person teach-Téo)
- **Files:** idem.

#### `[ ]` T-V5-098 · `_lens_historical.html.erb`
- **Files:** idem.

#### `[ ]` T-V5-099 · `_lens_ethical_choice.html.erb`
- **Files:** idem.

### Par-group K — Stimulus controllers per primitive (dep de J)

#### `[ ]` T-V5-100 · `lens_predict_controller.js`
- **Files:** `app/assets/controllers/lens_predict_controller.js`.
- **Aceite:** captura palpite, reveals com timing, dispara micro_check; envia advance via Turbo.

#### `[ ]` T-V5-101 · `lens_reconstruct_controller.js`
- **Files:** `app/assets/controllers/lens_reconstruct_controller.js`.

#### `[ ]` T-V5-102 · `lens_pattern_hunt_controller.js`
- **Files:** `app/assets/controllers/lens_pattern_hunt_controller.js`.

#### `[ ]` T-V5-103 · `lens_teach_back_controller.js`
- **Files:** `app/assets/controllers/lens_teach_back_controller.js`.

#### `[ ]` T-V5-104 · `lens_ethical_choice_controller.js`
- **Files:** `app/assets/controllers/lens_ethical_choice_controller.js`.

#### `[ ]` T-V5-105 · DESIGN.md — capítulo "Lentes"
- **Scope:** documentar tokens, motion contract, ui primitives. Deferido para final da Fase 4 (após estabilizar partials).
- **Files:** `DESIGN.md`.
- **Dep:** T-V5-090..104.
- **Aceite:** seção nova com inventário e do/don't.

---

## Fase 5 — Pokédex v5 ladder

#### `[ ]` T-V5-075 · `Academy::Pokedex::Advance` revisado
- **Scope:** reescrever lógica de níveis:
  - **L1** = uma lente visitada (qualquer tipo).
  - **L2** = missão completa (jornada de lentes fechada — pelo menos 4 tipos distintos no mesmo conceito, dentro de UMA missão).
  - **L3** = conceito visto em 2+ missões de áreas diferentes (transferência confirmada).
- **Files:** `app/services/academy/pokedex/advance.rb`, spec.
- **Dep:** T-V5-007.
- **Aceite:** spec cobre 4 transições (0→1, 1→2, 2→3 cross-area, idempotência).

#### `[ ]` T-V5-076 · Rake `academy:pokedex:reladder`
- **Scope:** re-deriva `LearnerConcept` rows pelo novo ladder a partir de `LearnerLensVisits` + `MissionProgress` históricos. Idempotente.
- **Files:** `lib/tasks/academy_pokedex.rake` (extender).
- **Dep:** T-V5-075, T-V5-115 (backfill de visits).
- **Aceite:** rodar produz contagem de updates; segunda run reporta 0 mudanças.

#### `[ ]` T-V5-077 · Pokédex Atlas — labels/counters
- **Scope:** atualizar `app/views/kid/academy/atlas/` para refletir ladder v5 (textos: "lente visitada" / "missão completa" / "transferência").
- **Files:** `app/views/kid/academy/atlas/_concept_chip.html.erb`, `index.html.erb`.
- **Dep:** T-V5-075.
- **Aceite:** kid vê labels novos; orb states intactos.

---

## Fase 6 — Content migration v4 → v5

#### `[ ]` T-V5-110 · Rake `academy:v5:migrate_missions`
- **Scope:** wrapper que combina T-V5-001/002/004 em comando único para staging. Para cada mission existente: garante `concept_id` setado (já feito por backfill), descarta dados em `format/scenes_tree/sessions_count` (no-op pós-drop).
- **Files:** `lib/tasks/academy_v5.rake`.
- **Dep:** T-V5-004.
- **Aceite:** rodar em staging idempotente; relatório por slug.

#### `[ ]` T-V5-111 · Archive v4 chat sessions
- **Scope:** `Academy::Session` marcado `active: false` (adicionar coluna se ausente). Não renderizados em kid UI. Mantidos para auditoria histórica.
- **Files:** migration `db/migrate/20260520000010_add_active_to_academy_sessions.rb`; service `app/services/academy/sessions/archive_v4.rb`.
- **Aceite:** todas sessions pré-v5 com `active=false`; rota kid/missions/show não consulta sessions.

#### `[ ]` T-V5-112 · Decision: keep `academy_practice_wagers` as lens type (Predict→Reveal)
- **Scope:** sem migration; documentar em `docs/academy-v2.md` que wagers viraram payload interno de lente `scientific`. Hooks novos via `Mission::Finalize`.
- **Files:** docs + service `Academy::Wagers::Create` recableado em T-V5-072 (chamado somente se lens.type == scientific).
- **Aceite:** nenhuma referência a `Wagers::Create` fora de `Mission::*` ou lens generators.

#### `[ ]` T-V5-113 · Decision: keep `academy_learner_story_paths` (lens internal state)
- **Scope:** vira estado interno da lente `narrative` quando precisar de bifurcação. Documentar.
- **Files:** docs.
- **Aceite:** model permanece; sem novo controller.

#### `[ ]` T-V5-114 · Keep `virtue_sightings` + `transfer_detections`
- **Scope:** confirmar que `Transfer::DetectJob` continua sendo gatilho para L3 (T-V5-075). Sem mudança de schema.
- **Files:** revisar `app/jobs/academy/transfer/detect_job.rb` para usar `LearnerLensVisit` em vez de `Message` como gatilho.
- **Dep:** T-V5-007.
- **Aceite:** job dispara em `after_commit` de `LearnerLensVisit#completed_at` quando lens_type == `analogy_bridge` (heurística inicial).

#### `[ ]` T-V5-115 · Backfill `learner_lens_visits` from session history (best-effort)
- **Scope:** rake `academy:v5:backfill_visits`. Para cada `MissionProgress` legado, sintetiza 1 visit por mensagem-checkpoint detectável; marca `legacy: true`. Sem fidelidade alta — só preserva ladder L1 retroativo.
- **Files:** `lib/tasks/academy_v5.rake` (extender).
- **Dep:** T-V5-007, T-V5-111.
- **Aceite:** rodar em staging produz N visits legacy; `Pokedex::reladder` (T-V5-076) usa-as.

---

## Fase 7 — Eval suite + observability

### Par-group L — Per-type eval specs (independentes)

#### `[ ]` T-V5-080 · Eval — `scientific` lens
- **Scope:** spec estrutural valida output contra schema; spec live (gated `ACADEMY_LIVE_EVAL=1`) chama OpenRouter e checa 10 fixtures.
- **Files:** `spec/services/academy/lens/generators/scientific_eval_spec.rb`.
- **Dep:** T-V5-051.
- **Aceite:** estrutural sempre passa; live passa ≥80%.

#### `[ ]` T-V5-081 · Eval — `narrative` lens
- **Files:** `spec/services/academy/lens/generators/narrative_eval_spec.rb`.

#### `[ ]` T-V5-082 · Eval — `ethical` lens
- **Files:** idem.

#### `[ ]` T-V5-083 · Eval — `statistical` lens
- **Files:** idem.

#### `[ ]` T-V5-084 · Eval — `engineering` lens
- **Files:** idem.

#### `[ ]` T-V5-085 · Eval — `historical` lens
- **Files:** idem.

#### `[ ]` T-V5-086 · Eval — `first_person` lens
- **Files:** idem.

#### `[ ]` T-V5-087 · Eval — `analogy_bridge` lens
- **Files:** idem.

### Par-group M — Integration + ops (dep de L)

#### `[ ]` T-V5-088 · Integration eval — full mission journey
- **Scope:** spec end-to-end: aprendiz sintético inicia missão → simula 5-7 advances → `Mission::Finalize` chamado → `Pokedex::Advance` atinge L2 → asserta cards/digests/signals.
- **Files:** `spec/services/academy/mission/full_journey_eval_spec.rb`.
- **Dep:** T-V5-072, T-V5-075.
- **Aceite:** cobre happy path completo em < 2s (mock LLM).

#### `[ ]` T-V5-089 · Quality dashboard
- **Scope:** `app/controllers/parent/academy/quality_metrics_controller.rb` (admin-gated). Métricas: lens generation success rate (cache hit %), avg tokens/lens, abandonment rate por tipo, avg lens journey length, top-10 conceitos com mais L2/L3.
- **Files:** controller + view + spec.
- **Aceite:** view renderiza com seed mínimo; gated por `current_profile&.parent? && admin?`.

#### `[ ]` T-V5-089b · `make eval-v5` target
- **Scope:** Makefile target que roda evals estruturais (Par-group L) sem live LLM; alias para CI.
- **Files:** `Makefile`, `config/ci.rb`.
- **Aceite:** `make eval-v5` exit 0 em CI sem `OPENROUTER_API_KEY`.

---

## Fase 8 — Parent surfaces

#### `[ ]` T-V5-120 · Parent digest revamp — `Digests::Compose` prompt v5
- **Scope:** narrar lentes visitadas em vez de checkpoints. Inputs novos: `LearnerLensVisits` agregados por concept + tipos atravessados. Prompt menciona "ângulos explorados".
- **Files:** `app/services/academy/digests/compose.rb` (reescrita do prompt).
- **Dep:** T-V5-007.
- **Aceite:** eval estrutural cobre 3 cenários (semana cheia / semana esparsa / nenhuma atividade).

#### `[ ]` T-V5-121 · Parent dashboard — "Últimas missões e ângulos"
- **Scope:** read-only view listando últimas N missões do kid com chips de lens_types visitados.
- **Files:** `app/controllers/parent/academy/journeys_controller.rb` + view + spec.
- **Dep:** T-V5-007.
- **Aceite:** kid sem atividade → empty state; com atividade → cards por missão.

---

## Fase 9 — Admin / CMS

#### `[ ]` T-V5-130 · Admin override de lens gerada
- **Scope:** controller admin para listar lentes geradas (lens_cache) por concept × type; editor JSON do payload; salva nova linha (versionada por `prompt_version` ou `edited_by`).
- **Files:** `app/controllers/admin/academy/lenses_controller.rb` + views + spec.
- **Dep:** T-V5-006.
- **Aceite:** admin edita; próxima requisição de aprendiz serve override.

#### `[ ]` T-V5-131 · "Regenerate lens" button
- **Scope:** botão na admin que invalida cache (`destroy` row) e chama `Lens::Generate` síncrono.
- **Files:** ação no controller acima.
- **Aceite:** após click, nova `lens_cache` row criada com `generated_at` novo.

#### `[ ]` T-V5-132 · Quality flagging
- **Scope:** admin pode flaggar lente como `quality_flagged: true` (adicionar coluna em `academy_lens_cache`). Lentes flagged não são servidas; geram alerta no quality dashboard.
- **Files:** migration `db/migrate/20260520000020_add_quality_flagged_to_lens_cache.rb`; controller action.
- **Dep:** T-V5-006, T-V5-089.
- **Aceite:** flagged lens é ignorada por `Lens::Generate` lookup; dashboard mostra contador.

---

## Cross-phase dependencies (resumo)

```
Fase 0 (A) → Fase 0 (B): drops dependem do dead-code wipe (Par-group D)
Fase 0 (C: tabelas novas) → Fase 1 (cache), Fase 2 (signals/visits), Fase 3 (lifecycle)
Fase 1 (E+F+G+H) → Fase 2 (ChooseNext consome Generate)
Fase 2 → Fase 3 (Mission::Begin/AdvanceLens dependem de ChooseNext)
Fase 3 → Fase 4 (controller wire + views)
Fase 3 → Fase 5 (Finalize chama Pokedex::Advance v5)
Fase 6 (migration) depende de toda Fase 0 + Fase 5
Fase 7 evals dependem de Fase 1 (generators) + Fase 3 (lifecycle)
Fase 8 depende de Fase 3 (visits existem)
Fase 9 depende de Fase 1 (cache table)
```

Maior cadeia: **T-V5-001 → 002 → 003 → 004 → 031 → 040 → 051 → 052 → 060 → 071 → 072 → 075 → 088** (foundations → catalog → generators → cache → ordering → lifecycle → ladder → integration eval).

---

## Status board (snapshot)

```
Fase 0 (Foundations + wipe):    0/14
Fase 1 (Lens catalog + gen):    0/14
Fase 2 (Ordering):              0/3
Fase 3 (Mission lifecycle):     0/4
Fase 4 (UI lens stages):        0/16
Fase 5 (Pokédex v5 ladder):     0/3
Fase 6 (Content migration):     0/6
Fase 7 (Eval + observability):  0/11
Fase 8 (Parent surfaces):       0/2
Fase 9 (Admin / CMS):           0/3

TOTAL: 0/76
```

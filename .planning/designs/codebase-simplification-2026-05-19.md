# Codebase Simplification — Pós-Curated-Static Pivot

**Data:** 2026-05-19
**Branch base:** `feat/academy-lens-v3-completion` (após cleanup completo da Fase D)
**Contexto:** depois de retirar a pipeline LLM de geração de lente (8 generators, prompts, judge, jobs, 10 colunas de cache), uma varredura mais funda revela vasta vestígio de features v2/v3/v4 que foram parcialmente implementadas e nunca atingiram o usuário. Este doc lista o que deletar/encolher, com evidência concreta.

---

## TL;DR

**~50 arquivos / 8 tabelas / 6 services / 3 jobs / 2 entradas de cron / 25+ ViewComponents podem sair em 1-2 sessões**, sem afetar nenhum caminho que o kid ou parent atualmente vê. As evidências são (a) `grep` zero-caller no código vivo + (b) `count == 0` no DB de dev.

Após isso o projeto fica MUITO mais legível: somem features-zumbi (skills/medals/ranks/digests/recall) que tinham models, services, jobs e até cron — tudo a serviço de zero linhas no DB.

---

## Hard Data (DB dev, contagem real)

| Tabela | Linhas | Status |
|---|---:|---|
| `academy_learner_skills` (score > 0) | **0** | Radar de habilidades é sempre zero |
| `academy_practice_wagers` | **0** | Mecânica de aposta nunca disparou |
| `academy_transfer_detections` | 0 | (depende da OPENROUTER_API_KEY — não-falha) |
| `academy_virtue_sightings` | **0** | Tabela write-never |
| `academy_learner_ranks` | **0** | Ranks zerados |
| `academy_parent_digests` | **0** | Job semanal nunca gerou row |
| `academy_recall_reviews` | 1 | Seed-only, kid não vê |
| `academy_medal_awards` | **0** | 89 medals cadastradas, 0 awards |
| `global_task_assignments` | 41 | **VIVO** — não tocar |
| `academy_lens_signals` | 51 | Usado por `ChooseNext` (vai encolher) |

---

## Tier 1 — Safe Deletes (zero callers + zero rows)

Cada item abaixo tem `grep` zero-callers fora do próprio diretório + zero linhas no DB. Pode ir em UM commit, sem teste manual em staging.

### 1.1 Skills (chain morto)

- `Academy::Skills::Award` — não invocado em `Missions::Finalize` nem em controllers
- `Academy::LearnerSkill` + `Academy::AulaSkill` + `Academy::Skill` (3 models + tabelas)
- 9-skill radar em `parent/academy/dashboard/index.html.erb` — remover (sempre zero)
- Spec correspondentes

### 1.2 Ranks (dependia de Skills)

- `Academy::Rank::Recompute` — única caller era `Skills::Award`
- `Academy::LearnerRank` model + tabela
- Render de `@rank_record` em kid/parent views já tem fallback `nil`-friendly — remover as 4 linhas

### 1.3 Medals (legado v2 read-only do parent)

- `Academy::Medals::AwardForMission` — não está no chain de Finalize
- `Academy::Medal` + `Academy::MedalAward` + 2 tabelas (89 medals cadastradas, 0 awarded — confirma desuso)
- Subject#medals association

### 1.4 ParentDigest + cron

- `Academy::Digests::WeeklyJob` (Sundays 19:00 em `config/recurring.yml`)
- `Academy::Digests::Compose`
- `Academy::ParentDigest` model + tabela
- Sem nenhum controller/view leitor → email/digest nunca apareceu

### 1.5 VirtueSighting

- `Academy::VirtueSighting` model + tabela
- Único leitor é `Digests::Compose` (deletado acima); nenhum writer

### 1.6 Recall (spaced repetition kid-invisível)

- `Academy::RecallReminderJob` + cron entry
- `Academy::Recall::*` (Reschedule e outros)
- `Academy::RecallReview` model + tabela (1 row seed)
- Kid nunca viu recall — sem UI

### 1.7 Wagers::Create (stub explícito)

- `app/services/academy/wagers/create.rb` — comentário do próprio arquivo admite "transitional stub… no-ops safely"
- Não chamado de `Missions::Finalize`
- `PracticeWager` model: kept (tabela existe, 0 rows, mas o UI block "Apostas em aberto" segue renderizado — decisão produto, mas pode ir junto se confirmar com você)

### 1.8 UI Components zero-ref (host app, 6 components)

- `app/components/ui/activity_row/`
- `app/components/ui/balance_chip/`
- `app/components/ui/kid_avatar/`
- `app/components/ui/kid_initial_chip/`
- `app/components/ui/profile_card/`
- `app/components/ui/star_badge/`

Confirmado: zero refs em qualquer view/controller/component externo aos próprios arquivos.

### 1.9 Helpers órfãos

- `app/helpers/component_docs_helper.rb`
- `app/helpers/kit_docs_helper.rb`
- `app/helpers/meta_tags_helper.rb`

Confirmado: rota `/docs` / `/kit` / `/styleguide` não existe em `config/routes.rb`. Foram do styleguide do tema antigo (Berry Pop, retirado).

### 1.10 Job órfão

- `app/jobs/star_decay_job.rb` + spec — sem cron, sem caller, nada no `.planning/`

### 1.11 Stimulus controller stale

- `app/assets/controllers/bulk_select_controller.js`
- Limpar `data-bulk-select-target` e `data-action="change->bulk-select#change"` em `ui/approval_row/component.html.erb` (nenhum ancestor registra `data-controller="bulk-select"`)

### 1.12 Ui::Header / Ui::Stat subtrees

- `app/components/ui/header/` (5 arquivos: component + 4 slots)
- `app/components/ui/stat/` (5 arquivos: component + 4 slots)

Confirmado: zero refs externas. Substituídos por `Ui::PageHeader` e `Ui::StatCard` / `Ui::StatMetric`.

**Estimativa Tier 1:** ~40 arquivos · ~2.500 LOC · 8 migrations (drop tables)

---

## Tier 2 — Shrinks (refactor, não delete)

### 2.1 `Academy::Lens::ChooseNext` — heurística super-engineered

Hoje: `HARD_CAP`, `COVERAGE_FLOOR`, `CONCRETE_OPENERS`, `ABSTRACT_LENSES`, `CLOSURE_LENSES`, rotation aware de mastery_tier + wrong_streak + signals.

**Justificativa pra existir era** o LLM cache shardado por mastery_tier e a possibilidade de rotação infinita com lens gen on-demand. Agora cada conceito tem ~3 lens types curados (`narrative` + `scientific` + `statistical` na maioria) — a "rotação" é literalmente `curated_set - visited`.

**Encolher para ~20 LOC:**
```ruby
def call
  visited = closed_visit_types(@progress)
  curated = curated_types_for(@progress.mission.concept_id)
  next_type = (curated - visited).first || force_closure_type
  next_type.nil? ? done(:exhausted) : open(next_type)
end
```

Mantém o conceito de closure-eligible types e o `HARD_CAP=visit_count_per_mission`, mas vai de ~250 LOC para ~50.

### 2.2 `Lens::LearnerContext.mastery_tier` bucket

A abstração `any/introductory/advanced` era pra dividir o LLM cache. Como `LensCache` não tem mais `mastery_tier` (migration anterior dropou a coluna), o bucket só sobrevive como string consumida pelo `BuildPrompt`.

**Simplificar:** trocar pelo `level` cru (int 0-3). `BuildPrompt#learner_state_block` faz o `case` direto. Remove `MASTERY_TIERS` constant e o `difficulty_hint`/`adaptive_hint` methods (não-callados).

### 2.3 `Lens::ScoreVisit` + `LensSignal` (51 rows mas só ChooseNext lê)

Após o shrink de 2.1, `LensSignal` deixa de ser usado. Único valor que importa pra `Pokedex::Advance` é `micro_check_correct` — que já vem em `LearnerLensVisit.signal_payload` JSONB.

**Consolidar:** mover lógica de bump-pokedex pro `Missions::AdvanceLens#after_close_visit` lendo `signal_payload`. Dropar `Lens::ScoreVisit`, `Academy::LensSignal` model + tabela.

### 2.4 `UiHelper` proxy via `method_missing`

`app/helpers/ui_helper.rb` (~30 LOC de metaprogramming) existe pra que components escrevam `helpers.ui.icon(...)` em vez de `render Ui::Icon::Component.new(...)`. Usado em ~10 components.

**Simplificar:** substituir todas as ~30 chamadas `helpers.ui.X(...)` por `render Ui::X::Component.new(...)` (mecânico via sed). Dropar o helper. Ganha-se claridade, perde-se ~30 LOC.

### 2.5 Slot sub-components (~25 arquivos)

`app/components/ui/{card,modal,drawer,empty,header,stat,tabs}/` cada uma tem 3-5 sub-component files (`title_component.rb`, `body_component.rb`, `footer_component.rb`...) que só existem para slot-rendering interno. Cada uma tem 1 caller (o pai).

**Refactor (1 sessão dedicada):** trocar por `renders_one`/`renders_many` com block syntax inline no pai. Ganha-se ~25 arquivos a menos. Pode ser feito em PR separado.

### 2.6 `Profiles::SetWishlistService`

3 LOC efetivos envolvidos em ApplicationService::Result. Inline no controller.

**Estimativa Tier 2:** ~10 arquivos refatorados · -500 LOC líquidos · 2 tabelas a mais dropadas

---

## Tier 3 — Verify antes de tocar

### 3.1 `Academy::PracticeWager` (UI live mas writer morto)

- Tabela: 0 rows
- `Wagers::Create` é stub → ninguém cria wager
- MAS `subjects/index.html.erb` renderiza "Apostas em aberto" e `Kid::Academy::PracticeWagersController#update` chama `Wagers::Settle`

**Decisão pendente do produto:** wager é feature futura ou retirada? Se retirada, dropar tudo (controller + view block + model + tabela). Se futura, mover pra branch parking-lot.

### 3.2 `LearnerSignal` (Compass::Propose usa)

- Tabela tem rows; lida por `Academy::Compass::Propose` (linhas 42, 61) que serve a "Bússola do Explorador" em `kid/academy/subjects#index` — KEEP a tabela.
- `Signals::Record` no chain de Finalize: precisa rodar pra Compass continuar tendo dados. **NÃO remover de Finalize.**

### 3.3 `Academy::Secret` / `SecretUnlock`

- UI live em `kid/academy/subjects/index` ("Segredos recém-desbloqueados") e parent dashboard
- `Secrets::EvaluateForLearner` no chain de Finalize: keep
- Verificar quantos `SecretUnlock` rows existem (não medi acima); se 0, pode ser feature dormante

### 3.4 PWA components iOS

- `ui/install_prompt/`, `ui/ios_install_hint/`, `ui/pwa_update_toast/` — cada uma 1 reference em `_pwa_shell.html.erb` + 1 Stimulus controller cada
- iOS install UX historicamente frágil — testar em iOS atual antes de assumir vivo

### 3.5 `Adapt::NextMissionFor`

- Substituído por `Compass::Propose` mas mantido como fallback "single candidate"
- Próprios comentários da Compass dizem isso — provável dead path

---

## Out of Scope (mantém — atualmente serve o usuário)

- **`DiscoveryCard` + `Cards::MintAfterMission`** — rendered em celebration + atlas + subjects index ("ÚLTIMAS DESCOBERTAS")
- **`Secret` + `SecretUnlock` + `Secrets::EvaluateForLearner`** — rendered em kid + parent
- **`Trail`** — backbone de navegação subject→trail→mission
- **`Compass::Propose`** — "Bússola do Explorador" em kid/academy/subjects
- **`Connections::ForMission`** — strip em celebration
- **`Pokedex::Advance` + `Concept` + `LearnerConcept`** — atlas é marquee
- **`TransferDetection`** — feature explícita do produto (cross-area concept transfer)
- **`GlobalTaskAssignment`** — vivo (41 rows, usado por upcoming tasks)
- **Guide chat (todo `app/services/academy/guide/`)** — DeepSeek + persona v2 dinâmica

---

## Estimativa Consolidada

| Tier | Arquivos | LOC | Tabelas | Risco | Sessões |
|---|---:|---:|---:|---|---:|
| 1 — Safe Deletes | ~40 | -2.500 | 8 | Baixo | 1 |
| 2 — Shrinks | ~10 refactor | -500 | 2 | Médio | 1-2 |
| 3 — Verify+Maybe-Delete | ~10 | -400 | 1-2 | Médio | depende de prod |

**Total potencial: ~60 arquivos · -3.400 LOC · ~10-11 tabelas dropadas.**

---

## Ordem de Execução Recomendada

1. **Sessão 1 — Tier 1 inteiro em um commit grande**
   - Migration drop_dormant_academy_tables (skills, ranks, medals, digests, virtue_sightings, recall_reviews, learner_skills, aula_skills)
   - rm dos services, jobs, models órfãos
   - rm dos 6 UI components zero-ref + 3 helpers + bulk_select controller
   - rm Ui::Header e Ui::Stat subtrees
   - rm star_decay_job
   - Cron entries (digests_weekly + recall_reminder)
   - Atualizar parent dashboard view: remover bloco skills_radar (sempre zero)
   - Atualizar kid/parent views: remover `@rank_record` reads

2. **Sessão 2 — Tier 2 ChooseNext + LearnerContext.mastery_tier**
   - Encolher ChooseNext pra ~50 LOC
   - LearnerContext usar `level` int direto
   - BuildPrompt#learner_state_block adaptar

3. **Sessão 3 — Tier 2 LensSignal+ScoreVisit consolidation**
   - Migrar lógica de bump pro AdvanceLens
   - Drop LensSignal model + tabela

4. **Decisão produto** — Tier 3 (wager + PWA iOS)

---

## Notas

- A migration de drop pode ser **irreversível** (write `raise ActiveRecord::IrreversibleMigration` no `down`). Dados que estavam zerados ou em valores fake (89 medals seedadas mas 0 awards) não têm valor de negócio.
- Não tocar em modelos do host (`Family`, `Profile`, `ProfileTask`, `GlobalTask`, `GlobalTaskAssignment`, `Reward`, `ActivityLog`, `Redemption`, `Category`) — todos vivos.
- Não tocar em `Authenticatable` concern, `ApplicationService`, factories ativas, `Tasks::*`, `Rewards::*`, `Auth::*`, `Streaks::*`, `Ui::Celebration`.

---

## Reasoning Trail (por que confio nesses números)

- **Zero-callers**: grep recursivo no app/ + lib/ + config/ + db/ excluindo migrations e `.planning`. Os agentes auditores confirmaram independentemente.
- **Zero-rows**: rodei `Academy::LearnerSkill.where("score > 0").count` etc. via `bin/rails runner` no DB de dev (pode estar fora de prod). Se o usuário quiser, vale rodar o mesmo em prod console antes do Tier 1.
- **UI grep**: confirmei que `parent/academy/dashboard/index.html.erb` e `kid/academy/subjects/index.html.erb` são os únicos consumidores das features sob investigação. Ranks/Skills/Medals não aparecem em nenhuma view kid.

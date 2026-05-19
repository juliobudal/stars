# Academy v4 — especificação executável

> Data: 2026-05-16
> Documentos antecedentes (leitura prévia obrigatória):
> - `.planning/audits/academy-v2-brutal-review-2026-05-16.md` (diagnóstico)
> - `.planning/designs/academy-v3-vision.md` (visão contemplativa — recalibrada)
> - `.planning/designs/academy-v3.1-adventure.md` (filosofia v4)
>
> Postura: spec implementável. Não vision doc. Cada item vira ticket.

## 0. O que v4 é (e não é)

**É** a aterrissagem de v3.1 no schema/serviços `Academy::` já em produção (v2 shipou 2026-05-16). Migração incremental sobre as 26 tabelas existentes.

**Não é** filosofia nova. Não é rewrite. Não é "v2 jogado fora".

Princípio de migração: **renomear conceitualmente, manter schema, evoluir incrementalmente.** Tudo que v3.1 propõe deve ser entregue como delta sobre `academy_*` atuais.

---

## 1. Decisões defaults (assumidas — vire se diferente)

Decisões abertas da última conversa, resolvidas agora com defaults razoáveis:

| # | Pergunta | Default assumido | Reversível em |
|---|---|---|---|
| 1 | Workflow de conteúdo | **(c) Híbrido: LLM gera draft → humano revisa em CMS → publica** | Sprint 4 |
| 2 | Quem escreve conteúdo | **Você + LLM por ora**, pedagogo contratado no mês 3 quando CMS estabilizar | Mês 3 |
| 3 | Início do Sprint 1 | **+1 semana de estabilização do v2** antes (2026-05-23) | imediato |
| 4 | Completar 5 áreas esqueléticas | **Em paralelo ao v4**, com tom v4 já desde o início | imediato |
| 5 | Este documento | **Existe** | — |

---

## 2. Princípios não-negociáveis (filtros de PR)

Toda mudança no módulo `Academy::` deve passar por estes filtros antes de merge:

1. **"Um menino de 9 anos contaria isso pro amigo na escola?"** Se não, refaz.
2. **70% descoberta / 30% reflexão.** Se a PR adiciona reflexão, soma e não passe de 30%.
3. **Celebra só o que custa.** Animação nova exige justificativa de raridade no PR description.
4. **LLM é escritor, não juiz de comportamento.** LLM avalia *conteúdo de resposta*, nunca *caráter da criança*.
5. **Conteúdo no CMS, nunca em seed Ruby novo** (a partir do Sprint 4).
6. **Zero novas FKs entre `academy_*` e tabelas host** (`profiles`, `families`).
7. **`Academy::ApplicationService` para qualquer mutação multi-step.**

---

## 3. Schema — deltas sobre `academy_*` atuais

### 3.1 Tabelas mantidas, com novos campos

```ruby
# academy_missions
add_column :academy_missions, :format, :string, null: false, default: "discovery"
# enum: discovery | story_choice | pattern_meta
add_column :academy_missions, :scenes_tree, :jsonb, default: {}
# para story_choice; jsonb: { nodes: [{id, narrative, choices: [{label, next_id}]}], terminal_ids: [...] }
add_column :academy_missions, :teaser_for_next_mission_id, :bigint
# FK opcional — beat 7 obrigatório
add_index  :academy_missions, :format
add_index  :academy_missions, :teaser_for_next_mission_id

# academy_concepts
add_column :academy_concepts, :pokedex_silhouette_key, :string
# asset name (svg em app/assets/images/academy/pokedex/)
add_column :academy_concepts, :pokedex_color_key, :string
# token de cor v4 (não hex)

# academy_concept_edges
add_column :academy_concept_edges, :edge_type, :string, null: false, default: "relates_to"
# enum: generalizes | manifests_in | conflicts_with | requires | composes_with | predicts | relates_to
add_index  :academy_concept_edges, :edge_type

# academy_discovery_cards
add_column :academy_discovery_cards, :kind, :string, null: false, default: "mission_card"
# enum: mission_card | trail_theory | virtue_sighting
add_index  :academy_discovery_cards, [:learner_id, :kind]

# academy_learner_ranks
add_column :academy_learner_ranks, :title_slug, :string
# enum: curious | observer | explorer | cartographer | naturalist | mentor
# substitui o "rank numérico" — view layer só lê title_slug
```

### 3.2 Tabelas deprecadas (read-only, sem nova escrita)

- `academy_challenge_reports` → congela. UIs param de escrever. Dados preservados para analytics.
- `academy_recall_reviews` → congela como UI. Schema mantido para analytics retroativa. Mecânica vira callback contextual (§5.3).

### 3.3 Tabelas removidas da UI do kid (mantidas no backend)

Frontend kid **não exibe**:
- `academy_medals` / `academy_medal_awards`
- `academy_learner_skills` (score raw)

Frontend parent continua exibindo (são para pais).

### 3.4 Novas tabelas

```ruby
# Pokédex de modelos mentais
create_table :academy_learner_concepts do |t|
  t.references :learner_id, null: false  # value object, sem FK
  t.references :concept, null: false, foreign_key: { to_table: :academy_concepts }
  t.integer :level, null: false, default: 0          # 0..3
  t.integer :seen_in_subjects_count, default: 0
  t.integer :transfer_count, default: 0
  t.datetime :first_seen_at
  t.datetime :last_seen_at
  t.datetime :evolved_to_2_at
  t.datetime :evolved_to_3_at
  t.timestamps
end
add_index :academy_learner_concepts, [:learner_id, :concept_id], unique: true
add_index :academy_learner_concepts, [:learner_id, :level]

# Apostas de prática (substitui challenge_reports)
create_table :academy_practice_wagers do |t|
  t.references :learner_id, null: false
  t.references :mission, null: false, foreign_key: { to_table: :academy_missions }
  t.integer :guide_bet_count, null: false
  t.integer :learner_actual_count
  t.string  :parent_observation       # seen_match | seen_higher | seen_lower | skip | nil
  t.text    :learner_note             # opcional, frase curta
  t.datetime :reported_at
  t.datetime :observed_at
  t.timestamps
end
add_index :academy_practice_wagers, [:learner_id, :mission_id], unique: true
add_index :academy_practice_wagers, :reported_at

# Caminhos em histórias-missão
create_table :academy_learner_story_paths do |t|
  t.references :learner_id, null: false
  t.references :mission, null: false, foreign_key: { to_table: :academy_missions }
  t.jsonb :scene_sequence, default: []   # [{scene_id, choice_label, at}]
  t.string :terminal_scene_id
  t.datetime :completed_at
  t.timestamps
end
add_index :academy_learner_story_paths, [:learner_id, :mission_id]

# Avistamentos de virtude (sem score)
create_table :academy_virtue_sightings do |t|
  t.references :learner_id, null: false
  t.string :virtue_slug, null: false     # honra-palavra | conserta-erro | espera | conta-verdade-que-custa | ...
  t.text :context, null: false           # 1-2 frases — pode vir do kid ou parent
  t.string :source, null: false          # self_reported | parent_confirmed | guide_inferred
  t.datetime :spotted_at, null: false
  t.timestamps
end
add_index :academy_virtue_sightings, [:learner_id, :virtue_slug, :spotted_at]

# Transferências detectadas (evento auditável)
create_table :academy_transfer_detections do |t|
  t.references :learner_id, null: false
  t.references :from_concept, foreign_key: { to_table: :academy_concepts }
  t.references :to_concept,   foreign_key: { to_table: :academy_concepts }
  t.references :message,      foreign_key: { to_table: :academy_messages }
  t.decimal :confidence, precision: 3, scale: 2
  t.text :evidence_excerpt          # snippet da resposta do kid
  t.datetime :detected_at
  t.timestamps
end
add_index :academy_transfer_detections, [:learner_id, :detected_at]
```

---

## 4. Regras de Pokédex (autoritativas)

`LearnerConcept.level` muda **apenas** por `Academy::Pokedex::Advance(learner, concept, trigger:)` (idempotente).

| Nível | Nome | Trigger de subida |
|---|---|---|
| 0 → 1 | Silhueta → **Avistado** | primeira aparição de `concept` em `aula_concepts` de uma `Mission` que o kid **completou** (`MissionProgress.completed`) |
| 1 → 2 | Avistado → **Reconhecido** | segundo encounter completado + segundo encounter está em `Subject` diferente do primeiro |
| 2 → 3 | Reconhecido → **Dominado** | terceiro encounter completado **OU** primeiro `TransferDetection` registrado para esse concept |

- Nunca regride.
- Cada subida dispara animação 3s + som distinto + entrada em `LearnerSignal` (kind: `concept_evolved`).
- Em backfill (Sprint 1): rodar `Academy::Pokedex::Backfill` calculando todos níveis com base em histórico de `MissionProgress` e `AulaConcept`.

---

## 5. Serviços — novos e alterados

### 5.1 `Academy::Compass::Propose(learner)` — substitui `Adapt::NextMissionFor`

Retorna sempre 3 cards:

```ruby
{
  hot_trail:      { mission_id:, reason: "Você tá caçando 3 padrões ligados — esse é o próximo." },
  new_territory:  { mission_id:, reason: "Você nunca explorou Caráter. Quer ver?" },
  revisit:        { mission_id:, reason: "Aquele padrão do açúcar tá voltando em outro lugar." }
}
```

Regras:
- `hot_trail`: `Trail` com maior `LearnerSignal.affinity` ativa, próxima `Mission` não-iniciada na trail; fallback: mission cujo `concept` é adjacente (no `concept_edges`) a um concept Avistado/Reconhecido.
- `new_territory`: `Subject` com menor `completion_count` do learner que tem ≥1 mission ativa não tocada.
- `revisit`: `Mission` que tagueia um `concept` com `LearnerConcept.level ∈ {1,2}` e `last_seen_at > 7 dias`, preferindo mission em `Subject` diferente do encontro anterior.

Determinístico (sem jitter). Tie-break: `id ASC` para reprodutibilidade.

Fallback se algum slot vazio: usa scoring do `Adapt::NextMissionFor` legado.

### 5.2 `Academy::Transfer::Detect` — job assíncrono

Solid Queue, executa após **toda** `Message` do learner com `content.length > 40` em turno livre (não checkpoint).

Pipeline:
1. Carrega últimos 20 conceitos do learner (`LearnerConcept` ordenado por `last_seen_at desc`).
2. Carrega `concept_ids` da `Mission` atual (excluí esses da análise).
3. Pede LLM-judge:
   ```
   Texto do explorador: "{message.content}"
   Conceitos que ele já conhece (não os da missão atual): [{slug, headline}, ...]
   Pergunta: ele aplicou/mencionou ALGUM deles aqui? Responda JSON:
   { "applied": [{slug, confidence: 0..1, snippet: "trecho que mostra"}] }
   ```
4. Para cada `applied` com `confidence ≥ 0.75`: cria `TransferDetection`, dispara `Pokedex::Advance` (subir para 3), emite Turbo Stream pra Atlas mostrar aresta nascendo.

Custo: ~1 chamada LLM por turno livre. Modelo barato (Sonnet 4.6 ou DeepSeek). Cache de 5 min por `(learner_id, message_hash)`.

### 5.3 Callback contextual (substitui `Recall::Reschedule` na UI)

Quando `StartMission` cria a primeira sessão de uma `Mission` cujos `concept_ids` intersectam com `LearnerConcept` do kid em nível ≥1:

- Injeta no system prompt do Guia:
  ```
  CONTEXTO: o explorador já encontrou os conceitos:
  - "dopamina" (visto em "Por que mexer no celular é tão difícil de parar?", há 5 dias)
  Use isso como ponte no Beat 1 ou 2. Não re-explique o conceito; reconheça que ele já é conhecido.
  ```
- Resultado: o Guia abre "Lembra daquele bicho? Ele apareceu de novo." sem nova tela de "recall".

Mantém `RecallReview` existente como sinal analítico (rastreia decay), mas remove a tela do kid.

### 5.4 `Academy::PracticeWager::Settle` — chamada quando kid reporta

Substitui `Challenges::Open`/`Challenges::Report`. Fluxo:

1. No final de cada `discovery` mission, `Wager::Create` salva o `guide_bet_count` (vindo do LLM, beat 6).
2. Pílula visual aparece na home no dia seguinte: "Conta a real — quantas vezes vc fez X?"
3. Kid manda número (input numérico simples + nota livre opcional).
4. `Wager::Settle` calcula `delta`, dispara Guia para responder na próxima missão: "Você disse 12, eu apostei 15. Quase!"
5. Parent push opcional (se opt-in): "Mariana reportou 12. Vc vê parecido? [match/mais/menos/skip]"

Sem score. Sem skill+ por isso. Triangulação puramente para conversa.

### 5.5 `Academy::ParentDigest::Compose` — cron semanal

Domingo 19h (config). Para cada learner ativo nos últimos 7 dias:
- Coleta: missões concluídas, conceitos evoluídos, transfer detections, virtue sightings, wagers reportados.
- Pede LLM com prompt focado em narrativa de bordo (sem psicologismo).
- Salva como `ParentDigest` (nova tabela leve) + envia email/push.

Tom (no prompt do digest): "jornal de bordo de expedição". Estrutura fixa de 4 blocos curtos:
```
Padrões descobertos: ...
Maior reveal da semana: ...
Conversa puxada: ...
Coisa que sua filha mandou pra vc: ...
```

---

## 6. Patch no prompt do Guia (`Llm::GuidePersona`)

Adicionar no topo, **antes** das HARD RULES existentes:

```
=== PERSONA UPDATE 2026-05 (v4) ===
Você é mentor de aventura, não professor.
Tom: Bill Nye + Mythbusters + Kurzgesagt + naturalista divertido.

PERMITIDO:
- humor seco, gírias leves
- exclamações genuínas ("sério?", "ó isso", "aposto que...")
- chamar o kid de "explorador" ocasionalmente
- linguagem direta de aventura ("vamos caçar esse padrão")

PROIBIDO (substitui regras antigas):
- tom de TED talk infantil
- introduções solenes ("deixa eu te contar uma coisa importante")
- fechamentos contemplativos ("pense nisso até amanhã")
- linguagem de terapia ("como você se sente sobre isso?")
- moralização ("é importante ser honesto")

BEAT 7 É OBRIGATORIAMENTE UM TEASER do próximo padrão.
Formato: "Próxima missão: [gancho do próximo conceito]. Te vejo amanhã."
Se não souber o próximo, gere gancho misterioso curto.
```

E mover Beat 6 para o **formato de aposta**:
```
BEAT 6 (mini-ação) DEVE ser aposta numérica quando aplicável:
"Aposto que você [faz X] [N] vezes hoje. Me conta amanhã."
N = palpite calibrado (não óbvio). Custa pro kid mais provar você errado
do que aceitar o número.
```

Eval suite obrigatório antes de promover patch: 10 cenários (`spec/services/academy/llm/persona_v4_eval_spec.rb`), gerando turnos e checando:
- Beat 7 presente em 100% dos turnos finais.
- Sem ocorrências de "reflita sobre" / "pense em como você se sente".
- Aposta numérica presente em ≥80% dos beat-6 de discovery missions.

---

## 7. Migração e backfill (Sprint 1)

Em ordem:

1. **Migrations 1** — adicionar colunas em `academy_missions`, `academy_concepts`, `academy_concept_edges`, `academy_discovery_cards`, `academy_learner_ranks`.
2. **Migrations 2** — criar `learner_concepts`, `practice_wagers`, `learner_story_paths`, `virtue_sightings`, `transfer_detections`, `parent_digests`.
3. **Backfill** `Academy::Pokedex::Backfill` — itera por `MissionProgress.completed` ordenado por `completed_at asc`, replay para popular `learner_concepts.level` e timestamps de evolução. Idempotente.
4. **Backfill** `Academy::LearnerRanks::AssignTitles` — converte rank numérico atual para `title_slug` mais próximo (Iniciante→curious, etc).
5. **Backfill** `academy_concept_edges.edge_type` — todas as arestas existentes recebem `edge_type='relates_to'`. Manual review depois para upgrade tipado.
6. **Soft kill** UIs de medalha/skill/recall/challenge no `kid/academy/*`. Routes mantém para preview parental.

Rollback strategy: feature flag `Rails.application.config.academy_v4_enabled`. Liga progressivamente por subject de profile.

---

## 8. Plano de sprint (4 sprints, ~2 semanas cada)

### Sprint 1 — "Tom + Pokédex" (2026-05-23 → 2026-06-06)

**Entregas:**
- [ ] Migrations 1 e 2 deploy.
- [ ] `Academy::Pokedex::Advance` + `Backfill` rodando em produção.
- [ ] Atlas refeito: silhueta → cor → brilho por concept (CSS + Stimulus).
- [ ] Patch do prompt (Persona v4) + eval suite passando.
- [ ] Soft-kill no front kid: medalhas, skills, recall card, rank numérico.

**Aceite:** kid de teste vê o Atlas com criaturas em 3 estados visuais; pelo menos 1 evolução acontece em conta com histórico de missões.

### Sprint 2 — "Caça com placar" (2026-06-06 → 2026-06-20)

**Entregas:**
- [ ] `PracticeWager::Create` + `Settle` services.
- [ ] UI no fim da missão com input numérico ("aposta do Guia: 12. Real?").
- [ ] Parent confirmation 1-tap por push (opt-in).
- [ ] Deprecação de `challenge_reports` no front (kid).
- [ ] Beat 6 e 7 do prompt validados em eval suite.

**Aceite:** 80% das missões `discovery` concluídas em conta de teste produzem `PracticeWager` + Guia comenta na missão seguinte.

### Sprint 3 — "Transferência + Bússola" (2026-06-20 → 2026-07-04)

**Entregas:**
- [ ] `Academy::Transfer::Detect` job + LLM-judge configurado.
- [ ] `TransferDetection` + animação de aresta nascendo no Atlas.
- [ ] `Academy::Compass::Propose` substitui `Adapt::NextMissionFor` (com fallback).
- [ ] Home reformulada: 1 missão dominante + Atlas pulsante + Caderno.
- [ ] `concept_edges.edge_type` ativo em 50%+ das arestas.

**Aceite:** transferência detectada em 1 conta de teste real, com animação visível e card "cartógrafo" disparando.

### Sprint 4 — "Histórias-Missão + CMS + Digest" (2026-07-04 → 2026-07-18)

**Entregas:**
- [ ] `mission.format=story_choice` + `scenes_tree` jsonb suportados no controller/view.
- [ ] Admin scaffold para editar `Mission` (ActiveAdmin ou similar) — fim do seed Ruby para conteúdo novo.
- [ ] 4 histórias-missão escritas e publicadas (1 por área: Caráter, Vida & Sociedade, Resolver, Tech).
- [ ] `ParentDigest::Compose` rodando semanalmente.
- [ ] Eval suite rodando em CI a cada PR que toca prompt.

**Aceite:** pai de conta de teste recebe digest com 4 blocos preenchidos; kid completa 1 story_choice mission com caminho registrado.

---

## 9. KPIs com queries

| KPI | Query base | Meta dia 90 |
|---|---|---|
| Transfer rate | `count(transfer_detections in 90d) / count(mission_progresses completed in 90d)` | ≥ 0.25 |
| Pokédex evolution depth | `% of active learners with ≥5 learner_concepts.level ≥ 2` | ≥ 40% |
| Wager honesty calibration | `avg(abs(guide_bet - learner_actual))` plotado por semana — esperado **decrescer** | tendência ↓ ao longo de 8 sem |
| Voluntary atlas visits | `count(distinct atlas_visit_events sem prompt) / active_learners` | ≥ 40% kids visitam ≥ 1×/sem após mês 2 |
| Same-day return | `% learners que abrem app em D+1 sem push em D` | ≥ 60% |
| Parent digest open | `% digests com open_event` | ≥ 70% pais ativos |
| Story choice completion | `% story_choice missions iniciadas que terminam` | ≥ 75% |

Dashboard Grafana/Metabase a partir de Sprint 2 (analytics layer separada — read replica + ETL leve).

---

## 10. Riscos e rollback

| Risco | Mitigação |
|---|---|
| Tom v4 do Guia degrada qualidade em algumas áreas | Eval suite + A/B em prompt versionado (Sprint 1) |
| Pokédex backfill cria estado inconsistente | Idempotente + dry-run em staging + ativável por feature flag |
| Custo LLM da detecção de transferência explode | Cache 5min, executa só em mensagens >40c, modelo barato |
| Pais não engajam com digest e quebra signal triangulado | Sem dependência crítica — sistema funciona sem confirmação parental, ela só enriquece |
| `story_choice` missions consomem tempo enorme de escrita | Limitar a 4 no Sprint 4; pedagogo no mês 3 |
| Kid sente que perdeu conteúdo (rank numérico, medalhas) | Migração suave: `title_slug` substitui rank visualmente; medalhas só somem do nav, ainda existem em "histórico" |

Rollback: `Rails.application.config.academy_v4_enabled` flag por env + per-profile override. Reativar v2 UI é toggle.

---

## 11. Definition of done (v4 full)

v4 está "feito" quando:

1. Os 4 sprints completos e em produção por ≥30 dias.
2. KPIs medidos em pelo menos 50 learners ativos.
3. Eval suite do prompt do Guia roda em CI a cada PR de prompt.
4. CMS publica missões sem deploy.
5. Documentação de operação atualizada em `docs/academy-v2.md` (renomear para `docs/academy.md`, retirar prefixo de versão — v4 vira "o academy").
6. Time consegue dizer "esta semana a Mariana evoluiu 2 conceitos e o Guia detectou 1 transferência" — narrativa, não vanity.

---

## 12. O que v4 explicitamente NÃO inclui

Não entram nesta especificação (postergados para v5 ou nunca):

- Spaced repetition explícito com tela própria.
- Notificações de retenção diária.
- Streak diário, mesmo "soft".
- Skill score visível no kid.
- Currículo invisível com "ensinar virtude" como categoria.
- Reflection/journal diário.
- Co-terapia parental (pacto mensal, espelho semestral).
- Crisis detection visível ao parent (mantém apenas safety silenciosa interna).
- Compartilhamento social entre crianças.

Se algum desses voltar à pauta, abre RFC. Não entra por "feature creep".

---

## 13. Próximo passo concreto

Após aprovação deste documento:

1. Criar epic no tracker (Linear/GitHub Projects/Notion).
2. Quebrar em tickets por sprint (esqueleto pronto nas seções §7 e §8).
3. Sprint 1 starts **2026-05-23**, após semana de estabilização do v2.

Quando isso acontecer, pego do tracker e começo Sprint 1.

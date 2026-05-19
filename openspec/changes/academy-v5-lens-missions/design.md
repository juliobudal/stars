# Design — Academy v5: Missões por Lentes

> Companion técnico de `proposal.md`. Define a arquitetura concreta, contratos
> de dados, ordenação de lentes, pipeline LLM, UI shape e plano de migração.
> Decisões já fixadas pelo usuário em modo explore (1:1 missão↔conceito, lentes
> geradas por LLM refinada, sistema escolhe ordem, lentes sempre presentes, pais
> recompensando aprendizado fica para fase futura, refundação clean sem backward
> compat).

## 1. Visão arquitetural

A Academy v5 colapsa a unidade pedagógica em **uma missão = um conceito = uma
jornada por lentes**. O que hoje vive como sessões PÍLULA + beats + chat
contínuo (`Academy::AdvanceTurn`, `Llm::GuidePersona`, `Llm::GuideAgent`,
`MissionsController#turn`) é substituído por um **stage runner** que pinta
lentes em sequência, cada uma com seu próprio mini-formato interativo.

### Novo namespace

```
Academy::Lens::*
├── Catalog          # tipos de lente + metadados + prompts
├── Generate         # invoca LLM e popula academy_lens_cache
├── Personalize      # injeta nome/contexto na render (não regenera)
├── ChooseNext       # decide próxima lente da jornada
├── ScoreVisit       # consolida sinais de uma visita
├── WarmCacheJob     # geração noturna proativa
└── Generators::<Type>  # 1 classe por tipo de lente com prompt + schema
```

E a interface HTTP:

```
Academy::Mission::Begin       # substitui StartMission
Academy::Mission::Advance     # substitui AdvanceTurn (orquestra lens stages)
Academy::Mission::Finalize    # finaliza missão e mintada de cards
```

### Serviços v4 removidos

- `Academy::AdvanceTurn` (`app/services/academy/advance_turn.rb`)
- `Academy::StartMission`
- `Academy::Llm::GuidePersona` (`app/services/academy/llm/guide_persona.rb`)
- `Academy::Llm::GuideAgent`
- `Academy::Wagers::Create` (vira `Lens::Generators::PredictReveal`)
- `Kid::Academy::MissionsController#turn` / `#choose` colapsam em `#advance`

### Serviços v4 mantidos

- `Academy::Cards::MintAfterMission` — discovery cards continuam sendo o
  artefato colecionável de fim de missão.
- `Academy::Signals::Record` — agora alimentado por sinais de lente
  (`lens_visit_completed`, `lens_micro_check_correct`, `lens_abandoned`,
  `transfer_lens_closed`).
- `Academy::Secrets::EvaluateForLearner` — chamado pelo `Mission::Finalize`.
- `Academy::Transfer::Detect` — virou um *sinal*, não mais o driver de L3.

## 2. Modelo de dados

### `academy_missions` — simplificação

Drop:

- `format` (enum `discovery|story_choice|pattern_meta`)
- `scenes_tree` (jsonb)
- `sessions_count`
- `teaser_for_next_mission_id`

Add:

- `concept_id` bigint NOT NULL FK → `academy_concepts(id)` (1:1 mission↔concept)
- `lens_journey_state` jsonb DEFAULT `{}` — config de jornada (cap, regras de
  fechamento override por mission, áreas a evitar etc — opcional)

Drop tabela inteira:

- `academy_aula_concepts` (M:N substituída pela FK direta acima)

### `academy_lens_cache` — novo

Cache global de lentes geradas, particionado por chave didática.

```
academy_lens_cache
├── id
├── concept_id      bigint FK NOT NULL
├── lens_type       string  NOT NULL    # científica | narrativa | etica | ...
├── age_band        string  NOT NULL    # 'kid' por enquanto
├── locale          string  NOT NULL    # 'pt-BR'
├── payload         jsonb   NOT NULL    # estrutura específica do tipo
├── prompt_version  string  NOT NULL    # ex: 'cientifica.v3'
├── generated_at    datetime
├── generated_by    string              # 'deepseek-v4-flash' etc
├── tokens_in       integer
├── tokens_out      integer
├── curated_by      bigint NULLABLE     # admin override
├── timestamps

UNIQUE (concept_id, lens_type, age_band, locale, prompt_version)
INDEX  (concept_id, lens_type)
```

### `academy_learner_lens_visits` — novo

Trace por aprendiz × lente. Cada visita = uma instância renderizada.

```
academy_learner_lens_visits
├── id
├── mission_progress_id  bigint FK
├── learner_id           bigint
├── lens_cache_id        bigint FK
├── lens_type            string
├── opened_at            datetime
├── completed_at         datetime NULLABLE
├── outcome              string    # completed | abandoned | skipped_by_system
├── signal_payload       jsonb     # respostas, tempo, micro-check correctness
├── timestamps

INDEX (mission_progress_id, opened_at)
INDEX (learner_id, lens_type)
```

### `academy_mission_progresses` — ajuste leve

Drop: `current_session_index`, `total_checkpoints`, `correct_checkpoints`.
Add: `lens_visit_count` (int), `closing_lens_type` (string).

### Tabelas v4 mantidas como sinal histórico (não-driver)

- `academy_practice_wagers` → resultado da lente `predict_reveal`; serializa o
  delta apostado.
- `academy_learner_story_paths` → estado interno da lente `narrativa` quando
  bifurcada.
- `academy_virtue_sightings`, `academy_transfer_detections`,
  `academy_learner_signals` → alimentadas por `Lens::ScoreVisit`.
- `academy_discovery_cards` → mintadas ao fim da missão como antes.

## 3. Catálogo de lentes

Oito tipos. Cada um tem prompt + schema + UI primitive + critérios de eval.

### 3.1 🔬 Científica

**Propósito didático:** mecanismo. Cause-and-effect explícito.
**UI primitive:** painel ilustrado (esquema/diagrama) + 1 micro-check.
**Schema de saída:**

```json
{
  "headline": "string ≤ 80c",
  "mechanism_steps": ["passo 1", "passo 2", "passo 3"],
  "illustration_hint": "string — metáfora visual",
  "micro_check": {
    "question": "string",
    "options": ["a","b","c"],
    "correct_index": 0,
    "rationale": "string"
  }
}
```

**Prompt skeleton:**

```
Você gera UMA lente científica sobre o conceito "{concept_slug}" para um
aprendiz de 8-14 anos. Foco: MECANISMO. NÃO conte história, NÃO moralize.
Explique a sequência de causa→efeito em 3 passos curtos. Cada passo é uma
frase de até 16 palavras. Termine com um micro-check de aplicação
(situação NOVA, não recitação). PROIBIDO: metáforas vagas, "muitos
cientistas acreditam", "estudos mostram" sem fonte. Saída: JSON conforme
schema.
```

**Eval gate:** 3 passos obrigatórios, presença de verbo causal, blacklist de
hedging ("talvez", "pode ser").

### 3.2 📖 Narrativa

**Propósito didático:** memorabilidade + Pixar pitch.
**UI primitive:** sequência de cards (3-5) com personagem + dilema + escolha
+ resultado. Branching opcional.
**Schema:**

```json
{
  "character": {"name": "string", "age": 11, "trait": "string"},
  "scenes": [{"id": "s1", "text": "...", "choices": [{"label":"...","next":"s2"}]}],
  "ending": "string — fecha o conceito",
  "micro_check": { ... }
}
```

**Prompt:** "Conte UMA história curta com 1 personagem + 1 dilema concreto +
1 escolha + 1 consequência observável. Sem moral explícita. O conceito
aparece como mecânica da consequência, não como rótulo."

### 3.3 ⚖️ Ética / Virtude

**Propósito:** tensão de valor. Forçar julgamento.
**UI primitive:** dois cenários lado a lado (split-screen) com slider de
posicionamento.
**Schema:**

```json
{
  "dilemma": "string ≤ 200c",
  "case_a": {"title": "...", "body": "..."},
  "case_b": {"title": "...", "body": "..."},
  "anchor_question": "string",
  "reveal": "string — o que a sacada implica sobre o julgamento"
}
```

**Prompt:** "Construa um dilema concreto onde o conceito empurra para um
julgamento desconfortável. Os dois casos são realistas e ambos defensáveis."

### 3.4 📈 Estatística

**Propósito:** predizer→revelar. Calibrar intuição com dado.
**UI primitive:** slider numérico (predict) → reveal animado com gráfico
mínimo.
**Schema:**

```json
{
  "predict_prompt": "string",
  "predict_unit": "vezes por dia | %",
  "predict_min": 0, "predict_max": 100,
  "reveal_value": 47,
  "reveal_source": "string — citação observável",
  "interpretation": "string ≤ 200c"
}
```

Esta lente é a evolução natural do `PracticeWager` v4 — quando gerada para
um conceito de comportamento (`dopamina`, `glicose-pico`), o `reveal_value`
pode ser convertido em `guide_bet_count` para escrita compatível em
`academy_practice_wagers`.

### 3.5 🛠 Engenharia

**Propósito:** tradeoff de design. "E se você tivesse que construir isso?"
**UI primitive:** drag-list de constraints; aprendiz arrasta 3 de 6 para
priorizar; sistema mostra consequência de cada combinação.
**Schema:**

```json
{
  "challenge": "string — projete X",
  "constraints": [{"id":"c1","label":"...","cost":"..."}],
  "must_pick": 3,
  "outcomes": {"c1+c2+c3": "string", "...": "..."}
}
```

### 3.6 🕰 Histórica

**Propósito:** mesmo padrão atravessa eras. Slot machine 1898 → infinite feed
2012.
**UI primitive:** timeline horizontal de 3 cenas; cada cena é um cartão com
data + cena + 1 elemento estrutural.
**Schema:**

```json
{
  "pattern_label": "string",
  "scenes": [
    {"year": 1898, "headline": "...", "structural_element": "..."},
    {"year": 1971, "headline": "...", "structural_element": "..."},
    {"year": 2012, "headline": "...", "structural_element": "..."}
  ],
  "pattern_question": "O que esses 3 momentos têm em comum?"
}
```

### 3.7 👁 Primeira-pessoa

**Propósito:** micro-ação encarnada. Âncora sensorial.
**UI primitive:** instrução de 1 ação física (≤ 60s) + reveal pós-ação.
**Schema:**

```json
{
  "action_prompt": "Pare. Respire 4 vezes contando até 4 em cada inspiração.",
  "sensory_anchor": "string — o que vai notar",
  "expected_time_seconds": 30,
  "reveal": "string — o que essa sensação ensina sobre o conceito"
}
```

### 3.8 🔭 Analogia-ponte

**Propósito:** transferência. Mesmo padrão em domínio distante.
**UI primitive:** dois domínios lado a lado; aprendiz arrasta elementos do
domínio A para o B (compare-cases).
**Schema:**

```json
{
  "source_domain": {"name": "Sistema imune", "elements": [...]},
  "target_domain": {"name": "Senso crítico", "elements": [...]},
  "mapping": [{"from": "anticorpo", "to": "ceticismo"}],
  "transfer_question": "string"
}
```

Esta é uma das duas **lentes de fechamento** (ver §4).

## 4. Algoritmo de ordenação — `Lens::ChooseNext`

**Heurística-first**, aprendizado de banda como work-stream separado.

### Score base por concretude

Tabela ordenada do mais concreto ao mais abstrato (default opening):

```
1. narrativa
2. primeira-pessoa
3. histórica
4. científica
5. estatística
6. ética
7. engenharia
8. analogia-ponte
```

### Regras hard

1. **Variedade:** nunca dois tipos iguais consecutivos.
2. **Abertura:** primeira lente sempre do top-3 (concreto antes de abstrato).
3. **Fechamento:** missão só fecha quando uma das duas lentes de transferência
   (`analogia-ponte` ou `etica`) foi **completada com sucesso** na última
   posição.
4. **Cobertura mínima:** ≥ 4 tipos diferentes visitados antes de poder fechar.
5. **Cap absoluto:** 7 lentes. Se atingir 7 sem fechamento via transferência,
   força a próxima a ser `analogia-ponte` e encerra.

### Sinais adaptativos

Coletados por `Lens::ScoreVisit` ao fim de cada visita:

- `time_on_lens` — ms entre `opened_at` e `completed_at`
- `micro_check_correct` — bool
- `abandoned` — bool (fechou aba sem completar)
- `affective_signal` — payload de UI ("ficou difícil" / "curti")
- `prediction_delta` — para predict_reveal

Função de score (heurística simples, V1):

```
visit_quality = base_score(lens_type)
              + (micro_check_correct ? +1 : -1)
              + (abandoned ? -2 : 0)
              + (affective_signal == 'curti' ? +1 : 0)
              + (affective_signal == 'dificil' ? -1 : 0)
              - (time_on_lens > 4min ? 1 : 0)
```

Se `visit_quality < 0` para a lente recém-fechada e cobertura ainda baixa,
o próximo `ChooseNext` evita lentes do mesmo cluster de abstração e prefere
voltar a uma lente concreta complementar.

### Decisão: heurística vs bandit

**Recomendação: heurística-first**. O bandit (Thompson sampling sobre
`(concept_slug, lens_type, age_band) → engagement`) entra em **v5.1** assim
que tivermos ≥ 1k visitas/lente para tirar do nível de ruído. Cravar a
heurística como floor (com testes determinísticos) protege qualidade
pedagógica enquanto o bandit ainda é estatisticamente vazio.

## 5. Pokédex v5 — profundidade reformulada

`Academy::Pokedex::Advance` em `app/services/academy/pokedex/advance.rb` é
reescrita. Nova tabela de transições:

| Level | Nome           | Critério                                                |
|-------|----------------|---------------------------------------------------------|
| 0     | silhouette     | nunca visitada                                          |
| 1     | spotted        | ≥ 1 lente do conceito visitada (qualquer tipo)          |
| 2     | recognized     | missão completa (cobertura ≥ 4 tipos + fechamento OK)   |
| 3     | mastered       | ≥ 2 missões em subjects diferentes touching o conceito  |

A diferença chave em relação a v4: **L2 ≠ "uma missão qualquer concluída"** — é
"jornada cognitiva inteira atravessada". E L3 mantém a definição de
transferência (mas agora pode ser disparada pela própria lente de
analogia-ponte fechando em subject diferente, não só por
`Transfer::Detect`).

**Migração de `LearnerConcept` existentes**: rodar
`lib/tasks/academy_v5.rake academy:v5:recompute_pokedex` que reavalia cada
linha pela nova regra. Tipicamente downgrade L2→L1 quando o aprendiz só
viu o conceito uma vez no formato chat antigo; preserva L3 quando há real
cross-subject.

## 6. Pipeline de geração LLM

### Chave de cache

```
(concept_slug, lens_type, age_band, locale, prompt_version)
```

TTL: **forever**. Invalidação só por (a) bump de `prompt_version`,
(b) `Lens::Cache.purge!(...)` via admin, (c) curated override.

### Geração lazy + warmup

Fluxo de leitura no `Mission::Advance`:

```ruby
cached = Lens::Cache.find(concept:, lens_type:, age_band:, locale:)
return cached if cached
generated = Lens::Generate.call(concept:, lens_type:, age_band:, locale:)
return generated  # já gravado em academy_lens_cache
```

Job noturno `Lens::WarmCacheJob` (registrado em `config/recurring.yml`):

1. Identifica aprendizes ativos (login últimos 7d).
2. Para cada um, pega `Mission::Recommend.call(learner: ...)` (top-3).
3. Para cada missão recomendada, garante que todos os 8 tipos de lente
   estão pré-gerados para o `concept_id`.
4. Budget: cap de 200 gerações/noite (proteção de custo).

### Personalização

`Lens::Personalize` roda **na renderização**, não na geração. Toma o payload
do cache e substitui placeholders:

- `{{learner_name}}` → primeiro nome
- `{{sibling_or_friend}}` → nome de irmão se conhecido, senão "amigo"
- `{{family_context}}` → "lá em casa" / "na sua escola"

Nenhuma regeneração é feita por aprendiz — o cache é global.

### Quality gate

Cada `Lens::Generators::<Type>` envia um eval spec:

```
spec/services/academy/lens/generators/cientifica_eval_spec.rb
spec/services/academy/lens/generators/narrativa_eval_spec.rb
...
```

Que valida estruturalmente (schema válido) e por blacklist
(`["você sabia que", "reflita sobre", "como você se sente", "lição"]`).
Live LLM eval (`ACADEMY_LIVE_EVAL=1`) cobre 5 conceitos golden por tipo de
lente. Sem passar, a lente fica **dark-launched** (gera no cache mas
`ChooseNext` não a oferece).

## 7. UI/UX

### Mission stage

Sem chat thread. Sem balões. A missão é uma **sequência de lens stages**
em tela cheia (modal-style no mobile, layout próprio no desktop).

Topo da tela: **lens ring**, círculo de 4-7 ícones (um por lente da jornada
atual). Estados visuais:

- ativo: glow + scale 1.1
- completado: checkmark, color cheia
- locked/futuro: dimmed 30% opacity
- abandonado: tachado discretamente

Reaproveita tokens da Pokédex (CSS variables em
`app/assets/stylesheets/tailwind/theme.css`) — mesma paleta por
categoria de conceito.

### Por tipo de lente

| Lens          | UI primitive                                | Stimulus controller                |
|---------------|---------------------------------------------|------------------------------------|
| científica    | painel + micro-check                        | `lens_scientific_controller`       |
| narrativa     | card stack swipe                            | `lens_narrative_controller`        |
| ética         | split-screen + slider                       | `lens_ethics_controller`           |
| estatística   | predict slider → reveal animation           | `lens_predict_controller`          |
| engenharia    | drag-list                                   | `lens_engineering_controller`      |
| histórica     | timeline horizontal                         | `lens_timeline_controller`         |
| primeira-pessoa | instrução + cronômetro                    | `lens_embodied_controller`         |
| analogia-ponte | dois domínios + drag-mapping                | `lens_bridge_controller`           |

Cada lente tem orçamento de **90s** (alvo). Uma interação dominante. Sem
encadeamento de modais.

### Pokédex evolution

Continua via `pokedex_evolution_controller.js` existente
(`app/assets/controllers/pokedex_evolution_controller.js`) — quando uma
visita causa transição de nível, Turbo Stream dispara o pulse animation +
WebAudio chime. Reaproveita 100% do trabalho de PR1-PR4 da v4.

## 8. Migração v4 → v5

### Conteúdo

- **Missões v4**: para cada `Academy::Mission`, escolher o conceito-foco
  (heurística: primeiro `academy_aula_concept` por mission, ordem de
  criação). Setar `concept_id`. Dropar colunas `format`/`scenes_tree`/
  `sessions_count`/`teaser_for_next_mission_id`.
- **Lentes**: zero pré-geração inicial. `WarmCacheJob` cuida disso
  conforme uso.

### Progresso

- `MissionProgress` v4: marcadas com `migrated_from_v4: true` no
  `lens_journey_state`. Best-effort: inferir visitas de lente científica/
  narrativa a partir de `academy_messages` por mission (script offline em
  `lib/tasks/academy_v5.rake`). Aprendizes que reabrirem uma missão antiga
  começam do zero na nova jornada (decisão do usuário: clean refoundation).

### Sinais históricos preservados

- `academy_practice_wagers` → ainda referenciada por `predict_reveal` lens.
- `academy_learner_story_paths` → ainda referenciada por `narrativa`.
- `academy_virtue_sightings` → fonte para sinal de `etica` lens.
- `academy_transfer_detections` → trigger de L3 em paralelo a `bridge` lens.

### Pokédex

`lib/tasks/academy_v5.rake`:

```
academy:v5:recompute_pokedex   # reavalia LearnerConcept.level pela nova regra
academy:v5:assign_concept_id   # popula missions.concept_id, dropa aula_concepts
academy:v5:purge_dead_tables   # drop academy_sessions vazia, opt-in
```

`academy_sessions` e `academy_messages` permanecem como **read-only history**
durante o ciclo de release; `purge_dead_tables` roda em fase 2 quando
nenhum código novo as referencia.

## 9. Riscos, perguntas em aberto, fora-de-escopo

### Riscos

- **Variabilidade do LLM por lente**. Mitigação: prompt + eval gate +
  curated override admin + cache forever.
- **Custo run-time da primeira passagem**. Mitigação: cache global +
  warmup proativo + cap noturno.
- **Friction de UX**: kid tem que aprender 8 mini-formatos. Mitigação:
  cada lente é self-contained, single interaction, 90s budget, com
  micro-tutorial inline na primeira vez que o tipo aparece.
- **Lente histórica e ética dependem de dados externos sensíveis**
  (datas, casos morais). Mitigação: blacklist + curated mode para
  conceitos delicados.

### Perguntas em aberto

- **Digest parental**: como narrar lentes? Proposta: "Maria atravessou 5
  ângulos do conceito 'dopamina' esta semana — incluindo um dilema ético
  que ela revisitou duas vezes." O serviço `Academy::Digests::Compose`
  precisa ser reescrito para consumir `learner_lens_visits` em vez de
  sessions. **Flag para decisão**: granularidade do digest — por lente
  individual ou por missão fechada? Recomendação: por missão fechada
  (menos ruído ao pai), com link "ver detalhes" que expande lentes.
- **Lente ética em conceitos de saúde** (`glicose-pico`, `sono`): faz
  sentido ou força? Provavelmente sim — empurra para responsabilidade
  pessoal. Validar com 3-4 conceitos golden no eval.

### Fora de escopo (v5.1+)

- Pais recompensando aprendizado com pontos (mencionado no proposal §4).
- Lentes multiplayer (irmãos atravessando o mesmo conceito em sync).
- Voice input ou voice output.
- Bandit aprendido para `ChooseNext` (só depois de massa estatística).
- Editor visual de lente curated no admin (v5.0 expõe JSON editor; v5.1
  poderá ter visual builder).

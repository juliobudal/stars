# De onde vem a estrutura das aulas (lentes) do Academy

Documento de referência para sessões futuras. Mapeia as 4 camadas que
determinam o que o LLM pode (e não pode) gerar quando uma criança clica
em uma aula. Use este doc como ponto de entrada antes de propor
melhorias na qualidade pedagógica, no tom, na variedade ou na latência
das lentes.

**Versão deste doc:** 2026-05-17 (pós wire-up do LLM-as-judge v3)
**Status:** v4 em produção · v5 lens-missions em runtime

---

## TL;DR

Estrutura de uma aula = **catálogo (universo fechado de tipos) + schema
(forma da saída) + prompt ERB (conteúdo pedagógico + tom) + dados
curados no DB (subject/mission/concept)**. O LLM preenche detalhes
dentro dessa moldura; tudo o resto é determinístico.

```
┌─────────────────────────────────────────────────────────────────┐
│  CAMADA 1 — Catálogo (tipos fechados de lente)                  │
│  app/services/academy/lens/catalog.rb                           │
│  8 tipos: scientific, narrative, ethical, statistical,          │
│           engineering, historical, first_person, analogy_bridge │
├─────────────────────────────────────────────────────────────────┤
│  CAMADA 2 — Schemas JSON (forma da saída)                       │
│  app/services/academy/lens/schemas/*.json                       │
│  Validação estrita; falha → retry com erro no prompt            │
├─────────────────────────────────────────────────────────────────┤
│  CAMADA 3 — Prompts ERB (conteúdo + tom + anti-padrões)         │
│  app/services/academy/lens/prompts/*.md.erb                     │
│  Template renderizado com binding do concept + learner_context  │
├─────────────────────────────────────────────────────────────────┤
│  CAMADA 4 — Dados curados (o que ensinar)                       │
│  Academy::{Subject, Mission, Concept, LearnerContext}           │
└─────────────────────────────────────────────────────────────────┘
```

Cima restringe baixo. Schema rejeita LLM que foge da forma. Tone-regex +
Juiz rejeita LLM que foge do tom. Catálogo restringe que tipos existem.
Dados restringem o que de fato é ensinado em cada missão.

---

## Camada 1 — Catálogo

**Arquivo:** `app/services/academy/lens/catalog.rb`

Enum fechado dos 8 tipos de lente. Cada entry carrega:
- `prompt_template` — nome do arquivo ERB sob `prompts/`
- `schema_file` — nome do JSON schema sob `schemas/`
- `template_version` — string tipo `"scientific.v2"`; bump invalida o cache
- `temperature` + `max_tokens` — tuning de LLM por tipo (precisão vs criatividade)
- `ui_primitive` — qual componente kid-side renderiza
  (`predict_reveal`, `card_stack`, `compare_cases`, `predict_slider`,
   `drag_list`, `timeline`, `embodied_action`, `bridge_mapping`)
- `closure_eligible` — se o tipo pode fechar uma missão
  (hoje só `ethical` e `analogy_bridge`)

**O que kid vê** (`KID_ACTION_LABELS`): nunca o nome técnico, sempre uma
ação. Ex: scientific → "🔬 Como funciona", ethical → "⚖️ Você decide".

**Onde tunar:**
- Mudar criatividade vs precisão → mexer `temperature` por tipo
- Cortar verbosidade → reduzir `max_tokens` (hoje todos em 10k — pode
  baixar pra forçar concisão)
- Adicionar/remover tipo → mudança de código aqui + 2 arquivos novos
  (prompt + schema) + migration na check constraint de `lens_type`

---

## Camada 2 — Schemas JSON

**Diretório:** `app/services/academy/lens/schemas/`

Cada arquivo é JSON Schema draft-07 com `additionalProperties: false` e
`required` cobrindo todos os campos críticos. Tamanhos mínimos e máximos
em cada string forçam ritmo (frase curta, parágrafo curto).

**Exemplos de constraint pedagógica embutida no schema:**
- `scientific.json` exige `mechanism_steps` com **exatamente 3 items**
- `narrative.json` exige `scenes` com 3-5 cenas + personagem com nome,
  idade 6-18, e `trait` entre 15 e 120 chars
- Todos os `micro_check` exigem 3-4 opções, `correct_index` 0-3, e
  `rationale` ≥ 40 chars (não pode só repetir a resposta)

**Validação:** `Generators::Base#validate!` usa `json-schema` gem.
Schema falho → `SchemaInvalid` → retry **uma vez** com os erros do
schema no `retry_message`. Se a 2ª também falha → `fail_with(:llm_schema_invalid)`.

**Onde tunar:**
- Forçar mais concisão → baixar `maxLength` de campos descritivos
- Permitir variação → relaxar `minItems`/`maxItems` em arrays
- Adicionar campo opcional → cuidado: precisa atualizar prompt + view
- Mudar `template_version` em catalog.rb se o schema mudar (invalida
  cache automaticamente via `prompt_digest` — ver `Base#prompt_digest`)

---

## Camada 3 — Prompts ERB

**Diretório:** `app/services/academy/lens/prompts/`

Cada `.md.erb` segue um esqueleto canônico de 6 blocos:

1. **TAREFA** — "Gere UMA lente X sobre o conceito Y para aprendiz pt-BR
   de 8-14 anos"
2. **PROPÓSITO DIDÁTICO** — pedagogia específica do tipo
   - scientific: mecanismo puro, causa→efeito em 3 passos, sem metáfora dentro
   - narrative: personagem com idade + dilema + ação + resultado
   - ethical: dois lados ambos defensáveis, sem resposta pré-determinada
   - statistical: número específico + predição + razão
   - engineering: constraint que força tradeoff real
   - historical: data/lugar real + padrão atemporal
   - first_person: sensorial, embodied, micro-ação executável
   - analogy_bridge: A e B com mapping nomeado, não vago
3. **VOZ** — "Bill Nye + Mythbusters + Kurzgesagt + naturalista divertido"
   sobreposto ao system prompt d'O Guia (`Generators::Base::VOICE`)
4. **PROIBIDO** — anti-padrões explícitos: TED talk, moralização, "reflita
   sobre", "estudos mostram" sem fonte, slug interno na saída, metáfora
   no lugar errado, hedging vazio
5. **PERSONALIZAÇÃO** — `{{learner_name}}` / `{{sibling_or_friend}}` como
   placeholders verbatim (trocados em runtime por `Lens::InterpolatePayload`)
6. **SAÍDA** — referência ao schema + descrição dos campos + **few-shot
   example** completo (uma lente exemplar do mesmo tipo)

**Variáveis disponíveis no template** (de `Generators::Base#template_binding`):
- `concept` — `Academy::Concept` com `name`, `slug`, `definition`, `category`
- `age_band` — "kid" hoje
- `locale` — "pt-BR" hoje
- `learner_context` — `Academy::Lens::LearnerContext` (ver camada 4)
- `related_concepts` — array de nomes de conceitos próximos
- `mastery_tier` — "novato" | "avançado" | "any"
- `difficulty_hint` — string adaptativa por kid
- `adaptive_hint` — string adaptativa por kid

**System prompt geral** (`Generators::Base::VOICE`, base.rb:22-37):
define o tom global ("PROIBIDO: tom de TED talk infantil, moralização
direta…") e o contrato de saída (JSON puro, sem fences, placeholders
preservados verbatim).

**Onde tunar:**
- Mudar pedagogia de um tipo → editar o respectivo `.md.erb`. O
  `prompt_digest` muda automaticamente (SHA do prompt + schema) e
  invalida o cache sem bump manual de `template_version`.
- Mudar tom global → editar `Generators::Base::VOICE` (afeta os 8 tipos)
- Adicionar anti-padrão duro → adicionar regex em
  `Generators::Base::FORBIDDEN_TONE_PATTERNS` (rejeição barata sem
  precisar de juiz)
- Few-shot novo → trocar o exemplo no fim do prompt ERB. **Alavanca de
  qualidade subestimada** — o exemplo é o âncora visível mais forte.

---

## Camada 4 — Dados de domínio (DB)

**Modelos:** `app/models/academy/`

- **`Academy::Subject`** — 7 áreas de formação humana
  (criar/listar via parent dashboard). Carrega `color`, `icon`, `slug`.
- **`Academy::Mission`** — uma "aula" curada por um pai/admin via
  parent dashboard. Aponta para um `Academy::Concept`. Carrega
  `title`, `hook`, `learning_objective`, `source` (origem da sacada),
  `framework`, `sacada` (sacada central esperada).
- **`Academy::Concept`** — **o que de fato é ensinado**. Campos críticos
  que viram variáveis no ERB:
  - `name` — usado no prompt
  - `slug` — banido da saída (anti-vazamento)
  - `definition` — referência interna mostrada ao LLM como "DEFINIÇÃO DE
    REFERÊNCIA (uso interno, não copie)"
  - `category` — cognitivo / ético / social / etc.
  - `pokedex_color_key` — afeta UI, não conteúdo
- **`Academy::Lens::LearnerContext`** — value object calculado por
  kid+concept. Define mastery_tier, related concepts, hints adaptativos.
  É a única coisa que varia entre dois kids no mesmo concept+lens_type
  (e por isso o cache compartilha por bucket, não por kid).

**O cache (`Academy::LensCache`)** é shared por:
```
(concept_id, lens_type, age_band, locale, template_version,
 mastery_tier, prompt_digest)
```
Ou seja: **uma curadoria do juiz beneficia todos os kids do mesmo
bucket**. Mudou prompt? `prompt_digest` muda automaticamente, cache
antigo fica órfão (não é deletado — fica lá pra auditoria).

**Colunas de telemetria do juiz** (adicionadas 2026-05-17):
`judge_verdict`, `judge_overall_score`, `judge_revision_cycles`,
`judge_critique`. Permitem rodar queries tipo "lentes shipped com
verdict=REVISE" pra regerar em batch.

---

## Fluxo runtime — cold path (kid clica aula, cache miss)

```
1. Kid clica → Kid::Academy::MissionsController#show
2. Academy::Missions::Begin
   ↓
3. Academy::Lens::ChooseNext escolhe lens_type
   (heurística determinística sobre histórico do kid + estado da missão —
    NÃO é LLM)
   ↓
4. Academy::Lens::Generate
   a. prompt_digest = SHA256(prompt_template + schema)[0..8]
   b. Lookup em LensCache por (concept, lens_type, age_band, locale,
      template_version, mastery_tier, prompt_digest)
   c. CACHE HIT → retorna (sub-100ms) ✨
   d. CACHE MISS → segue
   ↓
5. Generators::{Scientific|Narrative|…}#call
   ↓
6. Generators::Base#attempt (loop até 1 retry + 1 ciclo do juiz)
   a. ERB renderizado com binding
   b. LLM call (DeepSeek via OpenRouter) com system=VOICE + user=prompt
   c. parse_json! → enforce_tone! (regex) → validate! (schema)
   d. run_judge → gpt-5-nano avalia 6 pilares
   e. Se REVISE/FAIL + ciclo disponível → regen com rewrite_hint
   f. ok(payload + judge_metadata)
   ↓
7. Academy::Lens::Generate upsert no LensCache
   ↓
8. Lens::InterpolatePayload troca {{learner_name}} pelo nome real
   ↓
9. View renderiza (ui_primitive do catálogo decide qual partial)
```

**Latência típica:**
- Cache hit: <100ms
- Cache miss, PASS no 1º giro: ~6-10s (1 LLM call grande + 1 juiz pequeno)
- Cache miss, REVISE→PASS: ~12-20s (2 LLM calls + 2 juízes)
- Worst case (FAIL no ciclo final): ~32s

O **overlay com pílulas de sabedoria** (entregue na mesma sessão do juiz)
cobre toda essa janela com mensagens progressivas + citação fixa pra criança ler.

---

## O LLM-as-judge (v3, wirado em 2026-05-17)

**Arquivos:**
- `app/services/academy/llm/judge.rb` — chamada à gpt-5-nano, parse, Verdict
- `app/services/academy/llm/judge_persona.rb` — rubrica completa

**Rubrica (6 pilares + âncora moral):**
1. **Gancho** — abertura prende, não define
2. **Fidelidade ao conceito** — ensina o conceito declarado, não deriva
3. **Encaixe 7-12 anos** — vocab + cenário cabem na faixa
4. **Concretude / imagem mental** — cria cena, não claim abstrata
5. **Voz d'O Guia** — autoritativo + misterioso + fascinado, não professor
6. **Micro-check** — aplicação em situação nova, não memória
+ **Âncora moral** (gate independente) — valores cristãos respeitados,
   citações bíblicas contextuais

**Regras de verdict:**
- PASS = overall_score ≥ 8 E nenhum pilar com 0 E moral_anchor_ok
- REVISE = 5-7, OU 1 pilar com 0
- FAIL = ≤4, OU 2+ pilares com 0, OU moral_anchor_ok=false

**Ciclo:** gerar → julgar → se REVISE/FAIL com ciclo restante, regerar
com `rewrite_hint` → ship. Default: **1 ciclo de revisão máximo**
(config `Academy.config.judge_max_revision_cycles`).

**Failure-leniente:** juiz indisponível (timeout/erro) → lente é
**enviada com `judge_verdict="skipped"`**. Nunca bloqueia o kid.

**Onde tunar:**
- Calibração mais/menos exigente → mudar regras de verdict em
  `judge_persona.rb` (PASS ≥ N)
- Mais ciclos = mais qualidade, mais lento → subir
  `judge_max_revision_cycles` (cuidado com UX)
- Desligar globalmente → `ACADEMY_JUDGE_ENABLED=false`
- Mudar modelo do juiz → `ACADEMY_JUDGE_MODEL=…` (qualquer modelo
  OpenRouter aceito; tem que suportar `reasoning.effort`)
- Adicionar pilar novo → editar `JudgePersona::VOICE` (rubrica) +
  `Judge::PILLAR_KEYS` (parsing) + spec

---

## Anti-padrões e gates atuais

Em ordem de severidade (mais barato → mais caro):

1. **`FORBIDDEN_TONE_PATTERNS`** (regex em `Generators::Base`) —
   blacklist heurística. Rejeição grátis. Hoje cobre:
   `"deixa eu te contar uma coisa importante"`, `"reflita sobre"`,
   `"como você se sente"`, `"é importante ser/que/fazer/aprender"`,
   `"você sabia que"`, `"aprenda que"`, `"estudos mostram"`.
2. **Schema JSON** — rejeita forma errada, força tamanhos certos.
   Custo: zero (validação local).
3. **LLM-as-judge** — rejeita pedagogia fraca. Custo: 1 LLM call extra
   por lente (gpt-5-nano, ~$0.0006).
4. **`FlagLowQuality`** — gate reativo. Quando 3+ kids erram o
   micro_check da mesma `lens_cache` em 7 dias, marca `quality_flagged=true`
   e força regeneração para o próximo. Custo: zero antes; LLM call na
   regen.

---

## Backlog / oportunidades de melhoria conhecidas

Lista viva — adicione conforme aparece. Estas são as alavancas com
maior retorno esperado, ordenadas por ROI:

### Alto retorno
- **Re-judge offline em batch** dos rows com `judge_verdict=skipped` ou
  REVISE/FAIL shipped. Job rodando à noite. Já temos a coluna; falta o job.
- **Calibrar regras de verdict** com 50-100 julgamentos reais. A
  calibração atual (PASS ≥ 8/12) é palpite — pode estar permissiva ou
  rígida demais. Vale rodar `Lens::Generate` em batch para os concepts
  já existentes, exportar veredictos, e decidir.
- **Renovar few-shots dos prompts** com lentes que receberam PASS
  do juiz. Hoje os exemplos foram escritos à mão e podem estar
  desatualizados em relação ao tom atual.

### Médio retorno
- **Variedade pedagógica**: hoje cada lens_type tem 1 prompt fixo. Variar
  o exemplo few-shot pode aumentar diversidade sem mexer no schema.
- **`Lens::ChooseNext`** hoje é heurística simples. Vale revisar se a
  sequência de lens_types está realmente otimizada para retenção
  (telemetria de `LensSignal` ajuda).
- **Personalização adaptativa**: `LearnerContext` calcula hints mas
  pouco prompt usa de fato. Vale revisar se os ERBs estão tirando
  proveito.

### Baixo retorno / depende de produto
- Adicionar novos lens_types (custo alto: 2 arquivos + migration + UI
  primitive + spec)
- Multi-locale (en-US, es-ES) — `locale` já é parte do cache key,
  mas só pt-BR está populado

---

## Como pedir uma melhoria na próxima sessão

Para acelerar a próxima sessão, descreva o problema em termos das
camadas. Exemplos de pedidos bem-formados:

- *"Quero que lentes `narrative` tenham personagens mais diversos —
   hoje quase sempre são meninos de 10 anos. Mexe no prompt
   (`prompts/narrative.md.erb`) e no exemplo few-shot."*
- *"O juiz está aceitando lentes que abrem com definição. Endurecer o
   pilar 'gancho' do `JudgePersona` ou adicionar regex no
   `FORBIDDEN_TONE_PATTERNS`?"*
- *"Schema do `ethical` permite cenas curtas demais — `case_a.text`
   mínimo 40 chars não dá cena. Subir pra 100?"*
- *"Cold start ainda demora 20s. Vale tentar gerar lente com modelo
   mais rápido (groq llama, gemini flash) e judgar com gpt-5-nano,
   ou cortar o ciclo do juiz?"*
- *"Lentes geradas com `judge_verdict=skipped` estão acumulando.
   Implementa o job de re-judge noturno."*

Se o pedido for vago ("melhore as aulas"), o próximo passo é abrir
este doc, pegar 1 lente real do banco com `judge_verdict=REVISE`, ler
a `judge_critique`, e decidir qual camada mexer.

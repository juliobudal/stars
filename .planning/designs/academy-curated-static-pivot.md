# Academy — pivot pra conteúdo estático curado (LLM como tool de autoria, não runtime)

> Data: 2026-05-18
> Postura: virada arquitetural maior. Documento de decisão + roadmap.
> Antecedentes: `academy-bestseller-pattern.md` (didactic moves) · `academy-v4-spec.md` · refactor de tom Lens v5 (2026-05-18)
> Decisão: pendente confirmação final do produto owner

## Decisão proposta

**Padrão = aulas (lens payloads) pre-criadas e curadas, persistidas como dados estáticos no codebase.** LLM continua disponível pra geração mas reservado a **casos eventuais** (variantes especiais, geração ad-hoc, expansão pós-launch). Runtime serve conteúdo curado em 95%+ das interações.

## Por que (não retórica — análise honesta)

O bestseller-pattern que estamos importando como inspiração estrutural É curadoria, não geração on-demand. Carnegie escreveu cada capítulo uma vez. Clear escreveu cada lei uma vez. LLM-runtime nunca foi parte daquele paradigma; foi um atalho de escala que tem custo de qualidade.

| Argumento pró | Peso |
|---|---|
| Quality control absoluto — currículo pra 7-14 anos, custo de aula ruim é altíssimo | Alto |
| Coerência paradigmática com bestseller (estático por design) | Alto |
| Custo recorrente zero em LLM tokens | Médio-Alto |
| Velocidade — instantâneo, sem loading 3-15s | Alto |
| Iterabilidade — corrige uma vez, todo kid recebe | Médio |
| Auditável pré-launch — toda aula passa por curador antes de ir | Alto |
| Brand voice trancada — não driftaa em produção | Alto |

| Argumento contra / custo | Peso |
|---|---|
| Esforço de autoria — ~300 payloads se subset, ~1000 se completo | Alto |
| Personalização fina perdida (placeholder substitution preservada) | Baixo |
| Expansão mais lenta — conceito novo = curar antes de servir | Médio |

**Veredito:** sim, é o caminho. 45 conceitos é humanamente tratável; o LLM era ponte, não destino.

## O que muda arquiteturalmente

| Componente | Antes | Depois |
|---|---|---|
| Subjects/Trails/Missions | curados (seeds) | curados (seeds) — **auditar** |
| Concepts (definition + essence) | curados (essence parcial) | curados (essence COMPLETO) |
| **Lens payloads** | **LLM-runtime, cached** | **CURADO, seeded, estático** |
| Llm::Generators::* | ativo runtime | **vestigial** ou ferramenta de DRAFT pra curador |
| Llm::ExamplePicker | runtime few-shot | vestigial |
| Llm::Judge | runtime gate | **PRE-LAUNCH QA tool** (rake task) |
| Lens prompts (.erb) | prompt do LLM | **SPEC pro curador humano** |
| Lens schemas (.json) | validate LLM output | validate curated content (essencial) |
| Lens::Generate orchestrator | sempre LLM | branch: curated-first, LLM fallback |

**Nada do refactor desta semana foi desperdiçado.** Templates viram spec pra curador. Judge vira pre-launch QA. Generators viram drafter. Tudo é repurpose, não throwaway.

## Pipeline em 4 fases

### Fase 1 — Auditoria das 34 missões existentes

Pra cada missão em `db/seeds/academy.rb`, ranquear contra critérios:

| Critério | Threshold |
|---|---|
| TESTE DE ÚTIL | nomeia fenômeno kid 8-14 já meio-percebe |
| `central_insight` | existe? formato sticky ("se X então Y") |
| `concept.the_essence` | populado? (34/45 faltam) |
| `curiosity_facts` | 2-3 contraintuitivos com fonte |
| `challenge_prompt v4` | aposta numérica observável |
| `source` | autor/estudo real nomeado |
| **PROMESSA AO KID** | missão é compatível com quais lentes do catálogo (não toda missão pede todas as 8) |
| Equilíbrio de área | área tem 5+ missões ou está thin? |

**Output:** planilha priorizada ÚTIL / RETOQUE / CORTAR + lista de gaps.

### Fase 2 — Scaffolding antes dos payloads

Antes de escrever ~300 payloads, fechar o ground:

1. Popular 34 `the_essence` faltantes (one-liners padrão dos 11 já curados)
2. Reescrever `central_insight` das missões que falharam no audit
3. Substituir `source` genéricos por autor real
4. **Mapear `mission × lens_types_assigned`** — define escopo real de payloads (não todas as 8 lentes pra toda missão; ex.: "palavra dada" não cabe em `statistical`)

**Output:** scaffolding pronto + tabela de escopo (~300-500 payloads, não 1000).

### Fase 3 — Criação dos payloads (LLM-drafts-human-approves)

Workflow por payload:

```
1. LLM drafta (via Lens::Generators existente — vira rake task de autoria)
2. Judge valida factual/conceito/segurança (pre-launch, não runtime)
3. Curador edita (afia tom, ajusta exemplos brasileiros, troca quando driftou)
4. Spec valida contra lens/schemas/{type}.json
5. Commit como JSON em db/seeds/academy_lens_payloads/{lens_type}/{mission_slug}.json
6. Seeder popula academy_lens_payloads (nova tabela) com source: "curated"
```

Ritmo realista: 5-10 payloads/dia por curador solo. ~300 payloads = 6-12 semanas.

### Fase 4 — Runtime adapta

`Lens::Generate` ganha branch:

```ruby
def call
  curated = LensPayload.find_by(mission_id: ..., lens_type: ...)
  return ok(payload: curated.payload, source: "curated") if curated
  
  # Fallback — eventual LLM generation pra casos não-curados
  legacy_llm_generation(...)
end
```

95%+ das requisições passam pelo path curado. LLM preservado pra eventualidades.

## Ordem de execução

| Sprint | Foco | Saída |
|---|---|---|
| 0 (este doc) | Documentar a virada + alinhar | Doc + decisão registrada |
| 1 | Auditar 34 missões (Fase 1) | Planilha priorizada |
| 2 | Mapping mission × lens (Fase 2.4) | Tabela de escopo |
| 3 | Popular essence + reescrever insights fracos (Fase 2.1-2.3) | Seeds atualizados |
| 4 | **Pilot: Mente Forte / Atenção** (4 missões × ~6 lentes = ~24 payloads). Valida pipeline | Trilha completa shipable |
| 5+ | Escalar trilha por trilha | Currículo curado completo |
| 6 (paralelo) | Branch curated-first em Lens::Generate | Código atualizado |

## Considerações críticas

1. **Recall com curados funciona MELHOR** — curador desenha variantes complementares deliberadamente.
2. **`{{learner_name}}` preservado** — é placeholder substitution, não geração.
3. **Variedade controlada** — uma missão pode ter 2-3 variantes do mesmo lens_type; ChooseNext escolhe.
4. **Cache atual deve ser truncado** — rows gerados sob voz antiga ficam órfãos sob nova régua.
5. **i18n fica mais fácil** — estático = traduzível direto, sem re-gerar por locale.
6. **Marketing/transparência** — currículo estático pode virar brochura pra parents.
7. **Custo de autoria** — se solo, planejar 2-3 meses; alternativa: contratar curador editorial ou batching com agentes Sonnet.

## Roles após o pivot

| Stakeholder | Role |
|---|---|
| **Curador (humano)** | Owner da voz e da qualidade. Lê drafts, edita, aprova. Atualiza essence/insight quando precisa. Decide mission × lens mapping |
| **LLM (drafter)** | Cospe primeiro rascunho seguindo templates. Acelera autoria. Nunca chega direto ao kid sem revisão humana |
| **Judge** | QA gate pré-merge. Roda em rake task. Bloqueia commits com hallucination/drift/safety issue |
| **Runtime** | Serve payload curado se existe; LLM-fallback pra eventualidades |

## Histórico

- 2026-05-18 v1: documentado como virada arquitetural. Pendente confirmação do produto owner antes de iniciar Sprint 1.

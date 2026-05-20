# B — Curar closure lenses para os concepts ativos

> **Objetivo.** Restaurar a parte do desenho pedagógico v4 que hoje só roda
> em 9.5% das missões: o **closure lens** (`analogy_bridge` ou `ethical`),
> que é o momento em que o aluno **transfere o conceito pra outro domínio**.
> Sem isso, "pílula" vira "leitura" — entra na cabeça mas não consolida.

> **Status.** Este plano é a continuação direta do **G-1** documentado em
> `.planning/designs/academy-gaps-2026-05-19.md`. Aqui detalho a execução
> e o critério de aceite operacional, não a justificativa (já está lá).

## Motivação (resumida — ver gaps-doc para profundidade)

Banco (2026-05-19, ainda válido em 2026-05-20):
```
missions ativas .................................. 42
missions cujo concept tem ≥1 closure lens curada ... 4  ← 9.5%
missions hoje terminando em 3 stages curtos ........ 38 ← 90.5%
```

A `Lens::ChooseNext` foi corrigida pra parar de 503 quando não acha closure
— mas o atalho `:curated_coverage_complete` é rendição: o kid sai sem ter
visto a sacada de transferência.

Para o objetivo deste portfólio (pílulas que ensinam), o closure é
**o componente que faz a pílula virar inteligência transferível** em vez
de um fato isolado.

## Escopo

**Entra:**
- ~31 payloads curados (em JSON contra schema) para os concepts ativos
  hoje sem closure.
- Decisão por concept: `analogy_bridge` ou `ethical`, conforme tabela
  pré-estabelecida no gaps-doc.

**NÃO entra:**
- Cobertura dos concepts dormentes (sem nenhum payload curado) — esses
  esperam B + A.
- Mudança na `Lens::ChooseNext` (já está OK).
- Spec G-2 (validação de trail unlock + atlas card) — outro plano.

## Trabalho

### Passo 1 — Inventário inicial (10 min)

Rodar no console (`make c`):
```ruby
active = Academy::Mission.where(active: true).pluck(:concept_id).uniq
closed = Academy::LensCache.where(
  source: "curated",
  age_band: "kid", locale: "pt-BR",
  lens_type: %i[analogy_bridge ethical]
).distinct.pluck(:concept_id)
to_curate = Academy::Concept.where(id: active - closed).order(:category, :slug)
to_curate.pluck(:slug, :category)
```

Salvar essa lista no topo deste arquivo como appendix (substituir o
placeholder abaixo) antes de começar a curar.

### Passo 2 — Atribuir tipo (analogy_bridge vs ethical)

Aplicar a tabela do gaps-doc (`G-1 — Curar closure lens`):

| Categoria do concept | Default closure |
|----------------------|-----------------|
| cognitivo            | `analogy_bridge` |
| saude                | `analogy_bridge` |
| tecnologia           | `analogy_bridge` |
| cientifico           | `analogy_bridge` |
| financeiro           | `ethical`        |
| virtude              | `ethical`        |
| social               | `ethical`        |
| (novos: mundo/corpo/palavras de A) | `analogy_bridge` |

Manter como override por concept caso o curador veja melhor encaixe.

### Passo 3 — Workflow de curadoria

Para cada concept:
1. Ler `definition` + `the_essence` + revisar 1-2 lentes não-closure já
   curadas para esse concept (pra calibrar tom e nível).
2. Escolher domínio-fonte concreto e nomeado:
   - `analogy_bridge.source_domain`: tem que ser **algo que kid já
     conhece** (escovar dente, andar de bicicleta, jogo de cartas).
   - `ethical.case_a` / `case_b`: tem que ser **dilema escolar/familiar
     real** com dois lados defensáveis.
3. Escrever o JSON contra o schema correspondente (`schemas/analogy_bridge.json`
   ou `schemas/ethical.json`).
4. Salvar em
   `db/seeds/academy_lens_payloads/{analogy_bridge|ethical}/<concept-slug>.json`.
5. Rodar `make seed` parcialmente para validar o JSON contra schema
   (o seeder em `db/seeds/academy_lens_payloads.rb:54` valida antes de
   upsert).

### Passo 4 — Calibração com juiz (opcional mas recomendado)

Após curar 5-10, rodar o juiz offline contra esses payloads:
```ruby
Academy::LensCache.where(source: "curated", concept_id: <ids_curados>)
                  .each { |c| Academy::Llm::Judge.call(payload: c.payload, lens_type: c.lens_type, concept: c.concept) }
```
Calibra: se 3+ vierem `REVISE`, o tom do curador está abaixo do esperado —
ajustar antes de continuar com os outros 20.

### Passo 5 — Lote final

Curar os restantes em lotes de ~10 (~30 min cada).

## Critérios de aceite

1. `Academy::LensCache.curated.where(age_band:'kid', locale:'pt-BR',
   lens_type: %i[analogy_bridge ethical]).distinct.pluck(:concept_id).size`
   == `Academy::Mission.active.distinct.pluck(:concept_id).size`.
2. Replay manual de 5 missões aleatórias termina com closure lens visível
   (não com `:curated_coverage_complete`).
3. Spec system existente passa: `spec/system/academy/missions_spec.rb`.
4. `make rspec` verde.

## Riscos

- **Tom escorregando para moralização** no `ethical`. Mitigação: cada
  curador roda o juiz no próprio payload antes de commitar (passo 4).
- **`analogy_bridge` superficial** ("hábito é como dente" sem mapping
  nomeado). Mitigação: schema exige `mapping[].from/.to` — usar essa
  estrutura como **força criativa**, não como check-list.

## Estimativa

- ~30 min por payload × 31 = **~15h**.
- Cabe em 2-3 sessões, divididas por subject/categoria.

## Dependências

- **Nenhuma** técnica — pode começar amanhã.
- Conflita com **A** no sentido que A cria 30 conceitos novos que também
  precisarão de closure — fazer A primeiro evita re-trabalho de ordem
  (curar dois lotes em vez de um). Mas pode rodar em paralelo se o
  curador tiver foco.

## Appendix — concepts a curar (preencher após Passo 1)

```
<rodar query do Passo 1 e colar aqui>
```

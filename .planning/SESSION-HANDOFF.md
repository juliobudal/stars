# Session Handoff — Academy Curated-Static Pivot

> Data: 2026-05-18
> Sessão anterior: implementação do pivot + pilot Trilha Atenção + 3 gates + fixes de specs
> Próxima sessão: ler este doc primeiro, depois `.planning/designs/academy-curated-static-pivot.md` e `.planning/designs/atencao-pilot-scope.md`

## Estado em 1 parágrafo

O pivot arquitetural para conteúdo curado-estático está **completo e funcional na trilha de Atenção** (4 missões, 26 payloads). Migration + seeder + runtime curated-first + ChooseNext curated-aware + Begin fallback curated-aware + PrewarmNextJob curated-aware. UI tem modo de revisão que mostra a resposta dada + reveal aberto em vez de travar. Suite: **890/0 passando**. Pronto pra escalar pra próximas trilhas ou pra editorial humano nos 26 payloads existentes.

## O que está em produção (mergeável)

### Pipeline curated-static
- **Migration `20260518000002_add_source_to_academy_lens_cache`** — coluna `source: 'curated'|'llm'`, default `llm`
- **`Academy::LensCache`** — scopes `.curated` / `.llm`, validação `inclusion`
- **`Academy::Lens::Generate#call`** — curated-first lookup antes do path LLM; transparente pra controllers
- **`db/seeds/academy_lens_payloads.rb`** — seeder idempotente que lê `db/seeds/academy_lens_payloads/{lens_type}/{slug}.json`, valida schema + tom + forbidden_terms, upserta com `source=curated`, `judge_verdict=approved_human`
- **`lib/tasks/academy_lens.rake`** — 3 tasks: `draft[mission,lens]`, `draft_trail[trail]`, `coverage`

### Gates de qualidade
- **A (Tom)** — Seeder portou `FORBIDDEN_TONE_PATTERNS` do `Generators::Base` + `forbidden_terms_list` por concept. Aborta no seed se violar.
- **B (Fato)** — Cross-check via WebSearch dos 7 claims mais arriscados. 5 erros corrigidos (Tristan 2015 ✓, Gloria 47s era 2016 ✗, James Clear dedos invenção ✗, Franklin autobiografia 1791 ✗, Brain Drain 26% inventado ✗, pickups/dia n=200 não 1300 ✗).
- **C (UI smoke)** — `ApplicationController.renderer` headless renderiza os 6 partials × 8 lens types × 2 modos (live + review) sem erro.

### ChooseNext, Begin, PrewarmNextJob curated-aware
Antes do fix, mesmo com 26 payloads, ChooseNext escolhia tipos não-curados → Generate fallback LLM. Agora todos respeitam o `curated_set` da missão. Dentro da trilha Atenção, **zero rotas possíveis pro LLM**.

### Review mode UI
- **`review_lens.html.erb`** passa `review_mode: true, signal_payload: visit.signal_payload`
- 6 partials atualizados pra aceitar e renderizar: predict (slider pré-preenchido), micro_check (correta destacada + "Você acertou/errou"), compare (reveal aberto), embodied (badge "completou"), engineering (consequência calculada + outras combos em `<details>`), narrative (cenas todas desbloqueadas)
- Strings kid-facing renomeadas: `lente` → `lição` em atlas chip, review banner, review overview

### Bugs pré-existentes corrigidos
- `Digests::Compose` brittle em segunda — `travel_to(Wednesday)`
- `RecallReminderJob` test DB sujo — `before(:each)` truncate Academy tables global em `rails_helper.rb`
- Motion a11y `.ls-loading-dot` ignorava reduced-motion — CSS reordenado + `!important`
- PWA spec hardcoded `v1` vs real `v5` — regex
- Repeatable missions race Turbo/modal DOM — `have_css(..., visible: false, wait: 5)`

## Arquivos criados/alterados nesta sessão

```
NOVOS:
  .planning/designs/academy-curated-static-pivot.md  (doc do pivot — pré-sessão, gerado antes)
  .planning/designs/atencao-pilot-scope.md           (mapping mission × lens)
  db/migrate/20260518000002_add_source_to_academy_lens_cache.rb
  db/seeds/academy_lens_payloads.rb                  (seeder + tone enforcement)
  db/seeds/academy_lens_payloads/{lens_type}/*.json  (26 payloads)
  lib/tasks/academy_lens.rake                        (draft/coverage rake tasks)

ALTERADOS:
  app/models/academy/lens_cache.rb                   (SOURCES + scopes)
  app/services/academy/lens/generate.rb              (curated-first lookup)
  app/services/academy/lens/choose_next.rb           (curated-aware rotation + force_close)
  app/services/academy/missions/begin.rb             (fallback walka só curated)
  app/jobs/academy/lens/prewarm_next_job.rb          (skip non-curated)
  app/views/kid/academy/missions/review_lens.html.erb (passa review_mode)
  app/views/kid/academy/missions/_lens_*.html.erb    (6 partials: review_mode support)
  app/views/kid/academy/missions/review.html.erb     (lente → lição)
  app/views/kid/academy/atlas/_concept_chip.html.erb (lente → lição)
  db/seeds/academy.rb                                (carrega o novo seeder)
  spec/rails_helper.rb                               (TimeHelpers + Academy table cleanup)
  app/assets/stylesheets/tailwind/base.css           (reduced-motion order fix)
  spec/system/pwa_install_spec.rb                    (regex cache version)
  spec/services/academy/digests/compose_spec.rb      (travel_to Wednesday)
  spec/system/kid/repeatable_missions_spec.rb        (wait for modal DOM)
```

## Cobertura atual

```
Trilha 'atencao' (Mente Forte):
  celular-difícil-parar      7/8 lentes curadas (sem historical)
  notificacoes-custam-23-min 6/8 (sem historical, ethical)
  foco-profundo-25min        6/8 (sem historical, ethical)
  habito-2-minutos           7/8 (sem ethical) — única com historical
  Total: 26 payloads
```

Outras 46 missões (50 - 4): **não cobertas** ainda. ChooseNext fallback pro path legacy (LLM) para essas.

## Débitos conhecidos — priorizar por valor/esforço

### Alto valor, médio esforço
1. **Editorial humano nos 26 payloads** — eu escrevi tudo em ~1h. Voz Duolingo+Guia, exemplos brasileiros, ritmo merecem passagem de quem tem o tom na ponta. Mecanicamente passou (schema, tom, forbidden, fact-check parcial); estética é olho humano.
2. **Smoke visual real em browser** — só fiz headless. Abrir `/kid/academy` no Chrome em modo retrato (kid layout), navegar uma missão completa, revisitar via `/visits/:visit_id`, confirmar layout/animação/spacing.
3. **`forbidden_terms_list` vazio em 3/4 concepts** — só `dopamina` tem termos. `switch-cost`, `deep-work`, `regra-dos-2-min` têm `[]`. Tone check fica fraco até popular.

### Alto valor, alto esforço
4. **Judge LLM real** — sem `OPENROUTER_API_KEY` no dev. Cross-check verifica 7 claims; outros (William James 1890, "1000+ engenheiros Google", "600k palavras Clear") não passaram pelo Judge factual. Setar a key e rodar `Academy::Llm::Judge` contra todos os 26 payloads.
5. **Escalar pra outras 46 missões** — Sprint 5 do pivot doc. Próxima trilha lógica: `vies-cerebro` (Mente Forte, trilha 2) → 3 missões × ~6 lentes = ~18 payloads. Depois Corpo & Saúde.

### Médio valor, baixo esforço
6. **2-3 variantes por (mission × lens)** — hoje 1:1. Spaced-repetition repete o mesmo payload. Pivot doc prevê variantes (`ChooseNext.choose_variant`).
7. **Truncar `academy_lens_cache` rows antigas** — qualquer row `source=llm` gerada antes do pivot tem voz pré-Lens v5. Quando essas missões forem curadas, deletar as órfãs LLM.

### Baixo valor
8. **i18n** — pt-BR only por enquanto. Curated-static facilita tradução (sem regeneração por locale).
9. **System specs flaky** — 55 specs `type: :system` passam isolados mas têm timing issues Chrome+Turbo em suite. Não causados pelas minhas mudanças. Investigar quando crescer impacto.

## Como continuar em próxima sessão

### Caminho A — Editorial polish
1. Curador humano lê `db/seeds/academy_lens_payloads/*/celular-difícil-parar.json` (7 arquivos, todas as lentes da missão mais carregada)
2. Edita prosa, fixa drift, adapta exemplos brasileiros
3. `make seed` revalida schema + tom
4. Browser real: completa a missão, abre review_lens, valida visual

### Caminho B — Escalar para `vies-cerebro` (próxima trilha)
1. Cria `.planning/designs/vies-cerebro-pilot-scope.md` no mesmo formato de `atencao-pilot-scope.md`
2. Para cada missão da trilha, mapeia mission × lens
3. Escreve payloads em `db/seeds/academy_lens_payloads/{lens_type}/{slug}.json`
4. `make seed`
5. `rake academy:lens:coverage` confirma

### Caminho C — Ativar Judge factual real
1. Setar `OPENROUTER_API_KEY` no `.env`
2. Criar rake task `academy:lens:judge_curated` que itera `LensCache.curated`, roda `Llm::Judge`, persiste `judge_verdict`
3. Reportar verdicts `needs_revision` para curador humano

## Comandos úteis de partida

```bash
make dev-detached                              # sobe stack
make seed                                       # carrega curados (idempotente)
make rspec ARGS="spec/services/academy/lens/"   # tests do lens layer
docker compose exec web bin/rails academy:lens:coverage  # status atual
docker compose exec web bin/rails runner '
  m = Academy::Mission.find_by(slug: "celular-difícil-parar")
  Academy::LensCache.curated.where(concept_id: m.concept_id).pluck(:lens_type)
'                                               # smoke individual
```

## Risco principal a vigiar

A pipeline funciona end-to-end **dentro da trilha Atenção**. Quando o kid abrir uma missão fora dela (qualquer das outras 46), o caminho legacy LLM é acionado. Sem `OPENROUTER_API_KEY`, isso falha silenciosamente — o controller renderiza `v5_placeholder` com status 503. Comportamento esperado pré-curadoria, mas pode confundir kid testando. Considerar gate de produto: missões não-curadas aparecem desabilitadas no índice ("em breve") até serem curadas.

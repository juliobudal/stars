# Academy Lens v3 — Plano de Finalização da Branch

**Data:** 2026-05-19
**Branch:** `feat/academy-lens-v3-completion`
**Escopo:** fechar os 3 itens não-deferidos do `academy-migration-cleanup-plan.md` antes do PR.
**Não-escopo:** itens 5.1 (LearnerRanks), 5.3 (T-045 atlas edges), 7.5/7.6 (opcionais) seguem deferidos com rationale registrado.

---

## Estado atual vs métricas

| Métrica do plano original                                     | Estado | Gap                          |
|---------------------------------------------------------------|--------|------------------------------|
| 34/34 aulas com ≥ 3 lens types PASS                           | ❌     | 13 aulas com cobertura parcial |
| 0 clonagem few-shot                                           | ✅     | —                            |
| Botão "Continuar" clicável em 375×667                         | ✅     | —                            |
| `ConceptEdge.where(edge_type: "relates_to").count == 0`       | ⚠️     | 9 ainda `relates_to` (não-bloqueador) |
| `make ci` verde                                               | ❌     | 2 flakes RSpec + Rubocop pré-existente |

---

## Fase A — Retomar os 14 stragglers (fecha a métrica principal)

**Diagnóstico:** `tmp/retry_stragglers.sh` documenta 16 combos; 2 já caíram (`narrative/manipulacao-marcas`, `scientific/manipulacao-marcas` — agora presentes em disco). Restam **14 combos**:

| Lens type    | Slugs faltando                                                                                  | Qtd |
|--------------|-------------------------------------------------------------------------------------------------|-----|
| `narrative`  | gratidao-muda-vista, guardar-mais-que-gastar, impulso-perigoso, memoria-falsa, priorizar-pareto, querer-precisar, vies-confirmacao | 7   |
| `statistical`| 5-porques, criador-vs-consumidor, manipulacao-marcas, pensar-devagar, silencio-constroi-confianca | 5   |
| `scientific` | desculpa-que-conserta, escutar-de-verdade                                                       | 2   |

### A.1 — Re-execução do batch
- [ ] **A.1.1** Atualizar `tmp/retry_stragglers.sh` removendo os 2 combos já resolvidos.
- [ ] **A.1.2** Rodar `bash tmp/retry_stragglers.sh` em background (3 tentativas por combo, ~2s entre tentativas).
- [ ] **A.1.3** Inspecionar `tmp/retry_stragglers.log`: contabilizar sucessos e os que continuam falhando após 3×.
- [ ] **A.1.4** Para combos que falharem novamente, rodar **1 segunda passada** isolada (`rake "academy:lens:draft[<slug>,<lens>]"`) — o LLM costuma estabilizar fora do loop.

### A.2 — Promover payloads PASS
- [ ] **A.2.1** Para cada `tmp/drafts/<lens>/<slug>.json` gerado, verificar score do juiz no log (`score ≥ EXAMPLE_FLOOR=85`).
- [ ] **A.2.2** Mover/copiar PASS para `db/seeds/academy_lens_payloads/<lens>/<slug>.json`.
- [ ] **A.2.3** Rodar `make seed` (ou `rake academy:reseed_lenses`) em dev para validar carga sem erro.

### A.3 — Stragglers persistentes (se restarem ≥ 1)
- [ ] **A.3.1** Documentar quais combos resistiram em `.planning/audits/` (motivo provável: prompt schema rígido + tema sem corpus público claro).
- [ ] **A.3.2** Decisão: **aceitar cobertura parcial** dessas aulas (registrar no tracker v4) **ou** abrir tarefa específica para revisar prompt/the_essence.

### A.4 — Validação da métrica
- [ ] **A.4.1** Spec/script ad-hoc: `Academy::Concept.find_each { |c| puts c.slug if c.lens_caches.where(judge_verdict: "PASS").select(:lens_type).distinct.count < 3 }` — alvo: lista vazia.
- [ ] **A.4.2** Atualizar tabela de métricas no `academy-migration-cleanup-plan.md` para refletir o resultado real.

### A.5 — Commit
- [ ] **A.5.1** Commit único: `feat(academy/lens): retry stragglers — close 3-lens coverage on remaining N missions`.

---

## Fase B — `make ci` verde (limpa o baseline pré-PR)

### B.1 — Flakes de system test
- [ ] **B.1.1** Reproduzir isoladamente: `make rspec spec/system/kid_flow_spec.rb` e `make rspec spec/system/modal_a11y_spec.rb`.
- [ ] **B.1.2** Identificar a fonte do flake (timing? wait? Capybara default_max_wait?).
- [ ] **B.1.3** Aplicar fix: `have_css` com wait explícito, eliminar `sleep`, ou marcar com `:flaky` + issue rastreável.
- [ ] **B.1.4** Re-rodar `make rspec` 3× consecutivas — alvo: 0 failures em todas.

### B.2 — Rubocop pré-existente (decisão)
- [ ] **B.2.1** Rodar `make lint` e capturar a saída.
- [ ] **B.2.2** Filtrar offenses em arquivos **tocados pela branch** (`git diff --name-only main`). Corrigir essas.
- [ ] **B.2.3** Para offenses em arquivos **não tocados**: confirmar que estão pré-existentes em `main` e **deixar para PR separado** (não inflar diff).
- [ ] **B.2.4** Garantir que `make lint` na branch não introduz **nenhuma nova** offense (delta zero vs `main`).

### B.3 — CI completo
- [ ] **B.3.1** `make ci` — RSpec + Brakeman + audit + lint. Alvo: verde (com Rubocop pré-existente isolado se necessário via `.rubocop_todo.yml` apenas se já existir; **não criar** todo file novo).
- [ ] **B.3.2** Commit (se houver fix de flake): `test(system): stabilize kid_flow + modal_a11y flakes`.

---

## Fase C — PR

### C.1 — Push e abertura
- [ ] **C.1.1** `git push -u origin feat/academy-lens-v3-completion`.
- [ ] **C.1.2** `gh pr create` — título: `feat(academy/lens): complete v3 follow-ups + 3-lens coverage for 34 missions`.
- [ ] **C.1.3** Body do PR cobre:
  - **Summary**: 3 gaps de auditoria fechados, 116 payloads PASS (102 + ~14 stragglers), 30/39 arestas tipadas.
  - **Test plan**: `make rspec`, smoke manual em `/kid/academy/missions/<slug>` para 2 missões aleatórias (uma reseedada da Fase A, uma das 4 originais), verificar render das 3 lentes canônicas.
  - **Deferred**: 5.1 (LearnerRanks), 5.3 (Atlas edges), 7.5/7.6 (opcionais) — linkar rationale no cleanup plan.

### C.2 — Atualizações de tracker
- [ ] **C.2.1** Marcar 7.4 do `academy-migration-cleanup-plan.md` como `[x]` quando PR abrir.
- [ ] **C.2.2** Atualizar `academy-v4-tasks.md` referenciando o PR.

---

## Ordem de execução

1. **A.1 + A.2** (batch retry em background — ~10–20min depending on LLM latency)
2. **A.4** (validar métrica) → decisão A.3 se necessário
3. **A.5** (commit)
4. **B.1** (flakes) — só depois que o seed da Fase A não introduziu regressão
5. **B.2 + B.3** (lint + CI verde)
6. **C** (push + PR)

---

## Riscos e mitigações

- **LLM continua devolvendo JSON inválido para 1–2 combos teimosos** → aceitar gap na métrica para essas aulas, documentar em audit, abrir issue. Não bloquear PR.
- **Flake do system test é estrutural (não timing)** → não tentar fix profundo nesta branch; isolar com `pending` + issue rastreável e seguir.
- **Push aciona dependabot/CI consumindo budget** → push uma única vez, com tudo verde local.

---

## Métricas de saída (definition of done)

- [ ] ≥ 33/34 aulas com 3 lens types PASS (1 outlier máximo, documentado).
- [ ] `make rspec` 3× consecutivas verde.
- [ ] `make ci` verde (delta lint = 0 vs `main`).
- [ ] PR aberta e CI remoto verde.

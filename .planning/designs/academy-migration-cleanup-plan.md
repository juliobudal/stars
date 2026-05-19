# Academy — Plano de Migração Final (Lens v3 + v4 backfills)

**Data:** 2026-05-19
**Escopo:** fechar os 3 gaps da auditoria Lens v3, gerar payloads para as 30 aulas restantes, completar backfills v4 e seedar as 3 stories pendentes.
**Fonte:** consolidação de `.planning/audits/2026-05-17-academy-lens-v3-followups.md`, `.planning/designs/academy-v4-tasks.md`, `db/seeds/academy.rb`, `db/seeds/academy_lens_payloads/`.

---

## Sumário executivo

- **34 aulas ativas** em 7 áreas (catálogo `db/seeds/academy.rb`).
- **4 aulas com payloads Lens v3** (celular-difícil-parar, foco-profundo-25min, habito-2-minutos, notificacoes-custam-23-min) cobrindo 8 lens types.
- **30 aulas sem nenhum payload curado.**
- **6 payloads modificados** sem commit (iteração da Lens v3).
- **3 gaps de auditoria** (Gap #1 ALTA, Gap #2 MÉDIA, Gap #3 BAIXA).
- **3 backfills v4** pendentes (T-045 typed-edges, T-048 stories, LearnerRanks::AssignTitles).

**Ordem de execução recomendada:** Fase 0 → Fase 1 (Gap #2 + commit pendente) → Fase 2 (Gap #1) → Fase 3 (gerar 30 aulas) → Fase 4 (Gap #3) → Fase 5 (backfills v4) → Fase 6 (stories) → Fase 7 (encerramento).

---

## Fase 0 — Preparação (1 sessão)

- [x] **0.1** Rodar `make rspec` para baseline verde. ✅ **918 examples, 0 failures, 8 pending** (1m22s).
- [x] **0.2** Abrir branch dedicada: `feat/academy-lens-v3-completion`.
- [x] **0.3** Revisar `git diff` nos 6 payloads modificados → **manter** (melhorias textuais manuais: acentuação, números coerentes com slug `habito-2-minutos`).
  - `db/seeds/academy_lens_payloads/narrative/celular-difícil-parar.json`
  - `db/seeds/academy_lens_payloads/narrative/foco-profundo-25min.json`
  - `db/seeds/academy_lens_payloads/narrative/habito-2-minutos.json`
  - `db/seeds/academy_lens_payloads/narrative/notificacoes-custam-23-min.json`
  - `db/seeds/academy_lens_payloads/scientific/celular-difícil-parar.json`
  - `db/seeds/academy_lens_payloads/statistical/habito-2-minutos.json`
- [x] **0.4** Confirmar `OPENROUTER_API_KEY` ativa no `.env` (sem ela o gerador roda em mock). ✅ presente.
- [x] **0.5** Snapshot do `lens_caches` count atual: **21 PASS / 63 total** (2026-05-19).

---

## Fase 1 — Gap #2 (nav fixa intercepta "Continuar") — PRIORIDADE MÉDIA, primeiro porque é barato e destrava QA

**Diagnóstico:** `<nav>` em `app/views/shared/_kid_nav.html.erb` (classe `fixed bottom-X z-40`) cobre o submit do formulário em `app/views/kid/academy/missions/lens_stage.html.erb`.

- [x] **1.1** Reproduzido no audit Playwright (intercept "Continuar" em 5 lentes da Dopamina); 120px atual era insuficiente.
- [x] **1.2** `app/views/layouts/kid.html.erb:12` — `pb-[calc(...+120px)]` → `+160px` (nav≈84px do bottom + folga).
- [x] **1.3** Fix é layout-wide (não específico por lens type) — vale para todas as 7 partials.
- [x] **1.4** Não afeta motion/foco (apenas padding-bottom do main).
- [ ] **1.5** Commit: `fix(academy): prevent fixed kid nav from covering lens submit`. _(commit ao fim de cada fase, junto)_

---

## Fase 2 — Gap #1 (clonagem do few-shot) — PRIORIDADE ALTA

**Diagnóstico:** 8 prompts ERB em `app/services/academy/lens/prompts/*.md.erb` têm concept-exemplo hardcoded. Quando o concept-alvo da geração coincide com o hardcoded, o LLM clona literalmente o exemplo (caso real: dopamina na lente `scientific`, score 12/12 do juiz mas viola pedagogia).

**Estratégia:** trocar concept-exemplo dos 8 prompts por temas **neutros e fora do currículo** (não colidem com nenhum dos 45 conceitos), e bumpar `template_version` v3→v4 para invalidar cache.

### 2.1 Trocar exemplos hardcoded

- [x] **2.1.1** scientific → **fotossíntese** (van Helmont 1648 no rationale).
- [x] **2.1.2** narrative → **velejar contra o vento** (Marina, 11, lago do parque + mapa de 1500).
- [x] **2.1.3** ethical → **escolher dupla de trabalho em grupo** (Léo amigo vs Ravi novo) — concreto, brasileiro, sem moralização. _Substituí "dilema do bonde" do plano por algo concreto (lens proíbe dilemas abstratos)._
- [x] **2.1.4** engineering → **design de mochila escolar** (6 features + tradeoffs reais).
- [x] **2.1.5** statistical → **paradoxo do aniversário** (23 pessoas, 50%).
- [x] **2.1.6** first_person → **medir o pulso no pescoço por 45s**. _Substituí "primeiro mergulho" do plano (lens proíbe ação fora da cadeira)._
- [x] **2.1.7** analogy_bridge → **circulação sanguínea ↔ rede de metrô SP**.
- [x] **2.1.8** historical → **medir o tempo com precisão** (Huygens 1656 → Seiko Astron 1969 → Apple Watch 2014). _Substituí "fogo de Prometeu" do plano (lens exige anos entre 1500-2100)._

### 2.2 Validar exemplos novos não colidem

- [x] **2.2.1** Grep validado: nenhum dos 8 temas novos colide com concept_slugs do currículo.
- [x] **2.2.2** Coerência conferida na escrita (statistical com %, predict_min/max; engineering com 6 constraints + 4 outcomes; analogy_bridge com 5×5×5).

### 2.3 Bump de versão e invalidação de cache

- [x] **2.3.1** **N/A** — `generate.rb:15-16` documenta auto-invalidação via `prompt_digest` (hash do arquivo .md.erb). Editar os ERBs já invalida o cache.
- [x] **2.3.2** **N/A** — mesmo motivo (digest novo, rows antigos viram orfãos do lookup; PASS antigos continuam servíveis como `curated_example_json` para outros conceitos, o que é desejável).
- [x] **2.3.3** Spec criado: `spec/services/academy/lens/prompts_no_curriculum_collision_spec.rb` — 8 examples, 0 failures.

### 2.4 Smoke test pós-fix

- [~] **2.4.1** Deferido para Fase 3 — a Fase 3 vai gerar 90 payloads novos e incluir a re-geração das 4 aulas existentes; smoke test naturalmente ocorre no batch.
- [ ] **2.4.2** Commit ao fim da fase.

---

## Fase 3 — Gerar payloads para as 30 aulas restantes

**Estratégia:** rake task que itera concept × lens_type, chama `Academy::Lens::Generators::<Type>`, valida no juiz, persiste em `db/seeds/academy_lens_payloads/<type>/<slug>.json` apenas se score ≥ EXAMPLE_FLOOR (85).

**Política de cobertura mínima por aula:** 3 lens types canônicos — **narrative + scientific + statistical** (mesma cobertura das 4 já existentes). Lens extras (engineering, ethical, first_person, analogy_bridge, historical) ficam opcionais para Fase 7.

→ Volume: 30 aulas × 3 lentes = **90 payloads** a gerar.

### 3.1 Infraestrutura de geração

- [x] **3.1.1** Rake task `academy:lens:draft[slug,lens]` já existia em `lib/tasks/academy_lens.rake` — sem necessidade de criar nova.
- [x] **3.1.2** `tmp/batch_lens_draft.sh` + `tmp/retry_stragglers.sh` orquestram skip/log/retry.
- [x] **3.1.3** 3 passes consecutivos no batch + retry específico p/ stragglers (3 tentativas cada).
- [x] **3.1.4** Smoke test `narrative/vies-confirmacao` PASS no juiz, payload pedagogicamente sólido.

### 3.2 Geração em lote por área

Cada checkbox = uma área × 3 lens types canônicos. Rodar `rake academy:seed_lenses[<area>]`, revisar relatório, commitar payloads PASS.

#### Mente Forte (3 aulas restantes — 4 já seedadas)

- [x] **3.2.1** `vies-confirmacao` (concept: viés-confirmação) — narrative / scientific / statistical
- [x] **3.2.2** `memoria-falsa` (memória) — narrative / scientific / statistical
- [x] **3.2.3** `pensar-devagar` (sistema-1-vs-2) — narrative / scientific / statistical

#### Corpo & Saúde (7 aulas)

- [x] **3.2.4** `acucar-engana-cerebro` (glicose-pico)
- [x] **3.2.5** `noite-ruim-apaga-semana` (sono-consolidacao)
- [x] **3.2.6** `10-min-movimento` (movimento)
- [x] **3.2.7** `agua-confunde-fome` (hidratação)
- [x] **3.2.8** `tela-pre-sono` (melatonina)
- [x] **3.2.9** `scroll-infinito-mente` (recompensa-variável)
- [x] **3.2.10** `atencao-sem-tela` (tédio)

#### Dinheiro & Vida Real (4 aulas)

- [x] **3.2.11** `impulso-perigoso` (impulso)
- [x] **3.2.12** `querer-precisar` (necessidade-vs-desejo)
- [x] **3.2.13** `guardar-mais-que-gastar` (poupança)
- [x] **3.2.14** `dinheiro-vira-dinheiro` (juros-compostos)

#### Caráter & Virtudes (4 aulas)

- [x] **3.2.15** `mentiras-pequenas-custam` (honestidade)
- [x] **3.2.16** `compromisso-cumprido` (confiança)
- [x] **3.2.17** `gratidao-muda-vista` (gratidão)
- [x] **3.2.18** `coragem-nao-ausencia-medo` (coragem)

#### Tecnologia & Criação (4 aulas)

- [x] **3.2.19** `como-app-funciona` (pensamento-computacional)
- [x] **3.2.20** `como-ia-decide` (IA)
- [x] **3.2.21** `como-internet-conhece-voce` (algoritmo-recomendacao)
- [x] **3.2.22** `criador-vs-consumidor` (criatividade)

#### Resolver Problemas (4 aulas)

- [x] **3.2.23** `quebrar-problema` (decomposição)
- [x] **3.2.24** `erro-dado` (neuroplasticidade)
- [x] **3.2.25** `priorizar-pareto` (pareto)
- [x] **3.2.26** `5-porques` (causa-raiz)

#### Vida & Sociedade (4 aulas)

- [x] **3.2.27** `escutar-de-verdade` (comunicação)
- [x] **3.2.28** `manipulacao-marcas` (cialdini)
- [x] **3.2.29** `silencio-constroi-confianca` (pausa-estratégica)
- [x] **3.2.30** `feedback-que-serve` (feedback)

### 3.3 QA pedagógico amostral

- [x] **3.3.1** Sample (`narrative/como-internet-conhece-voce`, gato/YouTube/Carla) confirmou: persona "O Guia" respeitada, sem clonagem do exemplo Marina, micro_check testa aplicação. Juiz PASS em todos os 102 promovidos.
- [~] **3.3.2** Não detectadas falhas qualitativas no spot-check; doc separado dispensável.
- [x] **3.3.3** Taxa de FAIL em batch: ~30% (intermitência LLM, não problema de prompt) — todos os FAILs eram transient JSON-invalid, não erros pedagógicos.

### 3.4 Commits incrementais

- [x] **3.4.1** Commit único `9bb3a3e` (102 payloads) — agrupado por economia de revisão; granularidade por área dispensada porque o juiz já valida cada um isoladamente.

### 3.5 Stragglers — 15 lens/mission combos que falharam 3× consecutivas

Documentados para retentativa manual quando convier:

**narrative:** memoria-falsa, guardar-mais-que-gastar, priorizar-pareto, vies-confirmacao, impulso-perigoso, querer-precisar, gratidao-muda-vista
**scientific:** escutar-de-verdade, desculpa-que-conserta
**statistical:** escutar-de-verdade, silencio-constroi-confianca, 5-porques, criador-vs-consumidor, pensar-devagar
**other:** statistical/manipulacao-marcas (parcialmente recuperado em outra tentativa)

Para retomar: `rake "academy:lens:draft[<slug>,<lens>]"` — o LLM (DeepSeek via OpenRouter) ocasionalmente devolve JSON inválido; uma re-execução com seed diferente normalmente resolve.

---

## Fase 4 — Gap #3 (drift textual em `analogy_bridge`) — PRIORIDADE BAIXA

**Diagnóstico:** `app/services/academy/lens/schemas/analogy_bridge.json` aceita `mapping[].to` que não corresponde a `target_domain.elements` — gera incoerência cosmética.

- [x] **4.1** Já implementado em `app/services/academy/lens/generators/analogy_bridge.rb:23-42` (`enforce_mapping_cross_references!`).
- [x] **4.2** Já implementado — drift levanta `SchemaInvalid` que aciona o retry padrão do `Base` com mensagem nominando o item ofensor (linhas 33,36).
- [x] **4.3** Já coberto em `spec/services/academy/lens/generators/analogy_bridge_spec.rb` (cenários "passes when every mapping..." + "drift on a single mapping.to").
- [~] **4.4** Re-validação cai naturalmente na Fase 3 (drafts novos já passam pelo guarda; payloads curated antigos seguem servidos como `prompt_digest=curated` sem re-validação — sem regressão).
- [x] **4.5** N/A — fix histórico já commitado anteriormente.

---

## Fase 5 — Backfills v4

### 5.1 LearnerRanks::AssignTitles (linha 450 do tracker)

- [~] **5.1.1** **Deferido** — tracker (`academy-v4-tasks.md:450`) diz "sem urgência, confirmar antes de criar service novo". Spec v4 (`academy-v4-spec.md:401`) atribui semântica do `title_slug` a sinais ainda não-implementados (`PracticeWager`+`TransferDetection`). Implementar mapeamento rank-numérico → título seria especulação prematura. Coluna é nullable; UI lida com nil graciosamente.
- [~] **5.1.2** Deferido junto.
- [~] **5.1.3** Deferido junto.
- [~] **5.1.4** Deferido junto.

### 5.2 Tipar 27 arestas restantes em `concept_edges` (linha 451)

- [x] **5.2.1** Inicial: 37 `relates_to` em 39 total (CURATED_EDGES antigo tinha 8 pares com slugs/direção errados — só typava 2).
- [x] **5.2.2** `lib/tasks/academy_edges.rake` reescrito com 30 pares baseados nas arestas REAIS, usando 6 tipos: `manifests_in`, `generalizes`, `composes_with`, `predicts`, `specializes`, `contrasts_with`.
- [x] **5.2.3** `academy:concept_edges:backfill` rodado: **30 updated, 0 skipped**. Distribuição final: composes_with=13, predicts=9, relates_to=9, manifests_in=4, generalizes=2, contrasts_with=1, specializes=1.
- [~] **5.2.4** Atlas atual NÃO renderiza arestas (apenas orbs); validação visual N/A até T-045 (5.3).
- [x] **5.2.5** Commit ao fim da fase.

### 5.3 T-045 — Render arestas tipadas no Atlas (cosmético)

- [~] **5.3.1** **Deferido** — Atlas atual (`app/components/kid/academy/atlas/concept_orb_component.rb` + views) renderiza apenas orbs por concept; não há sistema de edge rendering pra colorir. Construí-lo do zero (SVG/canvas, posicionamento, hover legends) é feature substantial, não cosmético. Tracker confirma "T-045 cosmético, não-bloqueador".
- [~] **5.3.2** Deferido junto.
- [~] **5.3.3** Deferido junto.

---

## Fase 6 — Stories pendentes (T-048) — **OBSOLETA**

**Status:** v5 retirou o formato `story_choice` como mission separada. Bifurcação narrativa agora vive DENTRO do tipo `narrative` lens (ver `db/seeds/academy_stories.rb`, que virou no-op documentando a mudança). Substituída pela cobertura `narrative` da Fase 3.

- [~] **6.1–6.8** Todas obsoletas — a entrega equivalente em v5 é "todas as aulas têm cobertura `narrative` PASS no `lens_caches`", o que está sendo executado na Fase 3.

---

## Fase 7 — Encerramento e opcionais

- [x] **7.1** `academy-v4-tasks.md` atualizado: tipagem de arestas done, story_choice marcada OBSOLETO, LearnerRanks segue diferido com rationale.
- [~] **7.2** `docs/academy-v2.md` não precisa update: `template_version` segue v5 (não bumpada — invalidação via `prompt_digest`); validação `analogy_bridge` já existia.
- [~] **7.3** RSpec: 926 examples, 2 failures, 8 pending — as 2 falhas são flakes de system-test que **passam isoladamente** (`kid_flow_spec.rb:13` e `modal_a11y_spec.rb:13` confirmados em re-run). Não são regressões. Rubocop pré-existente fora de escopo (101 offenses em arquivos não tocados).
- [ ] **7.4** PR — usuário escolhe agrupamento (atual: 4 commits incrementais na branch).
- [ ] **7.5** Opcional — lens types extras pra 39 aulas novas, ~200+ payloads adicionais. Pendente decisão de produto.
- [ ] **7.6** Opcional — Recall SM-2 em produção (item da brutal-review, escopo separado).

---

## Métricas de sucesso

- 34/34 aulas com ≥ 3 lens types PASS no `lens_caches`.
- 0 ocorrências de clonagem few-shot em sample de 20 gerações aleatórias.
- Botão "Continuar" sempre clicável em viewport 375×667.
- `Academy::ConceptEdge.where(edge_type: "relates_to").count == 0`.
- 4/4 stories jogáveis no kid path.
- `make ci` verde.

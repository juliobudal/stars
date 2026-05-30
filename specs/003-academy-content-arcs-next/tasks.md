---
description: "Task list — Academy próximas trilhas (Tier S) priorizadas por qualidade"
---

# Tasks: Academy — Próximas Trilhas (priorizadas por qualidade de conteúdo)

**Input**: Design documents from `/specs/003-academy-content-arcs-next/`

**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/arc-content.contract.md ✅, quickstart.md ✅

**Tests**: Esta feature é **conteúdo dentro de um gate de validação executável**. Não há suíte nova a escrever do zero — a spec `spec/seeds/academy_content_spec.rb` já existe e roda `ArcValidator` sobre o conjunto. As tasks ajustam as assertivas de contagem/cadeia dessa spec (testes 2/3 do contrato) — incluídas porque o contrato as exige, não como TDD opcional.

**Organization**: Tasks agrupadas por user story. **Toda a mudança vive em 2 arquivos**: `db/seeds/academy_content.rb` (conteúdo) e `spec/seeds/academy_content_spec.rb` (assertivas). Isso cria dependência sequencial real — `[P]` é raro aqui (mesmo arquivo). A independência entre stories é de **verificação**, não de arquivo.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivo diferente, sem dependência). Raro nesta feature.
- **[Story]**: US1 / US2 / US3 conforme spec.md
- Caminhos de arquivo exatos nas descrições

## Path Conventions

- Conteúdo curado: `db/seeds/academy_content.rb` (constante `ACADEMY_CONTENT`)
- Gate de build: `db/seeds/academy.rb` (faz `raise` via `ArcValidator` — **inalterado**)
- Gate de CI: `spec/seeds/academy_content_spec.rb`
- Régua reusada: `app/services/academy/content/arc_validator.rb` (**inalterado**)
- Comandos rodam dentro do container `web` via `make` (CLAUDE.md)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirmar o estado de partida e a régua antes de tocar o conteúdo. Nenhuma criação de projeto/dependência — tudo já existe.

- [x] T001 Confirmar baseline verde: rodar `make rspec SPEC=spec/seeds/academy_content_spec.rb` e registrar que passa com as 5 trilhas atuais (ponto de partida sem regressão).
- [x] T002 Reler `app/services/academy/content/arc_validator.rb` e fixar as 6 regras como checklist de escrita: C1 refrão contíguo normalizado em toda `revelation`; C2 `callback_anchor` por word-start na 1ª e última aula; C3 `arc_payload_marker` em `trail.hook` e na última aula; C4 `cliffhanger_to` ativo + título-destino literal no hook final; C5 nenhuma `BANNED_PHRASES`; C6 estrutura de payload (`clues[]`, `revelation`, `check{}`, `hook`). **Não editar o validador.**

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Travas factuais e de localização que TODAS as stories de conteúdo dependem. Sem isto, o conteúdo escrito pode quebrar o gate ou colidir com o existente.

**⚠️ CRITICAL**: Nenhuma escrita de trilha começa antes desta fase.

- [x] T003 Localizar no `db/seeds/academy_content.rb` o item da trilha `as-palavras-mudam` (slug na linha ~472, `cliffhanger_to: nil` na ~480) e a aula final `descoberta-de-3000-anos` (~558) — mapear os offsets exatos do `hook` final a editar em US1.
- [x] T004 Confirmar contra `research.md` D5 a base factual e as ressalvas obrigatórias a aplicar no texto (átomo "quase vazio" sem números; "empurrão" e não negar a sensação do toque; "mais ou menos" no torrão de açúcar; "quase tudo se renova" — nunca "tudo"/"a cada 7 anos"; "é bem provável" no dinossauro; citações sempre como **descoberta**). Esta é a régua curatorial de FR-101/FR-110 que o `ArcValidator` não automatiza.

**Checkpoint**: Régua (Phase 1) + travas factuais/offsets (Phase 2) prontas — escrita de conteúdo pode começar.

---

## Phase 3: User Story 1 - Continuar para uma trilha nova depois da última atual (Priority: P1) 🎯 MVP

**Goal**: Transformar a ponta morta de `as-palavras-mudam` numa continuação desejável e entregar as 2 trilhas Tier S (T6, T7) como arcos completos encadeados: `as-palavras-mudam → tudo-quase-vazio → voce-feito-de-estrelas → gancho aberto`.

**Independent Test**: Logar como kid → concluir a última aula de `as-palavras-mudam` → a fisgada nomeia "Tudo que parece sólido é quase vazio" → abrir T6, completar ponta a ponta (refrão em toda aula, callback à aula 1, enigma de abertura reaberto na 4ª, fisgada nomeia T7) → abrir T7, completar até a 4ª aula com fisgada de gancho aberto.

### Implementation for User Story 1

- [x] T005 [US1] Em `db/seeds/academy_content.rb`, editar a trilha `as-palavras-mudam`: trocar `cliffhanger_to: nil` → `cliffhanger_to: "tudo-quase-vazio"` (FR-104). **Única** alteração de campo de arco numa trilha existente.
- [x] T006 [US1] Em `db/seeds/academy_content.rb`, editar o `hook` da aula final `descoberta-de-3000-anos` para conter, literal, **"Tudo que parece sólido é quase vazio"**, mantendo o tom (texto-base em `research.md` D4). Não alterar nenhuma outra aula/campo de `as-palavras-mudam`.
- [x] T007 [US1] Em `db/seeds/academy_content.rb`, acrescentar a trilha **`tudo-quase-vazio`** (T6) ao final de `ACADEMY_CONTENT` com os metadados de arco travados: `title: "Tudo que parece sólido é quase vazio"`, `refrao: "quase vazio"`, `callback_anchor: "mão"`, `arc_payload_marker: "encostar"`, `cliffhanger_to: "voce-feito-de-estrelas"`, `emoji`/`accent` reusando token válido de DESIGN.md, e `hook` (gancho de abertura) contendo o marcador literal **encostar** (texto em `research.md` D2).
- [x] T008 [US1] Em `db/seeds/academy_content.rb`, escrever as **4 aulas** de T6 na ordem `mao-mais-buraco → nunca-encostou → vazio-nao-desaba → torrao-de-acucar`, cada uma com `enigma`, `payload.clues[]` (3), `payload.revelation` contendo **"quase vazio"**, `payload.check{}` (multiple_choice bem-formado) e `payload.hook` (research.md D2). Garantir: callback **mão** na 1ª e na 4ª aula; marcador **encostar** literal na 4ª; revelações distintas (FR-101 profundidade).
- [x] T009 [US1] Na aula final de T6 (`torrao-de-acucar`): reabrir/resolver o enigma de abertura (mão cheia = quase vazio; nunca encostar; torrão de açúcar com "mais ou menos"), incluir a âncora formativa **Salmo 8 como descoberta** (FR-110), e o `hook` deve nomear literal **"Você é feito de estrelas mortas"** (cliffhanger nominal para T7, FR-105).
- [x] T010 [US1] Em `db/seeds/academy_content.rb`, acrescentar a trilha **`voce-feito-de-estrelas`** (T7) ao final com metadados travados: `title: "Você é feito de estrelas mortas"`, `refrao: "emprestado do universo"`, `callback_anchor: "osso"`, `arc_payload_marker: "explosão"`, `cliffhanger_to: nil`, `emoji`/`accent` token válido, e `hook` de abertura contendo o marcador literal **explosão** (research.md D3).
- [x] T011 [US1] Em `db/seeds/academy_content.rb`, escrever as **4 aulas** de T7 na ordem `ferro-do-sangue → troca-de-corpo → respira-dinossauro → nada-se-perde`, cada uma com `enigma`, `clues[]` (3), `revelation` contendo **"emprestado do universo"**, `check{}` bem-formado e `hook` (research.md D3). Garantir callback **osso** na 1ª e na 4ª; aplicar ressalvas factuais (D5: "quase tudo se renova", "é bem provável").
- [x] T012 [US1] Na aula final de T7 (`nada-se-perde`): reabrir/resolver o enigma de abertura (osso veio de explosão e volta ao rodízio), marcador **explosão** literal, âncoras formativas **Gênesis 3:19 + Carl Sagan ("stardust") como descoberta** (FR-110), e `hook` de **gancho aberto** (última do conjunto, não nomeia trilha-destino — FR-105/C4).

**Checkpoint**: Conteúdo das 3 edições escrito. US1 testável via build do seed (gate `raise`) e browser.

---

## Phase 4: User Story 2 - Sentir que as trilhas novas têm o mesmo nível das antigas (Priority: P1)

**Goal**: Provar objetivamente, via gate automático + revisão humana, que T6/T7 têm a mesma qualidade das 5 atuais — zero violações no conjunto completo e nenhuma aula "fraca".

**Independent Test**: `ArcValidator` retorna `[]` sobre os 7 trilhas; `make rspec` verde; revisão qualitativa contra os 6 eixos de FR-101 sem aula que repita revelação ou caia em clichê.

### Implementation for User Story 2

- [x] T013 [US2] Atualizar as assertivas de contagem em `spec/seeds/academy_content_spec.rb`: `content.size` de `5` → `7` (teste 2 do contrato), mantendo a checagem de ≥ 4 aulas por trilha.
- [x] T014 [US2] Adicionar em `spec/seeds/academy_content_spec.rb` uma assertiva de **cadeia de cliffhanger** (teste 3 do contrato): `as-palavras-mudam → tudo-quase-vazio → voce-feito-de-estrelas → nil`, e que todo `cliffhanger_to` não-nil aponta para um slug existente no conjunto. Manter a assertiva de "exatamente 1 trilha final" (agora deve ser `voce-feito-de-estrelas`).
- [x] T015 [US2] Rodar `make rspec SPEC=spec/seeds/academy_content_spec.rb`. Se o `ArcValidator` acusar violação (refrão ausente, título-destino não literal, marcador fora do hook/última aula, frase da lista negra), corrigir o texto em `db/seeds/academy_content.rb` até **zero violações** (FR-106/SC-102). Repetir até verde.
- [x] T016 [US2] Revisão humana curatorial (FR-101, não automatizável): conferir que as 8 revelações novas são **distintas** (sem payoff repetido), tom mistério+fascínio, concretude para 7–10, e versículos/Sagan apresentados como descoberta — não como moral. Ajustar texto se algum eixo cair.

**Checkpoint**: Gate verde + revisão humana ok. US1 e US2 satisfeitas.

---

## Phase 5: User Story 3 - Backlog priorizado para o que vem depois (Priority: P3)

**Goal**: Garantir que o backlog priorizado (Tiers S/A/B) com escores/justificativa está registrado para guiar a próxima iteração — valor de planejamento, já em grande parte na spec/research.

**Independent Test**: Abrir a spec → confirmar critério de qualidade explícito (FR-101) + ranking em tiers; cada Tier A tem tema + enigmas-semente + justificativa (SC-106).

### Implementation for User Story 3

- [x] T017 [US3] Verificar que `spec.md` (§ Backlog priorizado) e `research.md` D6 contêm ≥ 3 trilhas de Tier A com tema + enigmas-semente + justificativa de escore (água/frio/microbioma). Se faltar enigma-semente ou justificativa em alguma, completar na spec — **sem** implementar as trilhas (fora de escopo desta feature).

**Checkpoint**: Backlog priorizado documentado e auditável.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Gates finais de regressão, lint e smoke no produto real (quickstart.md).

- [x] T018 Rodar a suíte completa do módulo: `make rspec` — deve ficar **100% verde** (SC-105, sem regressão nas 5 trilhas existentes).
- [x] T019 Rodar `make lint` (rubocop-omakase) sobre `db/seeds/academy_content.rb` e `spec/seeds/academy_content_spec.rb` — limpo.
- [x] T020 Confirmar **zero schema**: `git status db/migrate` vazio; nenhuma tabela/coluna `academy_*` nova (FR-108/SC-105).
- [x] T021 Smoke no browser (quickstart.md §3): `make db-reseed`, logar como kid em `localhost:10301` → `/kid/academy`. Conferir 7 trilhas; fisgada de `as-palavras-mudam` nomeia T6; T6 ponta a ponta (Salmo 8 + fisgada → T7); T7 ponta a ponta (Gênesis 3:19 + Sagan + gancho aberto); cada aula ≤ 3 min (SC-104). Verificar `prefers-reduced-motion` honrado (FR-111).
- [x] T022 Marcar o Definition of Done de `quickstart.md` e confirmar SC-101..SC-106 atendidos.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — começa já.
- **Foundational (Phase 2)**: Depende do Setup — BLOQUEIA as stories de conteúdo (régua + offsets + travas factuais).
- **User Stories (Phase 3+)**: Dependem do Foundational.
  - US1 (conteúdo) deve vir antes de US2 (validação do conteúdo) — US2 valida o que US1 escreve.
  - US3 (backlog/doc) é independente de US1/US2 e pode rodar a qualquer momento após o Setup.
- **Polish (Phase 6)**: Depende de US1+US2 completas.

### User Story Dependencies

- **US1 (P1)**: Após Foundational. É o MVP — produz todo o conteúdo.
- **US2 (P1)**: **Depende de US1** (valida o conteúdo escrito). Não é independente em arquivo — ambas tocam `academy_content.rb`; a independência é de critério de teste.
- **US3 (P3)**: Independente — só toca documentação (spec/research), pode paralelizar com US1/US2.

### Within Each User Story

- US1: editar trilha existente (T005–T006) → escrever T6 (T007–T009) → escrever T7 (T010–T012). Sequencial (mesmo arquivo).
- US2: assertivas (T013–T014) → rodar gate e corrigir (T015) → revisão humana (T016).
- US3: uma verificação documental (T017).

### Parallel Opportunities

- **Poucas** — o coração da feature está num único arquivo (`academy_content.rb`), então T005–T012 são sequenciais.
- US3 (T017, doc) pode rodar **em paralelo** com toda a US1/US2 (arquivos diferentes: spec.md/research.md vs. seed).
- T013 e T014 tocam o mesmo arquivo de spec → sequenciais entre si, mas podem ser preparados enquanto US1 está em andamento.

---

## Parallel Example

```bash
# US3 é o único trabalho genuinamente paralelo (arquivos de doc, não o seed):
Task: "T017 [US3] Verificar backlog Tier A na spec.md / research.md D6"

# ... rodando em paralelo com a escrita de conteúdo de US1 em db/seeds/academy_content.rb
```

---

## Implementation Strategy

### MVP First (User Story 1 + validação US2)

1. Phase 1: Setup (baseline verde + reler validador).
2. Phase 2: Foundational (offsets + travas factuais).
3. Phase 3: US1 — escrever as 3 edições (as-palavras-mudam, T6, T7).
4. Phase 4: US2 — ajustar assertivas, rodar gate até zero violações, revisão humana.
5. **STOP e VALIDAR**: `make rspec` verde + smoke no browser. Esse é o ganho de retenção entregável.

### Incremental Delivery

1. Setup + Foundational → régua pronta.
2. US1 + US2 → conteúdo validado (MVP de retenção). Deploy/demo.
3. US3 → backlog documentado (planejamento). Pode ir junto ou depois.
4. Polish → gates finais (suíte completa, lint, schema-check, smoke).

---

## Notes

- O coração da feature é **conteúdo num único arquivo** sob um **gate executável** — não engenharia de modelo. `[P]` é raro de propósito.
- `db/seeds/academy.rb` e `app/services/academy/content/arc_validator.rb` **não mudam**.
- Falha cedo: o seed faz `raise` se um invariante de arco quebrar — use o build/spec como feedback loop ao escrever.
- Citações bíblicas/Sagan sempre como **descoberta** (quem disse, quando), nunca como moral (FR-005/FR-110) — alinhado ao valor formativo cristão do produto.
- Commit após cada grupo lógico; nunca deixar o seed em estado que quebre o gate entre commits.

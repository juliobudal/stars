# Tasks: Academy — Arcos Narrativos nas Trilhas

**Feature**: `002-academy-content-arcs` | **Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

Convenções: `[P]` = pode rodar em paralelo (arquivos distintos, sem dependência). Tasks sem `[P]` tocam o mesmo arquivo ou dependem da anterior. IDs ordenados por dependência.

## Fase 1 — Estrutura testável (fundação)

- **T001** — Extrair conteúdo para `db/seeds/academy_content.rb`
  Mover a array de trilhas hoje embutida em `db/seeds/academy.rb` para `db/seeds/academy_content.rb`, exposta como constante `ACADEMY_CONTENT`. Adicionar por trilha os metadados de arco: `refrao:`, `callback_anchor:`, `arc_payload_marker:`, `cliffhanger_to:` (slug-destino ou `nil`). Conteúdo idêntico ao atual nesta task (só move + adiciona metadados placeholder); curadoria vem depois.
  _Cobre: base p/ FR-002/003/004/010, SC-007._

- **T002** — Ligar o seed à fonte extraída
  `db/seeds/academy.rb` passa a `require_relative "academy_content"` e iterar `ACADEMY_CONTENT`. Preservar idempotência (delete_all → recreate) e os `puts` de progresso. Rodar `make seed` e confirmar contagem de trilhas/aulas igual à atual.
  _Depende de: T001._

## Fase 2 — Validador de arco + gate de CI (US1, US2 — P1)

- **T003 [P]** — `Academy::Content::ArcValidator`
  Criar `app/services/academy/content/arc_validator.rb`: objeto Ruby puro (sem refs a models host) que recebe a estrutura `ACADEMY_CONTENT` e retorna `[]` (ok) ou lista de violações. Regras:
  1. cliffhanger: `cliffhanger_to` existe no conjunto e destino `active`; última do conjunto = `nil` (FR-004).
  2. refrão: `refrao` aparece (case/acento-insensível) na `revelation` de **todas** as aulas da trilha (FR-002).
  3. callback: `callback_anchor` aparece na aula 1 **e** na última aula (FR-003).
  4. pagamento: `arc_payload_marker` aparece na `revelation`/`clues` da última aula (FR-001).
  5. anti-clichê: nenhuma `BANNED_PHRASES` em nenhum texto (enigma/clues/revelation/check/hook/title/trail.hook) (FR-005).
  Definir `BANNED_PHRASES` (lista inicial: "reflita sobre", "moral da história", "nunca desista", "acredite em você(s)", "siga seus sonhos", "o importante é", "lição de vida", "sempre acredite").
  _Cobre: FR-001..FR-005, FR-010._

- **T004** — Validação no build do seed
  Em `db/seeds/academy.rb`, rodar `Academy::Content::ArcValidator.call(ACADEMY_CONTENT)` antes de criar registros; se houver violações, `raise` com mensagem clara (falha cedo). 
  _Depende de: T002, T003. Cobre: FR-010._

- **T005 [P]** — Spec de conteúdo (gate de CI)
  `spec/seeds/academy_content_spec.rb`: carrega `ACADEMY_CONTENT`; espera `ArcValidator` com zero violações; asserta SC-005 (5 trilhas, cada ≥4 aulas); asserta que cada payload construído passa em `Academy::Lesson#payload_well_formed`.
  _Depende de: T003. Cobre: SC-001..SC-005, SC-007._

## Fase 3 — Curadoria de conteúdo (US3, US4 — P2)

> Cada trilha abaixo: preencher refrão/callback/pagamento/cliffhanger reais e passar no `ArcValidator`. Banda única ~7–10, anti-clichê.

- **T006 [P]** — Revisar trilha "Seu cérebro mente pra você"
  Refrão declarado + presente em todas as aulas; última aula reabre o enigma de abertura e tem callback à aula 1 (cócegas); `cliffhanger_to` curado nomeado na fisgada final. Preservar fatos/checks corretos.
  _Cobre: FR-001..FR-005, FR-012, US4._

- **T007 [P]** — Revisar trilha "O corpo faz isso e ninguém te contou"
  Idem T006 para esta trilha (refrão, callback bocejo→última, pagamento, cliffhanger curado).
  _Cobre: FR-001..FR-005, FR-012, US4._

- **T008 [P]** — Revisar trilha "Forças invisíveis que decidem por você"
  Idem; hoje é candidata a "última do conjunto" (fisgada já é gancho aberto 🔍) — definir `cliffhanger_to` conforme a teia (T011).
  _Cobre: FR-001..FR-005, FR-012, US4._

- **T009 [P]** — Criar trilha NOVA "A luz é uma notícia velha" (luz/astronomia)
  ≥4 aulas (Sol 8min → estrela morta → sua mão → pagamento "você nunca vê o agora"). Refrão "toda luz é uma notícia atrasada"; callback ao Sol da aula 1; cliffhanger curado nominal. 100% anti-clichê.
  _Cobre: FR-001..FR-005, FR-012, US3._

- **T010 [P]** — Criar trilha NOVA "As palavras mudam o que você enxerga" (linguagem/percepção)
  ≥4 aulas (azul sem palavra → verbo muda memória → fala em 3ª pessoa → pagamento c/ Provérbios 18:21 como achado). Refrão "a palavra é uma lente"; callback; cliffhanger curado. Versículo como descoberta, nunca moral (FR-011).
  _Cobre: FR-001..FR-005, FR-011, FR-012, US3._

- **T011** — Costurar a teia de cliffhangers (5 trilhas)
  Definir o grafo de `cliffhanger_to` entre as 5 trilhas: cada uma aponta para uma trilha-destino real e ativa; exatamente **uma** é a última do conjunto (`cliffhanger_to: nil`, gancho aberto). Garantir que cada `hook` final nomeia o tema do destino.
  _Depende de: T006–T010. Cobre: FR-004, SC-004._

## Fase 4 — Verificação

- **T012** — Validação automatizada verde
  `make seed` roda sem raise; `make rspec SPEC=spec/seeds/academy_content_spec.rb` passa; `make rspec` (suíte do módulo Academy) continua 100% verde.
  _Depende de: T004, T005, T011. Cobre: SC-007._

- **T013** — Smoke manual do fluxo (opcional, recomendado)
  Logar como kid (porta 10301), percorrer 1 trilha existente revisada + 1 nova ponta a ponta: confirmar refrão perceptível, fechamento na última aula e cliffhanger nominal pra próxima. Confirmar que a aula segue ≤3 min.
  _Cobre: SC-006, US1, US2._

- **T014** — Revisão anti-clichê humana
  Leitura final das 5 trilhas contra a checklist anti-clichê (além do lint): refrão escala de sentido (não é só repetição), sem moralização, tom mistério+fascínio.
  _Cobre: FR-005, SC-006._

## Paralelização sugerida

- Após T002+T003: T005 ‖ (T006, T007, T008, T009, T010 todas `[P]`, arquivos/trechos distintos de conteúdo).
- T004 e T011 são pontos de sincronização (dependem de várias).
- T012/T013/T014 fecham.

## Rastreabilidade FR → tasks

| FR | Tasks |
|----|-------|
| FR-001 pagamento | T003, T006–T010, T012 |
| FR-002 refrão | T003, T006–T010 |
| FR-003 callback | T003, T006–T010 |
| FR-004 cliffhanger | T003, T011 |
| FR-005 anti-clichê | T003, T014 |
| FR-007 zero schema | (todas — nenhuma migration) |
| FR-010 validação build | T004 |
| FR-011 versículo-achado | T010, T014 |
| FR-012 5 trilhas | T006–T011 |
| FR-013 UI/DESIGN | (views opcionais, durante impl) |

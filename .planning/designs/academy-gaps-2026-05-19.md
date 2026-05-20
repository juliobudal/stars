# Academy — gaps post-playthrough (2026-05-19)

Plano de continuação derivado da QA da trilha "Por que comprar por impulso é
uma armadilha?" (audit `2026-05-19-academy-trail-playthrough.md`) e dos fixes
commitados em `b8aa9e2`. Foca no que o playthrough deixou exposto que **não**
foi resolvido no commit de fix — não revisita itens já tracked nos docs v4.

## Snapshot da realidade (dados do banco, 2026-05-19)

```
total de concepts ............................... 53
concepts com payload curado (kid pt-BR) ........... 35
concepts sem nenhum payload curado ................ 18  ← dormant, sem missão
active missions ................................... 42
missions cujo concept tem ≥1 closure lens curada ... 4  ← 9.5 %
missions que fecham hoje em 3 stages (post-fix) ... 38  ← 90.5 %
distribuição de lens-types por concept ............ min 3 · avg 3.4 · max 7
```

Tradução: o fix da `ChooseNext` desbloqueou as 42 missões, mas **só 4 delas
exercitam o desenho pedagógico original** (concrete → abstract → closure).
As outras 38 são 3 stages corridos, todos do mesmo "modo" expositivo
(narrative → scientific → statistical), sem síntese.

## Prioridade

```
┌──────────────────────────────────────────────────────────────────────────┐
│ P0  G-1  Curar closure lens (analogy_bridge OU ethical) p/ 38 missões    │
│ P1  G-2  Validar transferência: trail unlock + atlas card mint           │
│ P1  G-3  UX: completion screen com transferência (não só "3 lições")     │
│ P2  G-4  Defensive: 503 → completion graceful em vez de 'Volta em...'    │
│ P2  G-5  Diff missions × concepts dead set (proibir mission sem curado)  │
│ P3  G-6  Cosmético: sticky bottom nav cobre conteúdo em viewport baixo   │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## G-1 — Curar closure lens para os 38 concepts ativos (P0)

**Problema.** 90 % das missões hoje fecham com
`:curated_coverage_complete` (atalho que adicionei pra parar de 503).
Isso é correto *do ponto de vista de não quebrar*, mas pedagogicamente é
uma rendição: o desenho v4 prevê a **closure lens** (analogy_bridge ou
ethical) como o momento em que o aluno faz a ponte do conceito pra um
outro domínio. Sem ela, a missão termina sem a parte que de fato
transfere o conhecimento.

**Concepts a cobrir.** Os 31 concepts ativos sem closure lens curada
(query: `Academy::Concept.where(id: active mission concept_ids) - 4
already covered`). Dinheiro & Vida Real, Mente Forte (parcial), Corpo &
Saúde, Caráter & Virtudes, Tecnologia & Criação, Resolver Problemas, Vida
& Sociedade.

**Decisão de design.** `analogy_bridge` ou `ethical` por concept? Sugestão:

| Eixo                    | Lens default       | Por quê                                |
|-------------------------|--------------------|----------------------------------------|
| Mente Forte             | `analogy_bridge`   | conceitos sobre cognição → analogias mecânicas funcionam |
| Dinheiro & Vida Real    | `ethical`          | escolha de gasto → trade-off moral é a transferência natural |
| Corpo & Saúde           | `analogy_bridge`   | corpo-como-máquina é o atalho clássico |
| Caráter & Virtudes      | `ethical`          | conceito *é* sobre ética             |
| Tecnologia & Criação    | `analogy_bridge`   | tech → mundo físico                    |
| Resolver Problemas      | `analogy_bridge`   | algoritmo de um domínio em outro       |
| Vida & Sociedade        | `ethical`          | comportamento social → norma           |

**Trabalho.**
- Escrever 31 payloads curados, 1 por concept, contra o schema
  `app/services/academy/lens/schemas/{analogy_bridge|ethical}.json`.
- Cada payload precisa ser autoral (não copiar few-shot — gap já documentado
  em `audits/2026-05-17-academy-lens-v3-followups.md#1`).
- Atualizar `db/seeds/academy/lens_payloads.rb` (ou onde estiverem hoje os
  102 que rodaram em `9bb3a3e`) e rodar `make seed` p/ popular
  `Academy::LensCache(source: 'curated')`.

**Aceite.**
- `LensCache.curated.where(age_band:'kid', locale:'pt-BR', lens_type:
  %i[analogy_bridge ethical]).distinct.pluck(:concept_id).size >=
  number_of_active_concept_ids`.
- Replay de uma missão random hoje "3-stage" mostra 4 stages na barra de
  progresso e termina com a closure lens visível.

**Estimativa.** ~30 min por payload × 31 = ~15h se for autoral. Cabe em
2-3 sessões com diviida por subject.

---

## G-2 — Validar transferência: trail unlock + atlas mint (P1)

**Problema observado.** No playthrough, terminei a missão #1 da trilha
"Quem manda no seu dinheiro?" (6 missões). Não cliquei "Próxima missão"
nem verifiquei se a #2 destravou. Também não confirmei se o
`Cards::MintAfterMission` (hook do `AdvanceLens#finalize_mission!`
documentado no CLAUDE.md) populou o atlas. Pode haver regressão silenciosa.

**Trabalho.**
- Adicionar spec system `spec/system/academy/trail_unlock_spec.rb` que
  fecha missão #1, recarrega a trail e verifica que a #2 ficou clicável e
  a #3 ainda travada.
- Spec para `Cards::MintAfterMission`: pós-finalize, existe 1 nova
  `DiscoveryCard` apontando para o concept da missão.
- Smoke manual no `/kid/academy/atlas` para confirmar UI.

**Aceite.** Specs verdes; atlas mostra o card minted após o playthrough.

---

## G-3 — Completion screen comunica transferência (P1)

**Problema.** A tela de fim hoje é `MISSÃO COMPLETA · 3 lições percorridas
sobre Recompensa imediata` + 3 cards de revisão. Em nenhum lugar aparece
o "e agora? o que isso desbloqueia? qual foi a sacada?".

**Trabalho.**
- Reusar o headline da closure lens (quando G-1 entregar) como "A sacada".
- Mostrar o card minted (G-2) como "Pra sua coleção" com link pro atlas.
- Mostrar trail progress (`mission 1 de 6 ✓`) + CTA pra próxima.
- Files: `app/views/kid/academy/missions/_completion.html.erb` (criar) +
  enabling no `kid/academy/missions_controller#advance` quando
  `result.data.mission_complete?`.

**Aceite.** Tela final deixa de ser meramente um "ok terminou".

---

## G-4 — 503 → fallback amigável real (P2)

**Problema.** Mesmo com o fix de `ChooseNext`, há paths em
`AdvanceLens#try_generate_with_fallbacks!` que ainda podem retornar
`:lens_generation_failed` (concept com curated mas LensCache row marcada
`quality_flagged: true`, por ex). Hoje isso vira a tela "VOLTA EM
INSTANTES — A Academia tá pensando", que é polida mas mente: nada está
pensando, simplesmente não há conteúdo.

**Trabalho.**
- Quando `AdvanceLens` falha com `:lens_generation_failed`, em vez de
  503, finalizar a missão como `mission.status = :graceful_exit` (novo
  enum) e redirecionar pra completion screen com mensagem "essa missão
  ficou curta — voltamos com mais em breve".
- Alertar via `LensSignal(signal_type: 'curated_gap_hit')` para o app
  parent poder ver no Library quais missões estão rasas.

**Aceite.** Provocar a falha (flag temporário em um payload curated) e
ver o kid receber completion graceful em vez de placeholder.

---

## G-5 — Guarda: missão ativa sem curated coverage (P2)

**Problema.** Hoje 18 concepts (`identidade`, `foco`, `ceticismo`,
`atencao`, ...) **não** têm payload curado e qualquer missão criada
contra eles renderia o erro `:concept_missing`/`:lens_generation_failed`.
Felizmente as 42 missões ativas todas têm coverage. Mas nada impede um
parent de cadastrar uma missão nova apontando pra um concept dormente
(via `/admin/academy/missions/:id/edit`).

**Trabalho.**
- Validação no model `Academy::Mission`:
  `validate :concept_must_have_curated_kid_payload, if: :active?`.
- Mensagem amigável no admin form: "Esse conceito ainda não tem aula
  curada — não pode publicar."

**Aceite.** Tentar `active: true` num mission do concept `foco` falha
validação; admin form mostra erro.

---

## G-6 — Sticky bottom nav cobre conteúdo (P3, cosmético)

**Observação.** Nos screenshots full-page do playthrough, o bottom nav
("JORNADA · ACADEMIA · LOJINHA · DIÁRIO") aparece flutuando sobre a
pergunta nos stages 2-3-7. Pode ser artefato do screenshot full-page
(viewport real talvez não cubra), mas vale checar com Lighthouse mobile
no viewport real.

**Trabalho.**
- Reproduzir no viewport iPhone SE (375×667). Se o nav cobre conteúdo na
  parte de baixo, adicionar `padding-bottom: 88px` (altura do nav + 16px)
  ao container `<main>` quando o nav está presente.

**Aceite.** Em 375×667 a última linha do conteúdo (botão Continuar)
permanece visível com o nav ancorado.

---

## Fora deste plano (já tracked em outro lugar)

- Clonagem do few-shot hardcoded → `audits/2026-05-17-academy-lens-v3-followups.md#1`
- Drift no `analogy_bridge` → `audits/2026-05-17-academy-lens-v3-followups.md#3`
- Repensar HARD_CAP e COVERAGE_FLOOR como configurações por concept →
  só se G-1 não der conta de uniformizar.

## Ordem sugerida de execução

1. G-5 (1h) — fecha a porta antes de abrir mais salas.
2. G-1 lote 1 (1 subject = ~2h) — valida o workflow de curadoria.
3. G-2 (1h) — specs que garantem que não regredimos enquanto curamos.
4. G-1 demais lotes em paralelo (Mente Forte + Dinheiro + outros).
5. G-3 (~2h) com G-1 entregue.
6. G-4 (~1h) — defensive depois que o caminho feliz está sólido.
7. G-6 quando der.

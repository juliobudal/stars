# Phase 0 — Research & Curatorial Lock

**Feature**: 003-academy-content-arcs-next

Decisões de conteúdo resolvidas antes do seed. Tudo aqui já reflete as Clarifications travadas no spec. Objetivo: chegar em `/speckit-tasks` com os 8 enigmas e a base factual fechados, sem `NEEDS CLARIFICATION`.

---

## D1 — Mecânica do `ArcValidator` (restrições que o conteúdo DEVE respeitar)

**Decisão**: escrever o conteúdo já conformado ao que o validador checa (revisão de `app/services/academy/content/arc_validator.rb`).

- **Refrão (FR-002)**: `includes_norm?` casa a frase **contígua** normalizada (minúsculas, sem acento) na `revelation` de **cada** aula. Logo o refrão precisa aparecer **literalmente** (ignorando acento) em todas as 4 revelações da trilha.
  - T6 → `"quase vazio"` em cada revelação. T7 → `"emprestado do universo"` em cada revelação.
- **Callback (FR-003)**: âncora casada por **início de palavra** no texto completo da 1ª e da última aula (título+enigma+pistas+revelação+hook+check).
  - T6 → `"mão"` (casa "mão/mãos"). T7 → `"osso"` (casa "osso/ossos").
- **Marcador de arco (FR-001)**: aparece no `hook` **da trilha** (gancho de abertura) **e** no texto da **última** aula.
  - T6 → `"encostar"` (casa "encostar"; cuidado: "encosta/encostou" NÃO casa `\bencostar` — usar a forma "encostar" literal no hook e na última aula). T7 → `"explosão"` (casa "explosão/explosões").
- **Cliffhanger (FR-004)**: o `hook` da última aula deve conter o **título exato** da trilha-destino, contíguo e normalizado.
  - `as-palavras-mudam` (existente) → hook final deve conter **"Tudo que parece sólido é quase vazio"** literal.
  - T6 → hook final deve conter **"Você é feito de estrelas mortas"** literal.
  - T7 → `cliffhanger_to: nil` (última do conjunto): sem título-destino; gancho aberto.
- **Anti-clichê (FR-005)**: nenhuma frase da lista negra (`reflita sobre`, `moral da história`, `nunca desista`, `acredite em você`, `siga seus sonhos`, `o importante é`, `lição de vida`, `sempre acredite`, `o céu é o limite`). Versículos entram como **descoberta** (quem disse, quando), nunca como moral.

**Implicação para o seed**: declarar `refrao/callback_anchor/arc_payload_marker/cliffhanger_to` por trilha e garantir as ocorrências literais acima. O seed faz `raise` se algo faltar — falha cedo.

---

## D2 — T6 "Tudo que parece sólido é quase vazio" (`tudo-quase-vazio`)

**Gancho de abertura da trilha (`hook`)** — contém o marcador `encostar`:
> "Bate na mesa: parece sólida, dura, cheia. Mentira. Ela é quase toda buraco — e tem outra: você nunca, nem uma vez na vida, conseguiu **encostar** de verdade em nada. Vamos pegar isso no flagra."

| # | slug | Enigma | Núcleo da revelação (contém `quase vazio`) | Hook → |
|---|---|---|---|---|
| 1 | `mao-mais-buraco` | "Se a sua mão é tão cheia e sólida, por que ela é quase toda… buraco?" | Cada átomo é um caroço minúsculo no meio e o resto, espaço. Junta bilhões e dá a **mão**, que parece cheia mas é **quase vazio**. | "Se é tudo vazio, por que a mão não atravessa a mesa? E será que você já encostou em algo de verdade?" |
| 2 | `nunca-encostou` | "Você toca tudo o dia inteiro. E se eu disser que você nunca encostou em coisa nenhuma?" | Os elétrons da sua pele empurram os elétrons da mesa antes de se tocarem. Você sente o empurrão, não o toque: dois **quase vazio** se repelindo. | "Se nem encosta, por que a mesa segura o copo e não deixa tudo afundar?" |
| 3 | `vazio-nao-desaba` | "Se tudo é quase vazio, por que a cadeira aguenta seu peso?" | A rigidez não vem de estar 'cheio': vem das forças que prendem os átomos. Mesmo material **quase vazio**, arrumado de outro jeito, vira diamante ou grafite. | "Se a solidez é uma força e não 'coisa cheia'… quanto de você é matéria de verdade?" |
| 4 | `torrao-de-acucar` (última) | "Hora de pagar a promessa: tudo é quase vazio e você nunca encostou em nada — e daí?" | Reabre o gancho: a **mão** cheia é **quase vazio**; o toque nunca **encostar**; tirando o vazio, a humanidade inteira caberia, mais ou menos, num torrão de açúcar. **Descoberta**: Salmo 8 — "que é o homem para que dele te lembres?". | (cliffhanger T7) "Sobra um tiquinho de matéria real em você. De onde veio? De uma estrela que explodiu. Próxima trilha: **Você é feito de estrelas mortas**." |

Metadados: `refrao: "quase vazio"`, `callback_anchor: "mão"`, `arc_payload_marker: "encostar"`, `cliffhanger_to: "voce-feito-de-estrelas"`, `emoji` ✋/⚛️, `accent` reutilizar paleta existente (ex.: `lilac`/`sky` — decidir no seed conforme tokens válidos).

---

## D3 — T7 "Você é feito de estrelas mortas" (`voce-feito-de-estrelas`)

**Gancho de abertura da trilha (`hook`)** — contém o marcador `explosão`:
> "O ferro do seu sangue, o cálcio do seu **osso** — nada disso nasceu na Terra. Tudo veio da **explosão** de uma estrela, há bilhões de anos. Você é, de verdade, feito de estrela morta."

| # | slug | Enigma | Núcleo da revelação (contém `emprestado do universo`) | Hook → |
|---|---|---|---|---|
| 1 | `ferro-do-sangue` | "O que o ferro do seu sangue tem a ver com uma estrela?" | No começo só havia hidrogênio e hélio. As estrelas são fornos que fundem átomos; o ferro do sangue e o cálcio do **osso** nasceram lá e foram cuspidos numa explosão. Esses átomos estão **emprestados do universo**. | "Se seu osso veio de uma estrela… ele é seu mesmo, ou só está de passagem?" |
| 2 | `troca-de-corpo` | "Você ainda é feito dos mesmos pedacinhos de um ano atrás?" | Quase todas as suas peças se trocam com o tempo: você é mais um desenho que se mantém do que um material fixo. Os átomos são **emprestados do universo** e devolvidos. | "Se os átomos entram e saem… por onde eles andaram antes de chegar em você?" |
| 3 | `respira-dinossauro` | "Será que você respirou um pedacinho de dinossauro hoje?" | Os mesmos átomos circulam há bilhões de anos. É bem provável que algum do ar de agora já tenha passado por um dinossauro. Tudo **emprestado do universo**, em rodízio. | "Se nada é novo e tudo circula… o que acontece com seus átomos depois de você?" |
| 4 | `nada-se-perde` (última) | "Para onde vai a estrela que te formou, quando você devolve?" | Reabre o gancho: o **osso** veio de uma **explosão** e volta pro rodízio — vira terra, planta, outro bicho. Você é um **emprestado do universo**. **Descobertas**: Gênesis 3:19 ("pó és, e ao pó voltarás") e Carl Sagan ("somos feitos de poeira de estrelas"). | (gancho aberto — última trilha) "E o mais estranho: esses mesmos átomos emprestados, arrumados de um certo jeito, conseguem se perguntar de onde vieram. Por que justo essa arrumação 'acorda' e pensa? Esse é o maior mistério — e a caçada continua." |

Metadados: `refrao: "emprestado do universo"`, `callback_anchor: "osso"`, `arc_payload_marker: "explosão"`, `cliffhanger_to: nil`, `emoji` ✨/💫, `accent` reutilizar paleta existente.

---

## D4 — Edição mínima na trilha existente `as-palavras-mudam`

**Decisão**: única mudança nas 5 trilhas atuais (FR-104). Hoje a fisgada final é um gancho aberto. Passar:
- `cliffhanger_to: nil` → `cliffhanger_to: "tudo-quase-vazio"`.
- `hook` da última aula (`descoberta-3000-anos`) → passar a conter, literal, **"Tudo que parece sólido é quase vazio"**, mantendo o tom (não trocar o resto do conteúdo). Ex.: "…uma palavra é uma lente. Mas e se a coisa mais sólida que você conhece — sua própria mão — for quase toda buraco? Próxima trilha: **Tudo que parece sólido é quase vazio**."

Nenhuma outra aula/trilha existente muda. Refrão/callback/marker de `as-palavras-mudam` permanecem como estão.

---

## D5 — Base factual e ressalvas (precisão para 7–10, sem mentir)

| Afirmação no conteúdo | Status factual | Ressalva aplicada |
|---|---|---|
| Átomo é "quase todo vazio" | ✅ Núcleo ~10⁻¹⁵ m vs. átomo ~10⁻¹⁰ m | Analogia "caroço no meio, resto espaço" — sem números no texto da criança. |
| Você "nunca encosta" (repulsão eletromagnética) | ✅ Repulsão entre nuvens de elétrons | Apresentar como "empurrão", não negar a sensação ("seu cérebro inventa o toque"). |
| Humanidade inteira caberia num torrão de açúcar | ✅ Ordem de grandeza (densidade nuclear) | Usar "mais ou menos / quase" — é estimativa, não medida exata. |
| Rigidez = forças/arranjo, não 'estar cheio' | ✅ Ligações químicas; diamante vs. grafite | Exemplo concreto carbono → diamante/grafite. |
| Ferro/cálcio nasceram em estrelas | ✅ Nucleossíntese estelar; elementos pesados em supernovas | Simplificar "fornos que explodem e espalham" — não detalhar fusão até o ferro. |
| "Quase todas as peças do corpo se trocam" | ⚠️ Parcial (neurônios e esmalte do dente persistem) | Usar "quase tudo se renova", nunca "tudo" nem "a cada 7 anos". |
| Respirou átomo de dinossauro | ✅ Argumento de probabilidade (Avogadro) | Usar "é bem provável", não "com certeza". |
| Matéria se conserva / recicla | ✅ Conservação da matéria | Direto. |
| Salmo 8 / Gênesis 3:19 / Sagan | ✅ Citações reais | Sempre como **descoberta** (quem, quando), nunca moral (FR-005/FR-110). |

---

## D6 — Backlog priorizado (Tier A) — sementes para a próxima iteração

Não implementado nesta feature; registrado para `/speckit-specify` futuro (SC-106).

1. **"A água quebra todas as regras"** — gelo flutua (e salvou os peixes) · inseto anda na água · Mpemba · capilaridade. Escore alto em concretude/demonstrável.
2. **"Frio não existe"** — só falta de calor · metal vs. madeira na mesma temperatura · zero absoluto. Alto em counterintuitividade.
3. **"Tem um mundo vivo dentro de você"** — mais bactérias que células · mitocôndria já foi bactéria · eixo intestino-humor. Alto em profundidade.

---

## Resultado

Todos os 8 enigmas, revelações-núcleo, ganchos e metadados de arco estão travados e conformados ao `ArcValidator`. Zero `NEEDS CLARIFICATION` remanescente. Pronto para `data-model.md`/`contracts/` e depois `/speckit-tasks`.

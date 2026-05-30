# Phase 1 — Data Model

**Feature**: 003-academy-content-arcs-next

> **Zero schema novo.** Esta feature não cria nem altera tabelas/colunas `academy_*`. O "modelo" abaixo descreve apenas a **forma do conteúdo curado** em `db/seeds/academy_content.rb` (constante `ACADEMY_CONTENT`) e como ele mapeia para as colunas já existentes de `Academy::Trail`/`Academy::Lesson`. Tudo herdado de `002`.

## Persistência (existente, inalterada)

- `academy_trails`: `slug`, `title`, `position`, `active`, `emoji`, `accent`, `hook`, `payload`(jsonb)…
- `academy_lessons`: `slug`, `title`, `position`, `enigma`, `payload`(jsonb), FK lógica para a trilha…

Os **metadados de arco** (`refrao`, `callback_anchor`, `arc_payload_marker`, `cliffhanger_to`) **não são persistidos**: existem só no seed e são consumidos pelo `ArcValidator` no build. (FR-108)

## Entidade: Trilha curada (item de `ACADEMY_CONTENT`)

| Campo | Tipo | Papel nesta feature |
|---|---|---|
| `slug` | string | `tudo-quase-vazio`, `voce-feito-de-estrelas` |
| `title` | string | Título exato (usado pelo cliffhanger da trilha anterior — casa literal) |
| `hook` | string | Enigma de abertura do arco; **deve conter o `arc_payload_marker`** |
| `emoji` / `accent` | string | Apresentação; `accent` reutiliza token válido de DESIGN.md |
| `refrao` | string (meta) | Frase contígua presente na `revelation` de **todas** as aulas |
| `callback_anchor` | string (meta) | Termo concreto presente na 1ª **e** na última aula |
| `arc_payload_marker` | string (meta) | Termo do gancho que **paga** na última aula |
| `cliffhanger_to` | string \| nil (meta) | Slug da trilha-destino, ou `nil` na última do conjunto |
| `lessons[]` | array | Exatamente **4** aulas ordenadas |

## Entidade: Aula curada (`lessons[]`)

| Campo | Tipo | Papel |
|---|---|---|
| `slug` | string | Identificador da aula dentro da trilha |
| `title` | string | Título da pílula |
| `enigma` | string | A pergunta-isca |
| `payload.clues[]` | array(string) | 3 pistas que conduzem à revelação |
| `payload.revelation` | string | Resposta + **refrão** da trilha; na última aula, **reabre/resolve** o enigma de abertura |
| `payload.check` | object | `{ kind, prompt, options[], answer_index, explanation }` |
| `payload.hook` | string | Fisgada; na última aula nomeia o **título** da trilha-destino (ou gancho aberto) |

## Regras de validação (impostas pelo `ArcValidator`, sem código novo)

1. `revelation` de cada aula ⊇ `refrao` (contíguo, sem acento). 
2. Texto da 1ª e da última aula ⊇ `callback_anchor` (word-start). 
3. `trail.hook` ⊇ `arc_payload_marker` **e** texto da última aula ⊇ `arc_payload_marker`. 
4. `cliffhanger_to` existe + está `active`; `hook` da última aula ⊇ `title` da trilha-destino (contíguo). `nil` ⇒ sem destino (gancho aberto). 
5. Nenhuma frase da lista negra anti-clichê em nenhum texto da trilha. 
6. (Curatorial, revisão humana — FR-101) 4 aulas com revelações **distintas**; nenhuma repetição de payoff.

## Transições de estado (existentes, inalteradas)

Status de aula `locked → available → completed` continua governado por `Academy::Lessons::Available`/`Complete` por **ordem** (`position`). As trilhas novas entram no fim do catálogo (maiores `position`), desbloqueadas em sequência como as demais. Nenhuma lógica de progressão muda.

## Conjunto final (após a feature)

| position | slug | cliffhanger_to |
|---|---|---|
| … | seu-cerebro-mente | o-corpo-faz-isso |
| … | o-corpo-faz-isso | forcas-invisiveis |
| … | forcas-invisiveis | a-luz-noticia-velha |
| … | a-luz-noticia-velha | as-palavras-mudam |
| … | as-palavras-mudam | **tudo-quase-vazio** *(era nil)* |
| nova | **tudo-quase-vazio** | **voce-feito-de-estrelas** |
| nova | **voce-feito-de-estrelas** | nil *(gancho aberto)* |

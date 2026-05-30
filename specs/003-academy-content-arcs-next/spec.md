# Feature Specification: Academy — Próximas Trilhas (priorizadas por qualidade de conteúdo)

**Feature Branch**: `003-academy-content-arcs-next`

**Created**: 2026-05-29

**Status**: Draft

**Input**: User description: "Planejar as próximas trilhas do Academy priorizando por nível de qualidade do conteúdo. Continuar o arco de cliffhanger cruzado, fechar a ponta solta de 'As palavras mudam o que você enxerga', e adicionar trilhas novas de altíssima qualidade (a começar por 'Tudo que parece sólido é quase vazio' e 'Você é feito de estrelas mortas'). Só conteúdo (payload + seeds), sem schema, mantendo os cinco padrões de arco já validados."

## Contexto

Feature **incremental** sobre `002-academy-content-arcs` (arcos narrativos, shipado nesta linha de trabalho). O motor de trilhas/aulas e os cinco padrões de arco (refrão declarado, callback à aula 1, pagamento do enigma de abertura na última aula, cliffhanger cruzado nominal, lista negra anti-clichê) já existem e **não mudam** — são reaproveitados como régua de qualidade via `Academy::Content::ArcValidator`.

O catálogo atual tem **5 trilhas encadeadas**: cérebro → corpo → forças invisíveis → luz → linguagem. A última (`as-palavras-mudam`) está com `cliffhanger_to: nil` (ponta solta). Esta feature **amplia o catálogo** com trilhas novas, **priorizando por qualidade de conteúdo** (não por tema ou volume), e fecha a ponta solta encadeando a primeira trilha nova.

O escopo desta feature é **conteúdo + priorização**: definir o critério de qualidade, rankear o backlog de trilhas candidatas, e entregar as trilhas de tier mais alto seedadas e validadas. Nenhuma tabela/coluna nova; tudo via `payload` jsonb de `Academy::Lesson`, metadados de arco no seed (`db/seeds/academy_content.rb`) e views/parciais já existentes.

## Decisões de produto (travadas com o usuário)

1. **Ordem de entrega = qualidade de conteúdo primeiro** — as trilhas são priorizadas por um escore de qualidade explícito, não por área temática nem por encaixe cronológico. As de tier mais alto entram primeiro.
2. **Continuidade = manter o cliffhanger cruzado** — a ponta solta de `as-palavras-mudam` passa a apontar para a primeira trilha nova; as trilhas novas encadeiam entre si; a última do conjunto fica com gancho aberto (`cliffhanger_to: nil`).
3. **Mesma banda etária (~7–10) e mesmo formato pílula** (enigma → pistas → revelação → teste → fisgada). Nada de níveis por idade nem passos novos.
4. **Escopo técnico = só conteúdo** — sem schema novo; reusa `ArcValidator` como gate de qualidade no build do seed e na suíte.

## Critério de qualidade de conteúdo (FR-101)

Cada trilha candidata é pontuada de 1–5 em seis eixos. O escore guia a priorização:

1. **"Não acredito que é real"** — counterintuitividade verificável (o motor da pílula).
2. **Concretude** — a criança consegue ver, testar ou sentir o fenômeno (não é puramente abstrato).
3. **Profundidade** — rende 4 enigmas distintos, cada um com payoff limpo (sem repetir a mesma revelação).
4. **Refrão escalável** — existe uma frase-âncora que cresce de sentido/escopo aula a aula.
5. **Encaixe no arco** — continua o fio condutor do catálogo e oferece cliffhanger cruzado natural.
6. **Valor formativo sem clichê** — fascínio genuíno; pode incorporar versículo bíblico ou filósofo **como descoberta** (quem disse, quando), nunca como moral.

## Backlog priorizado (resultado da aplicação do critério)

> O ranking é parte da entrega. As trilhas de Tier S são as **obrigatórias** desta feature; as demais ficam como backlog priorizado para iterações seguintes.

### Tier S — entregar nesta feature

- **T6 · "Tudo que parece sólido é quase vazio"** (átomos / vazio / você nunca toca em nada). Capstone do arco "a realidade não é o que parece": as 5 atuais tratam da *percepção*; esta vira a chave para a *própria matéria*. Recebe o cliffhanger de `as-palavras-mudam`.
- **T7 · "Você é feito de estrelas mortas"** (átomos forjados em supernovas / ciclo da matéria). Costura de volta na trilha de astronomia (`a-luz-noticia-velha`), fechando um macro-arco de catálogo.

### Tier A — backlog priorizado (próximas iterações)

- **"A água quebra todas as regras"** (anomalias da água — gelo flutua, tensão superficial, Mpemba, capilaridade). Mais demonstrável em casa.
- **"Frio não existe"** (calor/termodinâmica — só falta de calor; metal vs. madeira; zero absoluto).
- **"Tem um mundo vivo dentro de você"** (microbioma / mitocôndria — mais bactérias que células; eixo intestino-humor).

### Tier B — banco de ideias (não priorizado)

- Sentidos animais (campo magnético, ecolocalização) · O som faz coisas que você não vê (ressonância) · Padrões que se repetem (fractais) · As plantas conversam · O acaso engana você (probabilidade).

## Clarifications

### Session 2026-05-29

- Q: Por qual eixo priorizar as próximas trilhas? → A: Qualidade de conteúdo (escore de 6 eixos), não tema nem volume; tiers S/A/B.
- Q: Quantas trilhas novas entram NESTA feature? → A: As 2 de Tier S (T6 vazio, T7 estrelas); o resto fica como backlog priorizado documentado.
- Q: Como a ponta solta de `as-palavras-mudam` é resolvida? → A: Passa a apontar (`cliffhanger_to`) para T6; T6 → T7; T7 fica com gancho aberto (`nil`).
- Q: Quantas aulas por trilha Tier S? → A: Exatamente 4 (igual ao catálogo atual; sem variação).
- Q: Slugs e wiring do cliffhanger das novas? → A: T6 slug `tudo-quase-vazio`, T7 slug `voce-feito-de-estrelas`; cadeia `as-palavras-mudam` → `tudo-quase-vazio` → `voce-feito-de-estrelas` → `nil`.
- Q: Metadados de arco de T6 ("Tudo que parece sólido é quase vazio")? → A: `refrao: "quase vazio"`, `callback_anchor: "mão"`, `arc_payload_marker: "encostar"`.
- Q: Metadados de arco de T7 ("Você é feito de estrelas mortas")? → A: `refrao: "emprestado do universo"`, `callback_anchor: "osso"`, `arc_payload_marker: "explosão"`.
- Q: A âncora formativa (versículo/filósofo) é opcional ou obrigatória nas Tier S? → A: Obrigatória ≥1 por trilha Tier S, sempre como descoberta — T6: Salmo 8; T7: Gênesis 3:19 + Carl Sagan ("stardust").

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Continuar para uma trilha nova depois da última atual (Priority: P1)

A criança termina `As palavras mudam o que você enxerga` — hoje um beco sem saída (gancho aberto). Com a feature, a fisgada final dessa trilha passa a **nomear e provocar** o mistério da primeira trilha nova ("Tudo que parece sólido é quase vazio"), dando vontade de continuar. Ela entra na trilha nova e percorre um arco completo de qualidade equivalente às anteriores.

**Why this priority**: É o ganho direto de retenção — transformar a atual ponta morta do catálogo em uma continuação desejável, e provar que o catálogo pode crescer sem perder qualidade.

**Independent Test**: Logar como kid → concluir a última aula de `as-palavras-mudam` → verificar que a fisgada nomeia "Tudo que parece sólido é quase vazio" → abrir a trilha nova e completá-la ponta a ponta confirmando os cinco padrões de arco.

**Acceptance Scenarios**:

1. **Given** o seed atualizado, **When** a criança vê a fisgada final de `as-palavras-mudam`, **Then** ela nomeia a trilha "Tudo que parece sólido é quase vazio" (não um texto genérico).
2. **Given** a trilha T6 nova, **When** percorrida do início ao fim, **Then** ela satisfaz FR-001..FR-005 (refrão em todas as aulas, callback à aula 1, pagamento do enigma de abertura, cliffhanger nominal para T7, zero frase da lista negra).
3. **Given** a trilha T7 nova, **When** a criança chega à última aula, **Then** o enigma de abertura é reaberto e resolvido e a fisgada é um gancho aberto (última do conjunto, `cliffhanger_to: nil`).

---

### User Story 2 - Sentir que as trilhas novas têm o mesmo nível das antigas (Priority: P1)

A criança (e o pai que revisa) não deve perceber "duas qualidades" de trilha. As trilhas novas precisam ter o mesmo tom de mistério+fascínio, a mesma densidade de fenômeno real por aula, e o mesmo cuidado anti-clichê das 5 atuais.

**Why this priority**: A priorização-por-qualidade só vale se a régua for objetiva. Sem isso, "mais trilhas" vira diluição.

**Independent Test**: Rodar o `ArcValidator` sobre o conjunto completo (5 antigas + 2 novas) no build do seed e na spec → zero violações. Revisão qualitativa contra os seis eixos de FR-101 para cada trilha nova.

**Acceptance Scenarios**:

1. **Given** o conjunto final de trilhas, **When** o seed roda, **Then** o `ArcValidator` retorna zero violações e o build não falha.
2. **Given** cada trilha nova, **When** avaliada contra os seis eixos de FR-101, **Then** pontua de forma comparável às trilhas existentes (sem aula "fraca" que repita revelação ou caia em clichê).
3. **Given** o catálogo após a feature, **When** a criança percorre da primeira à última trilha, **Then** não encontra quebra de continuidade do cliffhanger nem trilha-destino inexistente/inativa.

---

### User Story 3 - Backlog priorizado para o que vem depois (Priority: P3)

O time de conteúdo precisa saber **o que entra a seguir e por quê**. A feature entrega, além das trilhas T6/T7, um backlog priorizado por qualidade (Tiers S/A/B) com escores justificados, para guiar as próximas iterações sem re-discutir do zero.

**Why this priority**: Valor de planejamento, não de runtime — não bloqueia o ganho de retenção (US1/US2), mas evita retrabalho.

**Independent Test**: Abrir a spec → confirmar que existe um ranking com critério explícito, escores e justificativa por trilha candidata, e que as trilhas entregues correspondem ao Tier S.

**Acceptance Scenarios**:

1. **Given** a spec, **When** lida pelo time, **Then** há um critério de qualidade explícito (FR-101) e um backlog rankeado em tiers.
2. **Given** o backlog, **When** uma trilha de Tier A for escolhida para a próxima iteração, **Then** ela já tem tema, enigmas-semente e justificativa de escore registrados.

---

### Edge Cases

- **Quebra do cliffhanger atual**: ao mudar `as-palavras-mudam` de `nil` para T6, a validação MUST confirmar que T6 existe e está ativa; senão o build falha cedo.
- **Trilha nova com fenômeno difícil de verificar**: se um eixo "concretude" cair muito (ex.: tema abstrato demais para 7–10), a trilha é rebaixada de tier — não entra só por ser "legal".
- **Revelação repetida entre aulas**: duas aulas da mesma trilha com a mesma revelação violam FR-101 (profundidade) mesmo que passem no `ArcValidator`; revisão qualitativa MUST pegar.
- **Última trilha do conjunto**: T7 não declara destino; fisgada aberta. Não pode nomear trilha inexistente.
- **Regressão nas 5 atuais**: nenhuma das trilhas existentes pode quebrar; só `as-palavras-mudam.cliffhanger_to` muda (de `nil` para T6).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-101 (Critério de qualidade explícito)**: A feature MUST definir e aplicar um escore de qualidade de conteúdo em seis eixos (counterintuitividade, concretude, profundidade, refrão escalável, encaixe no arco, valor formativo sem clichê) e priorizar as trilhas por esse escore — não por tema nem por volume.
- **FR-102 (Backlog priorizado)**: A feature MUST entregar um backlog rankeado em tiers (S/A/B) com justificativa de escore por trilha candidata, do qual o Tier S é o escopo obrigatório desta iteração.
- **FR-103 (Trilhas Tier S entregues)**: A feature MUST seedar e validar **2 trilhas novas de Tier S**, cada uma com **exatamente 4 aulas** (igual ao catálogo atual), satisfazendo todos os cinco padrões de arco (FR-001..FR-005 de `002`):
  - **T6 — "Tudo que parece sólido é quase vazio"** (slug `tudo-quase-vazio`): `refrao: "quase vazio"`, `callback_anchor: "mão"`, `arc_payload_marker: "encostar"`.
  - **T7 — "Você é feito de estrelas mortas"** (slug `voce-feito-de-estrelas`): `refrao: "emprestado do universo"`, `callback_anchor: "osso"`, `arc_payload_marker: "explosão"`.
- **FR-104 (Fechar a ponta solta)**: A trilha `as-palavras-mudam` MUST passar a declarar `cliffhanger_to: "tudo-quase-vazio"`, e sua fisgada final MUST nomear o mistério de T6. Essa é a **única** mudança de conteúdo nas 5 trilhas existentes (só o campo `cliffhanger_to` e o `hook` da última aula).
- **FR-105 (Encadeamento das novas)**: T6 MUST declarar `cliffhanger_to: "voce-feito-de-estrelas"` e sua fisgada final MUST nomear o mistério de T7. T7 MUST ser a última do conjunto (`cliffhanger_to: nil`) com fisgada de gancho aberto.
- **FR-106 (Reuso do gate de qualidade)**: O conteúdo novo MUST passar pelo `Academy::Content::ArcValidator` no build do seed (falha cedo) e na suíte de testes (gate de CI); zero violações no conjunto completo (5 antigas + 2 novas).
- **FR-107 (Formato e idade preservados)**: As trilhas novas MUST manter o formato enigma → pistas → revelação → teste → fisgada e a banda única ~7–10, sem passos novos nem variação por idade.
- **FR-108 (Zero schema)**: A feature MUST NOT alterar o schema — nenhuma tabela/coluna nova em `academy_*`; toda a expressão de arco vive no `payload` jsonb e nos metadados de arco do seed.
- **FR-109 (Sem regressão)**: As 5 trilhas existentes MUST continuar funcionando (home → trilha → aula → conclusão → próxima) após a mudança; a suíte do módulo MUST permanecer verde e o seed MUST rodar sem erro.
- **FR-110 (Âncora formativa obrigatória nas Tier S)**: Cada trilha Tier S MUST incluir **ao menos uma** âncora formativa apresentada como **descoberta** (quem disse, quando), nunca como moralização — T6 usa o Salmo 8; T7 usa Gênesis 3:19 ao lado de Carl Sagan ("stardust"). Demais trilhas PODEM incluir âncoras formativas no mesmo registro.
- **FR-111 (Design vigente)**: A apresentação MUST seguir o sistema vigente (DESIGN.md / redesign 001); qualquer parcial reusa `Ui::*` e tokens existentes e honra `prefers-reduced-motion`. Não há nova UI prevista.

### Key Entities *(payload — sem schema novo)*

- **Trail (Trilha)**: já existe. Cada trilha nova declara, no seed, os metadados de arco: `refrao`, `callback_anchor`, `arc_payload_marker`, `cliffhanger_to` (slug | nil). O `hook` da trilha é o enigma de abertura do arco.
- **Lesson.payload (jsonb)**: já existe. Convenções de arco aplicadas ao conteúdo novo: `revelation` carrega o refrão; `clues[]`/`revelation` da última aula reabrem e resolvem o enigma de abertura e contêm o callback à aula 1; `hook` da última aula nomeia o destino do cliffhanger.
- **Backlog priorizado (artefato de planejamento, não persistido)**: ranking em tiers com escores por eixo; vive nesta spec e guia iterações futuras.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-101**: O catálogo passa de **5 para 7 trilhas ativas**, todas com **≥ 4 aulas**, sem nenhuma trilha existente removida ou regredida.
- **SC-102**: Em **100%** das trilhas novas, os cinco padrões de arco são satisfeitos — `ArcValidator` retorna **zero** violações no conjunto completo.
- **SC-103**: A cadeia de cliffhanger fica **sem ponta morta intermediária**: `as-palavras-mudam` → T6 → T7 → gancho aberto; **0** referências de cliffhanger quebradas (destino inexistente/inativo).
- **SC-104**: A criança ainda completa uma aula em **≤ 3 minutos** (o arco não alonga a pílula individual) e percorre as trilhas novas sem encontrar conteúdo clichê (avaliação qualitativa contra FR-101 e a lista negra de FR-005).
- **SC-105**: A suíte RSpec do módulo permanece **100% verde** e o seed roda sem erro; **zero** mudanças de schema (nenhuma migration nova).
- **SC-106**: A spec contém um backlog priorizado com **≥ 3 trilhas de Tier A** documentadas (tema + enigmas-semente + justificativa de escore) para a próxima iteração.

## Assumptions

- O motor do Academy e o `ArcValidator` (de `002`) estão estáveis e são a régua de qualidade — esta feature não os altera.
- A faixa etária única (~7–10) continua suficiente; sem adaptação por idade.
- "Qualidade de conteúdo" é avaliável: parte por validação automática (os cinco padrões + lista negra) e parte por revisão humana contra os seis eixos de FR-101 (profundidade e ausência de revelação repetida não são 100% automatizáveis).
- O cliffhanger cruzado segue com destino curado por trilha (slug no seed), validado no build; sem FK nem coluna de ligação.
- Os temas de Tier S (átomos/vazio e estrelas/matéria) são adequados a 7–10 com analogias concretas (a mão, o osso, encostar, a explosão). Os slugs e metadados de arco estão **travados** (ver Clarifications); a concretude é resolvida por analogia no conteúdo, não rebaixando a trilha.
- Visual e componentes seguem DESIGN.md; nenhuma nova dependência de UI é necessária.

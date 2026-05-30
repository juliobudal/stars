# Feature Specification: Academy — Arcos Narrativos nas Trilhas

**Feature Branch**: `002-academy-content-arcs`

**Created**: 2026-05-29

**Status**: Draft

**Input**: User description: "Camada de arco narrativo no conteúdo das trilhas do Academy. Aprofundar o conteúdo e prender o kid do início ao fim de uma trilha, fazendo-o querer a próxima — sem perder a simplicidade do formato pílula (enigma→pistas→revelação→teste→fisgada) e sem mudar schema (só payload + seeds + views)."

## Contexto

Feature **incremental** sobre o redesign já entregue (`specs/001-academy-redesign/`, shipado). O motor de trilhas/aulas (status locked/available/completed, conclusão idempotente, reveal passo-a-passo client-side, Guia opcional) está pronto e **não muda**. Esta feature é sobre **qualidade e estrutura do CONTEÚDO** das trilhas: transformar uma sequência de aulas independentes numa **história-mistério com arco**, que prende o kid até o fim e o empurra para a próxima trilha.

## Decisões de produto (travadas com o usuário, clarify 2026-05-29)

1. **Profundidade = arco narrativo por trilha** — cada trilha tem um fio condutor recorrente; a última aula fecha o ciclo.
2. **Engajamento = cliffhanger cruzado** — a fisgada da última aula aponta nominalmente para o mistério da próxima trilha.
3. **Faixa etária = banda única ~7–10** — um único nível de texto e profundidade.
4. **Escopo técnico = só conteúdo** — sem tabela/coluna nova; tudo via `payload` jsonb de `Academy::Lesson`, `db/seeds/academy.rb` e views/parciais. Preserva ≤6 tabelas `academy_*`.

## Clarifications

### Session 2026-05-29

- Q: Como o "anti-clichê" (FR-005) deve ser garantido? → A: Lint de frases proibidas no seed (lista negra de termos/padrões checada na validação de seed + spec; barra o óbvio e pega regressões).
- Q: O refrão (FR-002) precisa ser verificável automaticamente? → A: Frase-âncora declarada por trilha — cada trilha declara seu refrão (string curta) e a validação confere que aparece em todas as aulas.
- Q: O cliffhanger de saída (FR-004) aponta sempre pra próxima por ordem, ou destino curado? → A: Destino curado por trilha — cada trilha declara qual trilha-destino sua fisgada provoca (não necessariamente a seguinte por position); validação confere existência + ativo.
- Q: Quantas trilhas no conjunto final? → A: 5 trilhas — 3 existentes revisadas + 2 novas (luz, linguagem).

**Nota de schema**: o refrão declarado e a trilha-destino do cliffhanger vivem como **metadado de origem no seed** (`db/seeds/academy.rb`, consumido pela validação de build) — **não** como colunas novas. FR-007 (zero schema) permanece intacto.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Terminar uma trilha e sentir o "fechamento" (Priority: P1)

A criança percorre uma trilha do começo ao fim. Ao longo das aulas percebe uma frase/ideia que se repete e cresce (o fio condutor). Na última aula, o enigma que abriu a trilha é **reaberto e respondido** — ela sente que a jornada "fechou", que valeu a pena, e fica com a sensação de ter desvendado um mistério maior do que cada aula isolada.

**Why this priority**: É o coração desta feature. Sem o pagamento de arco, a trilha continua sendo uma lista de fatos soltos. O fechamento é o que gera satisfação e retenção até o fim.

**Independent Test**: Logar como kid → completar todas as aulas de uma trilha → na última aula, verificar que o enigma de abertura da trilha reaparece e é resolvido, e que o fio condutor (refrão) está presente.

**Acceptance Scenarios**:

1. **Given** uma trilha com gancho de abertura (enigma do arco), **When** a criança chega à última aula, **Then** o conteúdo dessa aula reabre explicitamente o enigma de abertura e o resolve.
2. **Given** uma trilha em curso, **When** a criança lê as revelações de cada aula, **Then** uma frase-âncora (refrão) reaparece e escala em cada aula da trilha.
3. **Given** a última aula de uma trilha, **When** a criança lê suas pistas, **Then** ao menos uma pista retoma um elemento já apresentado na aula 1 (callback).

---

### User Story 2 - Querer a próxima trilha (cliffhanger cruzado) (Priority: P1)

Ao concluir a última aula de uma trilha, a fisgada não diz só "nova trilha": ela **nomeia e provoca** o mistério da trilha seguinte, criando vontade de continuar — como o gancho de fim de episódio de uma série.

**Why this priority**: É o mecanismo de retenção entre trilhas, o objetivo explícito da feature ("querendo partir pra outra por ter gostado muito").

**Independent Test**: Concluir a última aula de uma trilha → verificar que a fisgada cita nominalmente o tema/enigma de outra trilha existente e a torna desejável.

**Acceptance Scenarios**:

1. **Given** uma trilha que não é a última do conjunto, **When** a criança vê a fisgada da sua última aula, **Then** a fisgada nomeia o mistério da próxima trilha (não um texto genérico tipo "nova trilha").
2. **Given** a última trilha do conjunto, **When** a criança vê a fisgada final, **Then** ela recebe um gancho aberto/misterioso (sem trilha-destino), sem quebrar a expectativa.
3. **Given** a fisgada de fim de trilha, **When** a próxima trilha citada existe e está ativa, **Then** o nome/tema citado corresponde a uma trilha real seedada.

---

### User Story 3 - Trilhas-exemplo novas demonstrando os padrões (Priority: P2)

São produzidas novas trilhas que exemplificam plenamente os cinco padrões de arco (ex.: "A luz é uma notícia velha" — astronomia/luz; "As palavras mudam o que você enxerga" — linguagem/percepção), ampliando o catálogo sem quebrar as 3 trilhas atuais.

**Why this priority**: Demonstra os padrões na prática e amplia o conteúdo navegável, mas o valor de retenção (US1/US2) já é entregue ao aplicar os padrões às trilhas existentes.

**Independent Test**: Após o seed, abrir `/kid/academy` → ver as trilhas novas listadas → percorrê-las ponta a ponta e confirmar os cinco padrões.

**Acceptance Scenarios**:

1. **Given** o seed atualizado, **When** a home do Academy carrega, **Then** as trilhas novas aparecem com gancho de arco e progresso 0/y.
2. **Given** uma trilha-exemplo nova, **When** percorrida do início ao fim, **Then** ela satisfaz os cinco padrões de arco (FR-001..FR-005).

---

### User Story 4 - Trilhas existentes atualizadas ao novo padrão (Priority: P2)

As 3 trilhas já seedadas (cérebro, corpo, forças invisíveis) são revisadas para também respeitar os cinco padrões — em especial pagamento de arco e cliffhanger cruzado nominal — sem perder o conteúdo válido que já têm.

**Why this priority**: Consistência: o kid não deve sentir trilhas "de duas qualidades". Mas é P2 porque o motor já funciona e as trilhas atuais já encadeiam parcialmente.

**Independent Test**: Percorrer cada trilha existente ponta a ponta e confirmar os cinco padrões.

**Acceptance Scenarios**:

1. **Given** uma trilha existente, **When** percorrida até a última aula, **Then** o enigma de abertura é reaberto/resolvido e a fisgada final nomeia outra trilha real.
2. **Given** a revisão das trilhas existentes, **When** o conteúdo é comparado ao anterior, **Then** os fatos/checks já corretos são preservados (não há regressão de qualidade).

---

### Edge Cases

- **Trilha com 1 aula só**: a única aula deve, ela mesma, abrir e fechar o arco; o callback "da aula 1" é trivial. O conjunto-alvo não usa trilhas de 1 aula, mas a validação não deve quebrar nesse caso.
- **Trilha-destino do cliffhanger removida/inativa**: a fisgada não pode apontar para uma trilha inexistente. Validação de seed deve falhar cedo se um cliffhanger nomear destino inválido.
- **Última trilha do conjunto**: não há próxima; a fisgada final usa um gancho aberto, não um destino nomeado.
- **Conteúdo malformado**: como hoje, a aula não pode renderizar erro; o seed valida estrutura e referências de arco no build (falha cedo).
- **Revisita em modo leitura**: ver a última aula de novo não deve reprocessar progresso; o fechamento do arco é só conteúdo, sem efeito colateral.

## Requirements *(mandatory)*

### Functional Requirements

Os cinco padrões de arco viram requisitos curatoriais **verificáveis** sobre o conteúdo seedado:

- **FR-001 (Pagamento de arco)**: A última aula de toda trilha (com 2+ aulas) MUST reabrir o enigma de abertura da trilha e resolvê-lo de forma explícita, fechando o ciclo.
- **FR-002 (Fio/refrão recorrente)**: Cada trilha MUST **declarar** uma frase-âncora (refrão) como metadado de origem no seed; o refrão MUST aparecer em todas as aulas da trilha (ex.: na revelação) e escalar de sentido/escopo ao longo dela. A validação de seed confere a presença do refrão em cada aula.
- **FR-003 (Callback explícito)**: A última aula de toda trilha (com 2+ aulas) MUST retomar, em uma pista ou na revelação, um elemento concreto já apresentado na aula 1.
- **FR-004 (Cliffhanger cruzado nominal)**: Cada trilha (exceto a última do conjunto) MUST **declarar** uma trilha-destino (metadado de origem no seed) e a fisgada (`hook`) da sua última aula MUST nomear o mistério/tema dessa trilha-destino, tornando-a desejável. O destino é **curado** (não precisa ser a próxima por `position`). A validação de seed confere que o destino existe e está ativo. Para a última trilha do conjunto, não há destino declarado e a fisgada MUST ser um gancho aberto.
- **FR-005 (Anti-clichê reforçado)**: Todo conteúdo MUST evitar moral da história, frases motivacionais batidas, "reflita sobre", tom de palestra; o tom MUST ser mistério + fascínio, com fenômenos reais explicados como uma criança contaria a um amigo. Uma **lista negra de frases/padrões proibidos** MUST ser checada na validação de seed (e coberta por spec), falhando o build se algum termo proibido aparecer no conteúdo.
- **FR-006**: O formato da pílula MUST permanecer **enigma → pistas → revelação → teste → fisgada** (o `payload` mantém `clues[]`, `revelation`, `check{}`, `hook`); nenhum passo novo é adicionado.
- **FR-007**: A feature MUST NOT alterar o schema: nenhuma tabela ou coluna nova em `academy_*`; toda a expressão de arco vive no `payload` jsonb da aula, no campo `hook` do arco da trilha, e em views/parciais de apresentação.
- **FR-008**: O conteúdo MUST mirar **banda única ~7–10 anos** — um único nível de texto e profundidade, sem variação por idade.
- **FR-009**: O sistema MUST manter as 3 trilhas existentes funcionando após a revisão (sem regressão do fluxo home → trilha → aula → conclusão → próxima).
- **FR-010**: O seed MUST validar as regras de arco no build e falhar cedo se violadas, em vez de produzir conteúdo inconsistente em runtime. A validação cobre, no mínimo: (a) trilha-destino do cliffhanger existe e está ativa; (b) refrão declarado aparece em todas as aulas; (c) última aula contém callback à aula 1; (d) nenhuma frase da lista negra anti-clichê aparece no conteúdo.
- **FR-011**: Conteúdo formativo PODE incluir versículos bíblicos (ex.: Provérbios) ao lado de filósofos/ciência, sempre apresentados como **descoberta/achado** (quem disse isso e quando), nunca como moralização.
- **FR-012**: O conjunto entregue MUST conter exatamente **5 trilhas**: as 3 existentes (cérebro, corpo, forças invisíveis) atualizadas + **2 trilhas-exemplo novas** ("A luz é uma notícia velha" e "As palavras mudam o que você enxerga"), todas satisfazendo FR-001..FR-005.
- **FR-013**: O design e a renderização MUST seguir o sistema vigente (DESIGN.md / redesign 001); qualquer nova parcial de apresentação de arco reusa `Ui::*` e tokens existentes, honrando `prefers-reduced-motion`.

### Key Entities *(payload — sem schema novo)*

- **Trail (Trilha)**: já existe. Esta feature usa de forma disciplinada: `hook` = enigma de abertura do arco; `position`/`active` definem o conjunto. Dois **metadados de origem** acompanham cada trilha **no seed** (não no DB): o **refrão** declarado e a **trilha-destino** do cliffhanger (slug), ambos consumidos só pela validação de build.
- **Lesson.payload (jsonb)**: já existe. Convenções de arco adicionadas ao conteúdo (não ao schema):
  - `revelation` carrega/varia o **refrão** da trilha (FR-002).
  - `clues[]` da última aula contém ao menos um **callback** à aula 1 (FR-003).
  - `revelation`/`clues[]` da última aula **reabrem e resolvem** o enigma de abertura (FR-001).
  - `hook` da última aula nomeia o **destino** do cliffhanger cruzado (FR-004) — referência conceitual a outra trilha pelo seu tema, validada no seed.
- **Arco da trilha (conceito, não persistido)**: enigma de abertura (= `hook` da trilha) + refrão + pagamento na última aula + cliffhanger de saída. Expresso inteiramente pela composição dos campos acima.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em **100%** das trilhas com 2+ aulas, a última aula reabre e resolve o enigma de abertura (FR-001), verificável por inspeção/validação de seed.
- **SC-002**: Em **100%** das trilhas, existe um refrão presente em **todas** as aulas da trilha (FR-002).
- **SC-003**: Em **100%** das trilhas com 2+ aulas, a última aula contém um callback verificável à aula 1 (FR-003).
- **SC-004**: Em **100%** das trilhas que não são a última do conjunto, a fisgada final nomeia uma trilha-destino **existente e ativa** (FR-004); 0 referências quebradas.
- **SC-005**: O conjunto final tem **5 trilhas** (3 existentes revisadas + 2 novas), cada uma com **≥ 4 aulas**, todas satisfazendo os cinco padrões.
- **SC-006**: A criança ainda completa uma aula em **≤ 3 minutos** (o arco não alonga a pílula individual) e percorre uma trilha inteira sem encontrar conteúdo clichê (avaliação qualitativa contra a checklist anti-clichê de FR-005).
- **SC-007**: A suíte RSpec do módulo continua **100% verde** e o seed roda sem erro; **zero** mudanças de schema (nenhuma migration nova).

## Assumptions

- O motor do Academy (serviços `Lessons::Available`/`Lessons::Complete`, controller, reveal client-side, Guia) já está implementado e estável — esta feature não o altera.
- A faixa etária única (~7–10) é suficiente; não há demanda de adaptação por idade nesta iteração.
- O conteúdo legado não precisa ser preservado byte a byte: as 3 trilhas existentes podem ser reescritas desde que preservem os fatos/checks corretos e ganhem a estrutura de arco.
- "Anti-clichê" é avaliado contra uma lista de proibições explícita (sem moral, sem motivacional, sem "reflita sobre", sem tom de palestra) — critério checável por revisão.
- O cliffhanger cruzado tem **destino curado**: cada trilha declara no seed o slug da trilha-destino e a fisgada nomeia seu tema/enigma; a validação de build garante que o destino existe e está ativo (sem introduzir FK ou coluna de ligação).
- Visual e componentes seguem DESIGN.md; nenhuma nova dependência de UI é necessária.

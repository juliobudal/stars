# Feature Specification: Academy Redesign — Pílulas de Conhecimento

**Feature Branch**: `001-academy-redesign`

**Created**: 2026-05-28

**Status**: Draft

**Input**: Refatorar/reescrever o módulo Academy. Está complexo demais (25 tabelas, ~12.7k LOC). Objetivo: a criança aprende assuntos de forma rápida e interessante. Diariamente (ou mais) ela consome uma "pílula de conhecimento" — uma aula curta numa trilha. Método de ensino pelo mistério e interesse lúdico, inteligente e eficiente, sem clichês. Simplicidade acima de tudo.

## Decisões de produto (ancoradas com o usuário)

1. **Guia LLM mantido** — chat ao vivo "O Guia" disponível dentro de cada aula (persona autoritária + misteriosa + fascinada). Mas infra LLM enxuta: só `Client` + `Ask` + prompt + storage de conversa. Sem `Readability`, `PredictReaction`, `Voices`, etc.
2. **Só progresso de trilha** — sem streak, coleção, pokédex, conceitos/grafo, skills, ranks, segredos, wagers, signals, lightning rounds, recall, digests parentais. Apenas: avançar aula a aula numa trilha.
3. **Conteúdo novo, do zero** — descartar os ~180 payloads e missões antigas. Escrever poucas trilhas fortes, autênticas, anti-clichê, no método do mistério.
4. **Formato da pílula** definido aqui: **Enigma → Pistas → Revelação → Teste → Fisgada** (ver FR-010).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consumir a pílula do dia (Priority: P1)

A criança abre o Academy e imediatamente vê a próxima aula disponível na trilha que está cursando (ou escolhe uma trilha). Ela toca em "Começar", passa pelo enigma e pistas, recebe a revelação, responde um teste rápido e vê a fisgada para a próxima aula. A aula é marcada como concluída e a próxima é desbloqueada.

**Why this priority**: É o coração do produto. Sem isso não há Academy. Entrega valor sozinho: a criança aprende algo interessante em ~3 minutos.

**Independent Test**: Logar como kid → abrir `/kid/academy` → entrar numa trilha → completar a aula disponível → verificar que ela vira "concluída" e a seguinte fica disponível.

**Acceptance Scenarios**:

1. **Given** uma trilha com 5 aulas e nenhuma concluída, **When** a criança abre a trilha, **Then** só a aula 1 está disponível e as 2–5 aparecem bloqueadas.
2. **Given** a criança na aula 1, **When** ela percorre enigma → pistas → revelação → responde o teste → vê a fisgada e toca "Concluir", **Then** a aula 1 fica concluída e a aula 2 desbloqueia.
3. **Given** uma aula concluída, **When** a criança volta nela, **Then** ela pode revê-la (modo leitura) sem alterar progresso.

---

### User Story 2 - Escolher entre trilhas (Priority: P1)

A home do Academy mostra as trilhas disponíveis como cards (com gancho/enigma do arco). A criança escolhe qual trilha explorar. Cada trilha mostra seu progresso (ex.: 2/5).

**Why this priority**: A navegação mínima para chegar à pílula. Sem ela, a US1 não tem entrada.

**Independent Test**: Abrir `/kid/academy` → ver N cards de trilha com progresso → tocar num → cair na lista de aulas da trilha.

**Acceptance Scenarios**:

1. **Given** trilhas ativas seedadas, **When** a criança abre a home, **Then** vê um card por trilha com título, gancho e progresso (x/y).
2. **Given** uma trilha sem nenhuma aula concluída, **When** exibida na home, **Then** mostra "0/y" e um CTA "Começar".

---

### User Story 3 - Perguntar ao Guia (Priority: P2)

Dentro de uma aula, a criança pode abrir "O Guia" (🦉) e fazer uma pergunta livre sobre o assunto. O Guia responde no tom misterioso/fascinado. Limite de 5 perguntas/dia por criança. Sem `OPENROUTER_API_KEY`, o botão fica escondido e a aula funciona normalmente.

**Why this priority**: Camada de "magia" e aprofundamento, mas a aula é completa sem ela (conteúdo é 100% curado). Por isso P2.

**Independent Test**: Numa aula, abrir o Guia → enviar pergunta → receber resposta. Com a env ausente, confirmar que o botão some.

**Acceptance Scenarios**:

1. **Given** `OPENROUTER_API_KEY` presente, **When** a criança abre o Guia e pergunta, **Then** recebe uma resposta em pt-BR no tom da persona.
2. **Given** a criança já fez 5 perguntas hoje, **When** tenta a 6ª, **Then** o sistema recusa educadamente e mostra que o limite volta amanhã.
3. **Given** env ausente, **When** a aula carrega, **Then** o botão 🦉 não aparece e a aula funciona.

---

### User Story 4 - Pai acompanha o progresso (Priority: P3)

Um pai/mãe vê um resumo simples (read-only) de quais trilhas a criança está cursando e quantas aulas concluiu.

**Why this priority**: Valor de visibilidade parental, mas não bloqueia o loop da criança. Mínimo viável.

**Independent Test**: Logar como parent → abrir `/parent/academy` → ver lista de trilhas com "x/y concluídas" por filho.

**Acceptance Scenarios**:

1. **Given** uma criança com 3 aulas concluídas, **When** o pai abre o dashboard, **Then** vê o total por trilha.

---

### Edge Cases

- Trilha 100% concluída: mostra estado "Trilha completa" e nenhuma aula bloqueada; não há "próxima".
- Criança nova (zero progresso): toda trilha começa com a aula 1 disponível.
- Aula sem teste (check) definido: o passo de teste é pulado, sem quebrar o fluxo.
- Conteúdo de aula malformado no seed: a aula não deve renderizar erro 500; valida no seed (build falha cedo).
- Recarregar no meio da aula: o estado de "passo atual" é client-side; ao recarregar, volta ao início da aula (sem perda de progresso de trilha, pois só "concluir" persiste).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST organizar o conteúdo em **Trilhas** (ordenadas, com título e gancho) contendo **Aulas/Pílulas** ordenadas.
- **FR-002**: O sistema MUST desbloquear as aulas sequencialmente: a aula N só fica disponível quando a N-1 foi concluída. A aula 1 está sempre disponível.
- **FR-003**: A criança MUST poder concluir uma aula, persistindo `completed_at` por (learner, lesson). Concluir é idempotente.
- **FR-004**: A criança MUST poder revisitar aulas concluídas em modo leitura, sem alterar progresso.
- **FR-005**: A home `/kid/academy` MUST listar trilhas ativas com progresso (x/y) e destacar a próxima aula a fazer.
- **FR-006**: O sistema MUST NOT exibir nem depender de: pokédex/conceitos, skills, ranks, segredos, wagers, signals, lightning rounds, recall, coleção de cartas, digests. Esses subsistemas são removidos.
- **FR-007**: O Guia (LLM) MUST estar disponível dentro de uma aula via botão, respondendo perguntas livres no tom da persona; limite de 5 perguntas/dia por criança.
- **FR-008**: Sem `OPENROUTER_API_KEY`, o sistema MUST esconder o botão do Guia e manter a aula 100% funcional (conteúdo é curado, não depende de LLM em runtime).
- **FR-009**: Todo conteúdo de aula MUST ser curado/estático (seedado), sem geração por LLM em runtime fora do chat do Guia.
- **FR-010**: Cada aula MUST seguir o formato **Enigma → Pistas → Revelação → Teste → Fisgada**:
  - **Enigma**: pergunta-âncora intrigante (1 frase) que a criança não sabe responder de cara.
  - **Pistas**: 2–4 micro-fatos surpreendentes, revelados um a um (tap), construindo curiosidade.
  - **Revelação**: o insight central — frase própria que "fica na cabeça" (formato "se X, então Y" ou afim).
  - **Teste**: 1 checagem rápida (múltipla escolha OU predição), com feedback imediato. Opcional por aula.
  - **Fisgada**: gancho curto para a próxima aula da trilha (ou gancho misterioso se for a última).
- **FR-011**: O conteúdo MUST ser anti-clichê: sem frases motivacionais batidas, sem moralização, sem "reflita sobre", sem tom de palestra TED infantil. Tom: mistério + fascínio + curiosidade inteligente.
- **FR-012**: O pai MUST poder ver (read-only) o progresso da criança por trilha em `/parent/academy`.
- **FR-013**: O sistema MUST manter o contrato de isolamento do módulo: zero FK das tabelas `academy_*` para tabelas host (`profiles`, `families`); `learner_id` é bigint sem FK; boundary via `Academy::Learner` value object.
- **FR-014**: O design MUST seguir o sistema Duolingo do projeto (DESIGN.md): verde #58CC02, Nunito, sombras 3D `0 4px 0`, `prefers-reduced-motion` honrado.
- **FR-015**: A remoção do código legado MUST limpar models, services, controllers, views, specs, seeds e tabelas `academy_*` que não fazem parte do novo desenho (drop migrations).

### Key Entities

- **Trail (Trilha)**: tema ordenado. Atributos: slug, title, hook (gancho do arco), accent/emoji, position, active.
- **Lesson (Aula/Pílula)**: unidade de conteúdo numa trilha. Atributos: trail_id, slug, position, enigma (título-pergunta), payload (JSON estruturado: clues[], revelation, check{kind, prompt, options[], answer, explanation}, hook), active.
- **LessonProgress**: conclusão por aprendiz. Atributos: learner_id (no-FK), lesson_id, completed_at, check_choice, check_correct. Único por (learner, lesson).
- **GuideConversation / GuideMessage**: thread (learner × lesson) com o Guia + turnos. Mantido enxuto.
- **Learner**: value object de boundary (id, display_name, age_band). Sem persistência.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A criança completa uma aula (enigma → fisgada) em **≤ 3 minutos**.
- **SC-002**: O módulo Academy reescrito tem **≤ 6 tabelas** `academy_*` (de 25) e **≤ ~2.500 LOC** de produção (de ~8.7k).
- **SC-003**: A home → trilha → aula → conclusão → próxima funciona end-to-end, validado por **smoke E2E Playwright**.
- **SC-004**: Suite RSpec do novo módulo passa 100%; a suite geral do projeto continua verde após a remoção do legado.
- **SC-005**: Existem **≥ 3 trilhas** com **≥ 4 aulas** cada, conteúdo original e anti-clichê, seedadas e navegáveis.
- **SC-006**: A aula carrega e é 100% jogável **sem** `OPENROUTER_API_KEY` (Guia opcional).

## Assumptions

- A camada de áreas/subjects (7 áreas de formação humana) é **descartada** em favor de trilhas no topo — menos navegação, mais foco.
- O conteúdo legado (missões/lens/conceitos) **não** é migrado; progresso histórico do Academy v2/v4 é descartado (produto pré-lançamento, sem usuários reais a preservar).
- O Guia usa a infra OpenRouter/DeepSeek existente (`OPENROUTER_API_KEY`), reaproveitando `Academy::Llm::Client`.
- Autenticação/sessão (FamilySession → ProfileSession, `session[:profile_id]`) e o boundary `Learner.from_profile` continuam como hoje.
- Visual segue DESIGN.md (Duolingo). Reuso de `Ui::*` ViewComponents sempre que possível.

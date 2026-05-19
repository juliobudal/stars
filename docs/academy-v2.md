# Academy v2 — Plataforma de Formação Humana

> Documento de design da v2 da Academy.
> Status: aprovado 2026-05-16. Em implementação inicial.
> Lê junto com `docs/academy.md` (v1 — contrato de isolamento, infra LLM, persona, quality check). A v2 **estende** a v1; não reescreve do zero.

---

## 1. A virada de tese

A v1 destila autores ("uma sacada de Carnegie por pílula"). A v2 sobe o nível: **forma capacidades práticas para a vida, escondendo currículo dentro de curiosidade.**

A criança vê: "Por que açúcar engana seu cérebro?". O sistema sabe: neurobiologia básica + autocontrole + leitura de rótulo.

| | v1 (hoje) | v2 (proposta) |
|---|---|---|
| Tese | "pílulas destiladas de autores" | "capacidades para a vida, com currículo invisível por trás" |
| Unidade | sacada de 1 autor → 2 sessões | 1 pergunta poderosa → 1 insight central → 1 comportamento mudado |
| Currículo visível | área autoral (Inteligência/Caráter…) | área de formação humana (Mente Forte / Corpo & Saúde…) |
| Currículo invisível | inexistente | conceitos + skills rastreados em grafo |
| Sucesso = | acertou os checkpoints | comportamento mudou + skill subiu |
| Recompensa | medalha + pontos | medalha + carta de descoberta + rank epistêmico + segredo desbloqueado |

---

## 2. Princípios não-negociáveis

1. **Esconder currículo dentro da curiosidade.** A criança escolhe explorar um mundo; o sistema sabe o que ela está aprendendo de verdade.
2. **Toda aula precisa mudar algum comportamento.** Mesmo que minimamente. Sem mudança → aula falhou.
3. **Conhecimento como grafo, não árvore.** Conceitos atravessam áreas (`hábito` aparece em Mente Forte, Corpo & Saúde *e* Dinheiro).
4. **Progresso pessoal, não escolar.** Aprendiz → Mentor. Nada de série/ano.
5. **Inteligência prática.** Cada pílula entrega um "caraca" + um "vou fazer isso hoje".

---

## 3. As 7 áreas de formação humana

Currículo **visível** ao kid. Substitui as 6 áreas autorais; abaixo o mapeamento explícito.

| Slug | Nome (kid) | Ensinamento central | Tópicos | Áreas v1 que absorve |
|---|---|---|---|---|
| `mente-forte` | 🧠 Mente Forte | Dominar a própria mente | foco · memória · autocontrole · ansiedade · hábitos · disciplina · coragem · procrastinação · pensamento crítico · ilusões cognitivas | `inteligencia` |
| `corpo-saude` | 💪 Corpo & Saúde | Cuidar do corpo como ferramenta poderosa | sono · alimentação real · ultraprocessados · açúcar · exercício · respiração · postura · energia · vícios digitais · hormônios básicos | `saude` |
| `dinheiro-vida` | 💰 Dinheiro & Vida Real | Inteligência financeira e responsabilidade | valor · troca · trabalho · impulso vs. planejamento · juros · investir · negociar · paciência · "querer ≠ precisar" | `dinheiro` |
| `carater` | 🤝 Caráter & Virtudes | Formar caráter forte | honestidade · responsabilidade · respeito · coragem · empatia · humildade · gratidão · perseverança · palavra · liderança | `carater` + `fe-sentido` (folder dentro como trilha) |
| `tecnologia-criacao` | 💻 Tecnologia & Criação | Deixar de só consumir — virar criador | lógica · programação básica · IA · internet · segurança digital · automação · pensamento computacional | NOVA |
| `resolver-problemas` | 🛠️ Resolver Problemas | Autonomia intelectual | estratégia · decomposição · decisão sob incerteza · criatividade · observação · "errar como dado" | NOVA (puxa parte de `inteligencia`) |
| `vida-sociedade` | 🌎 Vida & Sociedade | Entender pessoas e o mundo | comunicação · amizade · família · influência · mídia · manipulação · cooperação · cultura · multidão | `relacionamentos` (expandido) |

> As 6 áreas v1 viram `active: false` na seed. Progresso histórico e medalhas v1 ficam preservados — apenas saem do index do kid.

---

## 4. Arquitetura de 5 níveis

```
ÁREA DE FORMAÇÃO  (7, visível)         ← academy_subjects
  └── TRILHA       (4-8 por área)      ← academy_trails           [NOVO]
        └── AULA   (4-8 por trilha)    ← academy_missions (renomeada "aula" no domínio)
              ├── CONCEITOS  (1-3)     ← academy_aula_concepts    [Fase 2]
              └── SKILLS     (1-2)     ← academy_aula_skills      [Fase 7]

CONCEITOS         (~80, invisível)     ← academy_concepts         [Fase 2]
  └── conexões (grafo)                 ← academy_concept_edges    [Fase 2]

SKILLS            (9, semi-visível)    ← academy_skills           [Fase 7]
  └── pontuação por learner            ← academy_learner_skills   [Fase 7]
```

### Trilha (camada nova entre área e aula)

Mini-jornada narrativa de 4-8 aulas com arco. Tem `title`, `arc_hook` (gancho do arco inteiro), `position`. Substitui a numeração-sequencial-de-10 que hoje vive direto no Subject.

Exemplos em **Mente Forte**:
- "Quem manda na sua atenção?" — 4 aulas: dopamina, notificação, foco, deep work pra criança
- "Hábitos sem sofrer" — 5 aulas: gatilho, recompensa, ambiente, 1% por dia, hábito-quebra
- "Seu cérebro mente pra você" — 4 aulas: viés de confirmação, memória falsa, ilusões, pensamento devagar

### Conceito (invisível, transversal — fase 2)

Lista fechada (~80), com `slug`, `name`, `definition`, `category` (cognitivo / científico / social / financeiro / saúde / virtude). Cada aula declara 1-3.

Exemplos: `causa-e-efeito`, `dopamina`, `habito-loop`, `juros-compostos`, `vies-confirmacao`, `homeostase`, `prova-social`, `decomposicao`, `feedback-loop`, `tradeoff`, `escassez`, `delayed-gratification`.

Uso:
- Alimenta a seção "Isso se conecta com…" ao fim da aula
- Parent dashboard mostra "conceitos atravessados"
- LLM-judge audita cobertura conceitual

### Skill (semi-visível, rastreada — fase 7)

9 skills cognitivo-caracteriais. Cada aula declara 1-2 primárias. Cada checkpoint correto + cada mini-desafio cumprido pontua.

| Skill | O que sinaliza |
|---|---|
| `disciplina` | Manteve micro-compromisso assumido |
| `curiosidade` | Abriu pílula sugerida fora da trilha em andamento |
| `autonomia` | `explain_back` aprovado (síntese própria) |
| `foco` | Concluiu sessão sem abandonar / sem responder rápido errado |
| `saude` | Acertos + desafios em Corpo & Saúde |
| `comunicacao` | Idem em Vida & Sociedade + `explain_back` |
| `logica` | Acertos em Resolver Problemas + Tecnologia & Criação |
| `responsabilidade` | Reportou honestamente desafios (sim *e* não) |
| `criatividade` | Respostas livres com originalidade detectada pelo judge |

Kid vê isso como radar simplificado. Parent vê o radar completo.

---

## 5. Framework de Aula v2 (6 beats refinados)

Mantém a espinha v1, ajusta 3 beats:

| # | Beat v1 | Beat v2 | Mudança |
|---|---|---|---|
| 1 | GANCHO | **PERGUNTA PODEROSA** | Gancho vira pergunta-âncora que define a aula inteira |
| 2 | PONTE | **CURIOSIDADE RÁPIDA + PONTE** | 2-3 mini-fatos surpreendentes ANTES da relevância pessoal |
| 3 | SACADA com fonte | **EXPLICAÇÃO SIMPLES + INSIGHT CENTRAL** | Insight é frase própria ("se você não controla X, alguém controla"); citação de fonte só quando faz sentido |
| 4 | EXEMPLO VIVO | EXEMPLO VIVO | inalterado |
| 5 | CHECKPOINT SOCRÁTICO (MCQ) | **CHECKPOINT (multi-kind)** | MCQ + ordering + predict + explain_back + complete_phrase (fase 6) |
| 6 | AMARRAR + GANCHO PRÓXIMA | **AMARRAR + APLICAÇÃO + MINI-DESAFIO + GANCHO** | Mini-desafio vira contrato comportamental |

### Insight central — o coração da aula

Frase própria que sobra na cabeça do kid uma semana depois. Formato preferido: "se X, então Y" ou "quem não X, perde Y".

A fonte (`mission.source`) continua sendo usada quando aula vem de autor, mas o insight é da aula, não citação literal.

### Mini-desafio — o sinal de comportamento

Cada aula termina pedindo compromisso pequeno e específico:
- "Coloque o celular em outro cômodo na hora de dormir hoje. Amanhã me conta o que mudou."
- "Antes da próxima compra de besteira no mercado, espere 5 minutos. Veja se ainda quer."
- "Pergunte ao seu pai/mãe: 'qual foi a coisa mais difícil que você fez essa semana?'"

No próximo abrir da Academy, antes de qualquer pílula nova, aparece honor-system:

> "Você fez o desafio de [pílula X]?"
> [Fiz] [Quase] [Não fiz]

Sem punição. Honestidade pontua `responsabilidade`. Fiz pontua `disciplina`. Parent dashboard mostra ratio reportado.

---

## 6. Progressão pessoal (6 ranks cross-area)

Substitui "Aprendiz/Adepto/Mestre" *por área* por **um rank único cross-area**:

| Rank | Como sobe |
|---|---|
| 🌱 Aprendiz | default ao começar |
| 🧭 Explorador | 5 aulas concluídas em ≥ 2 áreas diferentes |
| 🔨 Construtor | 15 aulas + 3 mini-desafios reportados como cumpridos |
| ♟️ Estrategista | 30 aulas + 1 `explain_back` aprovado + 3 áreas a 30%+ |
| 🎨 Criador | 50 aulas + 1 trilha 100% em Tecnologia & Criação OU Resolver Problemas |
| 🧙 Mentor | 100 aulas + 5 áreas a 50%+ + ratio mini-desafios > 60% |

Sobe → animação especial + desbloqueia 1 Segredo (pílula bônus). Medalhas por área continuam, mas viram secundárias.

---

## 7. Grafo de conhecimento ("Isso se conecta com…")

Ao concluir aula, no card de Descoberta aparecem 2-3 chips clicáveis: "Esta sacada conversa com…" → outras aulas que compartilham conceitos.

Cross-area é o efeito mágico:
- "Por que açúcar engana seu cérebro?" (Corpo & Saúde) ↔ "Por que apps prendem você?" (Tecnologia & Criação) via `dopamina`
- "Compras por impulso" (Dinheiro) ↔ "Por que reclamar enfraquece você?" (Caráter) via `recompensa-imediata`

---

## 8. Modelo de dados — delta vs. v1

### Tabelas novas

```ruby
academy_trails
  subject_id, slug, title, arc_hook, position, active

academy_concepts                      # fase 2
  slug, name, definition, category, position

academy_aula_concepts                 # fase 2
  mission_id, concept_id, primary

academy_concept_edges                 # fase 2
  from_concept_id, to_concept_id, kind  # echoes | depends_on | leads_to

academy_skills                        # fase 7 (9 fixas)
  slug, name, icon

academy_aula_skills                   # fase 7
  mission_id, skill_id, weight

academy_learner_skills                # fase 7
  learner_id, skill_id, score, last_event_at

academy_challenge_reports
  learner_id, mission_id, status, reported_at  # pending|done|partial|skipped

academy_discovery_cards
  learner_id, mission_id, illustration_key, headline, source, application, minted_at

academy_recall_reviews                # fase 5
  learner_id, card_id, interval_days, ease, due_at, last_reviewed_at, streak

academy_secrets                       # fase 8
  slug, unlock_rule_jsonb, mission_id, kind

academy_learner_signals               # fase 8
  learner_id, subject_id, affinity_score, accuracy_rolling, last_session_at

academy_learner_ranks                 # fase 7
  learner_id, rank, updated_at
```

### Colunas a adicionar

```
academy_missions
  + trail_id            (nullable enquanto migra)
  + central_insight     (string ≤ 200 — "se X então Y")
  + challenge_prompt    (text — frase do mini-desafio)
  + curiosity_facts     (jsonb array de 2-3 strings)
  + position_in_trail   (int)
```

### Soft deprecations

- Áreas v1 viram `active: false`. Não deletar — preserva FKs em progresses, medals, messages.
- `mission.source` / `mission.framework` / `mission.sacada` continuam opcionais — agora há aulas "puras de formação" sem autor.

---

## 9. Atualização do prompt do Guia

`Academy::Llm::GuidePersona::VOICE` recebe 3 mudanças cirúrgicas:

1. **Beat 2 expandido** — incluir 2-3 curiosidades rápidas antes da ponte. Cap: 80c cada.
2. **Beat 3 reescrito** — exigir `central_insight` ("se X, então Y"). Citação opcional.
3. **Beat 6 reescrito** — fechar com `challenge: { prompt, when, observable }` no JSON, onde `observable` é o sinal que o kid deve notar.

JSON envelope estendido:

```json
{
  "narrative": "...",
  "checkpoint": { "kind": "multiple_choice|...", ... },
  "central_insight": "...",
  "curiosity_facts": ["...", "..."],
  "challenge": { "prompt": "...", "when": "hoje|esta semana", "observable": "..." } | null,
  "card_summary": { "headline": "...", "application": "..." } | null,
  "session_complete": bool,
  "mission_complete": bool,
  "next_hook": "..."
}
```

`challenge` e `card_summary` são obrigatórios apenas na última sessão. `central_insight` é exigido a partir da sessão 2.

`QualityCheck` heurística ganha 4 checks novos: `curiosity_facts_count`, `insight_present_session_2+`, `challenge_observable`, `card_summary_required_on_last`.

---

## 10. UI — superfícies novas/refeitas

| Tela | Conteúdo |
|---|---|
| `/kid/academy` (home) | Faixa de rank + Pílula do dia + "Você fez o desafio?" (se pendente) + "Você lembra disso?" (recall due — fase 5) + Continuar trilha + Atlas (horizontal) |
| `/kid/academy/areas` | Grade das 7 áreas |
| `/kid/academy/areas/:slug` | Trilhas da área (cards estilo Netflix com hook do arco) |
| `/kid/academy/areas/:slug/trilhas/:trail_slug` | Aulas da trilha (cards com pergunta-âncora na frente) |
| `/kid/academy/aulas/:slug` | Chat (atual `missions/show`) |
| `/kid/academy/atlas` | Coleção de discovery cards + chips "conecta com…" |
| `/kid/academy/skills` | Radar simplificado (fase 7) |
| `/parent/academy` | Dashboard com radar + ratio desafios + conceitos + grafo |

---

## 11. Plano de execução em fases

Cada fase = PR isolável.

### Fase 0 — Migração de áreas — **Entregue 2026-05-16**
- Seed das 7 áreas novas
- Mapeamento 1:1; áreas v1 viram `active: false`

### Fase 1 — Trilhas — **Entregue 2026-05-16**
- Tabela `academy_trails`
- Coluna `mission.trail_id`
- View `/kid/academy/areas/:slug` mostra trilhas

### Fase 2 — Conceitos + grafo + "isso conecta com…" — **Entregue 2026-05-16**
- Tabelas conceitos + edges + aula↔conceito
- Seed inicial ~80 conceitos
- UI: chips no fim da aula

### Fase 3 — Discovery Cards + Atlas + central_insight — **Entregue 2026-05-16**
- Tabela `academy_discovery_cards` + `mission.central_insight`
- Prompt do Guia exige `card_summary` na última sessão
- `Academy::Cards::MintAfterMission` chamado em `AdvanceTurn#finalize_mission!`
- View `/kid/academy/atlas`

### Fase 4 — Mini-desafio + honor-system — **Entregue 2026-05-16**
- Colunas `mission.challenge_prompt` + `mission.curiosity_facts`
- Tabela `academy_challenge_reports`
- Prompt exige `challenge` no JSON da última sessão + 2-3 `curiosity_facts` no beat 2
- UI: card "Você fez?" prioritário na home

### Fase 5 — Spaced repetition (recall) — **Entregue 2026-05-16**
- Tabela `academy_recall_reviews`
- `Academy::Llm::RecallAgent` gera pergunta-aplicação a partir do card
- Bloco "Você lembra disso?" na home

### Fase 6 — Checkpoints multi-kind — **Parcial (envelope/parser entregue; kinds adicionais pendentes)**
- ✅ `checkpoint.kind` reconhecido em `Academy::Llm::Parser`
- ✅ `complete_phrase` (UI igual ao MCQ — sem JS novo)
- ⏳ `ordering`, `predict`, `explain_back` (ver `docs/academy-v2-pending.md` §3)

### Fase 7 — Skills + Rank — **Entregue 2026-05-16**
- Tabelas de skills + aula_skills + learner_skills + learner_ranks
- Service `Academy::Skills::Award` em `AdvanceTurn`
- UI: radar + faixa de rank

### Fase 8 — Adaptação + Segredos — **Entregue 2026-05-16**
- `academy_learner_signals` + `Academy::Adapt::NextMissionFor`
- `academy_secrets` + `Academy::Secrets::EvaluateForLearner`

---

## 12. Estado atual + lições do shipping

A v2 foi entregue end-to-end (Fases 0-8) em 2026-05-16. Smoke E2E Playwright
validado em: login → home (rank pill + pílula do dia + recall + atlas) →
área → trilha → aula (LLM com `central_insight`, `curiosity_facts`,
`challenge`, `card_summary`) → celebration → atlas → home com follow-up →
recall com `RecallAgent` → `/skills` com 9 barras. 717 specs passando.

### Lições do shipping (o que o ato de entregar ensinou)

1. **O bug do `session_complete` precoce.** Versões iniciais do prompt
   permitiam que o LLM fechasse a sessão no próprio turno de abertura, antes
   de qualquer resposta do learner. Resolvido endurecendo `GuidePersona::VOICE`
   na seção "GERENCIAMENTO DE SESSÕES E MISSÃO (HARD RULES)" — todo turno de
   abertura agora vem com `session_complete=false` explicitamente, e o flip
   só ocorre depois de mensagem do learner. Re-teste E2E pós-mudança
   pendente (ver `docs/academy-v2-pending.md` §7).
2. **LLM ignora "SOMENTE depois que".** Instruções suaves do tipo "só feche a
   sessão depois que o kid responder" foram repetidamente desobedecidas.
   Exigiu HARD RULE em maiúsculas, com exemplo positivo e negativo, antes do
   modelo passar a respeitar de forma consistente.
3. **Injeção de valores canônicos no system prompt.** Tentamos deixar o LLM
   inventar `central_insight` por turno e ele driftava entre sessões. Solução:
   quando a aula tem insight declarado (`mission.central_insight`), injetamos
   o valor verbatim no system prompt como "use este insight, palavra por
   palavra". Mesma estratégia para `challenge.prompt` e `card_summary.headline`
   na última sessão.
4. **Hooks side-effect do finalize.** `AdvanceTurn#finalize_mission!` orquestra
   5 services em ordem fixa dentro da mesma transação:
   `Cards::Mint` → `Challenges::Open` → `Skills::Award` → `Signals::Record` →
   `Secrets::Evaluate`. Ordem importa porque `Secrets::Evaluate` lê o estado
   já gravado pelos serviços anteriores. Se for adicionar um novo hook, posicione
   por dependência (lê o quê?), não por ordem de chegada.

---

## 13. O que sobrevive da v1 sem mexer

- Contrato de isolamento do módulo (zero FK para host)
- `Academy::Llm::Client` + Agent + Parser (parser ganha apenas campos novos)
- `Academy::QualityCheck` heurística (estende, não reescreve)
- Medalhas existentes (continuam, viram secundárias)
- Estrutura de chat (`missions/show.html.erb` + turbo_stream)
- Persona base (extensão, não reescrita)

---

## 14. Decisões tomadas

1. **`fe-sentido` vira trilha dentro de Caráter & Virtudes.** Provérbios/Lewis/Frankl entram como aulas dentro de trilhas de coragem, gratidão, perseverança. Áreas v1 ficam soft-retired.
2. **MVP de v2 = Fases 0+1+3+4 com Mente Forte e Corpo & Saúde como showcases.** Resto das áreas tem schema, mas conteúdo plenamente desenvolvido fica para depois.
3. **Conteúdo legado preservado.** Missões v1 continuam em DB; só param de aparecer no index do kid. Progresso histórico fica intacto.

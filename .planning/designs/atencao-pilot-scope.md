# Pilot Trilha Atenção — escopo mission × lens

> Data: 2026-05-18
> Pré-requisito: `academy-curated-static-pivot.md` (Sprint 4)
> Trilha-alvo: `mente-forte` → `atencao` (4 missões)
> Decisão: nem toda missão recebe todas as 8 lentes — só as que cabem natural.

## Critério de inclusão por lente

| Lente | Inclui se… | Exclui se… |
|---|---|---|
| 🔬 scientific (predict_reveal) | há mecanismo causal nomeável e contraintuitivo | fenômeno é puramente social/comportamental sem mecanismo |
| 📖 narrative (card_stack) | há protagonista/autor real com arco de descoberta | conceito é puramente abstrato sem caso humano forte |
| ⚖️ ethical (compare_cases) | há dilema com dois lados defensáveis e um trade-off real | "decisão" é trivial ou unilateral (ex.: ligar/desligar) |
| 📈 statistical (predict_slider) | há número observável que kid pode prever errado e ser surpreendido | não há grandeza quantificável |
| 🛠 engineering (drag_list) | kid pode projetar/desenhar um sistema simples | é só consumo passivo de informação |
| 🕰 historical (timeline) | há linha temporal de >50 anos com 3+ marcos | fenômeno é recente (smartphones, redes) sem profundidade |
| 👁 first_person (embodied_action) | há experimento físico de <30 min observável | requer equipamento, terceiros, ou tempo longo |
| 🔭 analogy_bridge (closure) | há analogia poderosa com domínio distante | analogia é forçada ou clichê |

## Escopo das 4 missões

### 1. `celular-difícil-parar` (concept: dopamina / recompensa-variavel)

| Lente | Inclui | Ângulo |
|---|---|---|
| 🔬 scientific | ✅ | Dopamina ativa em ~80ms — antes do pensamento racional acordar |
| 📖 narrative | ✅ | Tristan Harris sai do Google porque vê o que está construindo |
| ⚖️ ethical | ✅ closure | Engenheiro otimiza engajamento vs. responsabilidade pelo que cria |
| 📈 statistical | ✅ | "1000 engenheiros × 1 você = quantos pickups/dia?" |
| 🛠 engineering | ✅ | Projetar a tela inicial que reduz gatilho (apps em pasta, sem badges) |
| 🕰 historical | ❌ | Fenômeno tem 15 anos — não há timeline rica |
| 👁 first_person | ✅ | Celular em outra sala por 10 min — observar impulso |
| 🔭 analogy_bridge | ✅ closure | Caça-níquel ⇄ feed: mesmo gatilho, escala diferente |
| **Total** | **7 lentes** | |

### 2. `notificacoes-custam-23-min` (concept: switch-cost)

| Lente | Inclui | Ângulo |
|---|---|---|
| 🔬 scientific | ✅ | Cérebro recompõe contexto — atenção tem custo de boot |
| 📖 narrative | ✅ | Gloria Mark (UC Irvine) cronometrando milhares de devs |
| ⚖️ ethical | ❌ | "Ligar/desligar notificação" não é dilema moral |
| 📈 statistical | ✅ ⭐ | "23 min × 5 notificações = ? horas" — predição perfeita |
| 🛠 engineering | ✅ | Desenhar regras de notificação (whitelist mínima) |
| 🕰 historical | ❌ | Notificações são recentes |
| 👁 first_person | ✅ | 30 min modo avião + uma única tarefa |
| 🔭 analogy_bridge | ✅ closure | Cada notificação = pedágio na rodovia da atenção |
| **Total** | **6 lentes** | |

### 3. `foco-profundo-25min` (concept: deep-work)

| Lente | Inclui | Ângulo |
|---|---|---|
| 🔬 scientific | ✅ | Atenção sustentada constrói mielinização (fast-track neural) |
| 📖 narrative | ✅ | Cal Newport recusando emprego do MIT pra defender deep work |
| ⚖️ ethical | ❌ | Sem dilema forte |
| 📈 statistical | ✅ | "25 min focado vs. 2h fragmentado — qual rende mais palavras escritas?" |
| 🛠 engineering | ✅ ⭐ | Projetar o bloco de 25 min ideal (ambiente, sinal, fim) |
| 🕰 historical | ❌ | Conceito recente (2016) |
| 👁 first_person | ✅ ⭐ | Fazer 1 pomodoro AGORA com timer |
| 🔭 analogy_bridge | ✅ closure | Foco = músculo: progressão de carga, descanso, hipertrofia |
| **Total** | **6 lentes** | |

### 4. `habito-2-minutos` (concept: regra-dos-2-min)

| Lente | Inclui | Ângulo |
|---|---|---|
| 🔬 scientific | ✅ | Cérebro registra IDENTIDADE da repetição, não duração |
| 📖 narrative | ✅ | James Clear quebrando nariz no beisebol → 1% por dia → bestseller |
| ⚖️ ethical | ❌ | Sem dilema |
| 📈 statistical | ✅ | "1 página/dia × 365 dias = ? livros?" — efeito composto |
| 🛠 engineering | ✅ ⭐ | Projetar mini-versão de 1 hábito real do kid |
| 🕰 historical | ✅ | Aristóteles ("virtude é hábito") → William James → BJ Fogg → Clear |
| 👁 first_person | ✅ ⭐ | Fazer a versão 2-min HOJE de algo que vinha adiando |
| 🔭 analogy_bridge | ✅ closure | Bola de neve / juros compostos do comportamento |
| **Total** | **7 lentes** | |

## Resumo de payloads

| Missão | Lentes | Closure (ethical/analogy_bridge) |
|---|---|---|
| celular-difícil-parar | 7 | ethical + analogy_bridge |
| notificacoes-custam-23-min | 6 | analogy_bridge |
| foco-profundo-25min | 6 | analogy_bridge |
| habito-2-minutos | 7 | analogy_bridge |
| **Total** | **26 payloads** | 5 closure-eligible |

## Notas de execução

1. **Closure obrigatório por missão** — toda missão fecha em ethical OU analogy_bridge. `celular-difícil-parar` tem ambos; o `ChooseNext` decide qual entregar dependendo do signal do learner (alta-emoção → ethical; alta-curiosidade → analogy_bridge).
2. **Variantes** — sprint inicial cobre 1 payload por (mission × lens). Variantes (2-3 por slot) entram em sprint posterior se o spaced-repetition pedir.
3. **Drafting order** — começar por `celular-difícil-parar` (mais lentes, valida pipeline em todos os generators).
4. **Persistência** — payloads ficam em `db/seeds/academy_lens_payloads/{lens_type}/{mission_slug}.json`. Seeder upserta com `source: 'curated'`.

# LittleStars v3 — proposta de arquiteto pedagógico e de produto

> Data: 2026-05-16
> Documento companheiro de: `.planning/audits/academy-v2-brutal-review-2026-05-16.md`
> Postura: arquiteto pedagógico e de produto, não auditor. Redesenho, não correção.

Escrevo como arquiteto, não auditor. O que segue é um redesenho — não correção do v2. Algumas decisões aqui implicam jogar fora trabalho bom. Avisei.

---

## 1. Transformar "entendimento" em "comportamento"

### O erro conceitual atual

V2 trata comportamento como *próximo passo* depois do entendimento ("kid entendeu, agora faz"). Pedagogia comportamental real funciona ao contrário: **a ação vem com a compreensão e a sustenta**. Behavior change não é um output da aula — é o material da aula.

### Princípio: triangulação, não verificação

Você não vai verificar comportamento de criança de 9 anos no mundo real. **Aceite isso.** Mas você pode *triangular*: 3 sinais fracos vencem 1 forte. Combinação de:

1. **Self-report estruturado** (kid responde, com perguntas específicas que são difíceis de fabricar)
2. **Evidência multimodal** (foto, áudio de 15s, texto livre — kid bom em mentir é ruim em fabricar detalhes)
3. **Probe deslocado no tempo** (3-7 dias depois, mesma pergunta com outra framing)
4. **Sinal parental leve** (1 toque/semana: "vi acontecer? sim/não/talvez")
5. **Comportamento dentro do app** (latência de toque, padrão de retorno, tempo de reflexão)

Quando 3 desses 5 convergem → trate como verdade. Quando divergem → não pune, *abre uma conversa* ("vc disse X, mas seu pai não viu — me conta de novo").

### Mecanismos concretos

**1. Carta de implementação (Gollwitzer, "implementation intention")**

Kid escreve, em vez de receber, o desafio:

> "Quando eu sentir vontade de pegar o celular sem motivo, eu vou contar até 10 e ir beber água."

App armazena o `if-then`. App não verifica, mas **lembra**. Push contextual leve: "lembra do seu plano de quando bater vontade?" 1×/dia, sem barulho.

Por que funciona: estudos de Gollwitzer mostram 2-3× mais aderência vs. intenção genérica. Para criança, "se X então Y" é cognitivamente alinhado com como o cérebro deles formula causalidade.

**2. Caderno de campo (Field Journal)**

Substitui o "challenge report" honor-system. Não pergunta "fez ou não fez?". Pergunta:

- "Hoje, alguma coisa que aprendeu apareceu na sua vida? 1 frase ou 1 emoji."

Repetido por 7 dias. **O ato de logar é a prática.** Sem score, sem streak ofensivo. Kids que logam coisa criam evidência narrativa orgânica. Kids que não logam → sinal de que aulas não estão ressoando, e *isso* alimenta o motor de adaptação.

**3. Evidência como artefato**

Para certos desafios (não todos — a maioria fica em journal):
- "Tira foto do celular com 3 notificações desligadas"
- "Grava 15s explicando o que mudou"
- "Manda pro pai/mãe a sua promessa cumprida hoje, peça pra ele reagir"

A foto não precisa ser verificada por humano. Existe → triangula. Não existe → registra ausência sem punir.

**4. Probe deslocado**

7-10 dias depois, em meio a outra coisa, app pergunta:
> "Aquilo das notificações... ainda tá assim? Reativou alguma?"

Resposta honesta ("reativei 2") é **valorizada explicitamente pelo Guia**:
> "Honesto. Maioria das pessoas reativa em uma semana. Vamos pensar por quê."

Re-engaja o aprendizado em vez de penalizar.

**5. Pacto pai-filho (Compass moment, mensal)**

1×/mês, 10 minutos: pai e filho respondem 3 mesmas perguntas separadamente em telas diferentes ("nessas 4 semanas, o que você notou que mudou? o que ficou difícil? o que você quer experimentar?"). Depois revelam juntos. **Não é dashboard. É ritual.**

Estudos de Cialdini e Gottman mostram que conversa estruturada com regularidade muda comportamento mais que qualquer intervenção pontual. Esse é o vetor real de mudança no produto — o app é só a estrutura.

**6. Anti-fake design**

- Detalhes específicos pedidos (mentira ruim em detalhes).
- Variação de framing nas probes (consistência denuncia fabricação).
- Custo > zero para mentir (escrever resposta livre custa mais que clicar "fiz").
- **Honra normalizada como conquista**: "Você disse que não fez. Isso é mais raro que fazer. Vamos investigar por quê."

---

## 2. Retenção real de longo prazo

### O problema técnico

Insight em LLM-chat decai em ~3 dias se não houver re-encontro. SM-2 lite (RecallReview atual) trata como flashcard adulto — recognition de fatos. Mas o que queremos lembrar não é fato, é **modelo mental**.

### Modelo proposto: Memória em 4 camadas

**Camada 1 — Recall ativo (1-7 dias)**

Não "qual a resposta?" mas "explica com suas palavras para o Guia". LLM-as-judge avalia se kid tocou no núcleo. Se sim, sobe interval. Se não, **não falha** — re-ensina com outro exemplo.

Diferença crucial: recall *generativo*, não reconhecimento. Kid escreve 1-2 frases. Vai detestar nos primeiros 5 dias e depois ficar bom.

**Camada 2 — Callback contextual (7-30 dias)**

Quando uma aula nova toca um conceito já encontrado, o sistema **levanta o conceito anterior em vez de re-introduzir do zero**:

> "Aqui aparece de novo aquilo que vc viu no celular. Lembra? [mini-card do encontro anterior]. Agora veja como o mesmo padrão funciona com açúcar..."

Tecnicamente: `Encounter` salva `concept_ids[]`. Quando próximo encounter compartilha ≥1 concept, prompt do Guia recebe injetado: "kid já encontrou este conceito em [contexto], use isso como ponte". Reforço sem repetição. Transferência ganha aresta visível.

**Camada 3 — Reativação emocional (30-90 dias)**

A cada ~60 dias, app gera **um encontro de re-evocação** que não introduz nada novo. É uma carta:

> "Faz 2 meses que vc descobriu sobre as 1000 pessoas otimizando seu celular. Agora me conta: o que mudou? O que voltou a ser do jeito antigo? Sem julgamento."

Este encontro não dá pontos, não dá medalhas. **Tem peso emocional próprio.** Volta o kid pro próprio passado dele. Estabelece narrativa de continuidade.

**Camada 4 — Avaliação de transferência (90+ dias)**

Não é teste. É um encontro **disfarçado de aula nova** que requer modelo mental prévio para engajar. Se kid usa espontaneamente conceito X (ex: cita dopamina ao falar de açúcar), `TransferDetected` é emitido. Esse é o único KPI de aprendizado real.

### Métricas de retenção (técnicas)

| Janela | Métrica | Como medir |
|---|---|---|
| 7 dias | Explain-back accuracy | LLM-judged: kid acerta núcleo do insight em palavras próprias? |
| 30 dias | Behavioral persistence | Probe deslocado + evidência: kid ainda faz a ação? |
| 90 dias | Transfer rate | Kid usa conceito de área A em encontro de área B sem prompt? |
| 180+ dias | Self-narrative | Em reflexão livre, kid menciona conceitos antigos? |

KPI consolidado: **% de encontros que produzem transferência em 90 dias**. Hoje, valor real esperado é < 5%. Meta v3: 25%.

---

## 3. Grafo de conhecimento vivo

### Tipos de aresta necessários (substituir o "relates_to" único)

```
Concept --[generalizes]--> Concept       # dopamina → recompensa-variável
Concept --[manifests_in]--> Domain        # recompensa-variável → "redes sociais"
Concept --[conflicts_with]--> NaiveModel  # "açúcar dá energia" ↔ glicose-pico
Concept --[requires]--> Concept           # juros-compostos requires exponencial
Concept --[composes_with]--> Concept      # atenção + hábito → identidade
Concept --[predicts]--> Behavior          # dopamina prediz scrolling-infinito
```

Isso permite o sistema *raciocinar sobre o grafo*, não só decorar.

### Mecânicas pedagógicas sobre o grafo

**1. "Onde mais isso aparece?" — final de cada encontro**

LLM, com acesso ao grafo, oferece 2-3 outros lugares onde o conceito reaparece. Kid escolhe (ou ignora). Cria *itinerário emergente* em vez de currículo fixo.

**2. Meta-encontros de padrão (1×/mês)**

Encontro que dá 3-4 situações de áreas diferentes e pergunta: "qual o padrão comum?".

Exemplo concreto:
- Situação A: "TikTok te prende"
- Situação B: "Sorvete depois do almoço"
- Situação C: "Caixinha de surpresa de Lego"

Resposta cobiçada: "Recompensa variável + dopamina rápida". Se kid chega lá, **`TransferDetected` × 3** — o sinal mais valioso do sistema.

**3. Construa sua teoria (trimestral)**

A cada 3 meses, kid arrasta 5 cards do Atlas para um quadro e escreve 2 frases conectando-os. Vira artefato pessoal. Pais recebem.

> "Eu acho que escolas, jogos e redes sociais funcionam parecido. Todos usam recompensa que vc não sabe quando vem."

Esse é o produto. Não a aula, não o card — **a teoria que o kid construiu sozinho**.

### UX do Atlas

Não scroll grid. **Mapa 2D com gravidade visual:**
- Conceitos recém-vistos brilham levemente.
- Conceitos esquecidos perdem cor.
- Arestas grossas onde kid já fez transferência; finas onde só semântico.
- Zoom out → ver áreas; zoom in → ver conceitos individuais.
- Tap em conceito → ver TODAS as vezes que apareceu (memória autobiográfica).

Inspiração: **Tinderbox**, mapa de Witcher 3, Roam Research. Não scroll de Instagram.

### Algoritmo de aparição

Quando escolher próximo encontro: priorizar conceitos que:
1. Estão a 1 aresta de conceitos já vistos (zona de desenvolvimento proximal de Vygotsky)
2. Não foram vistos em > 14 dias (decay)
3. Aparecem em múltiplas áreas (alta utilidade de transferência)

Anti-jitter: random reduzido. Determinístico explicável.

---

## 4. Ensinar virtudes sem moralismo

### A premissa errada do v2

V2 trata virtudes como conceitos: "aprenda sobre honestidade". Aristóteles já apontou: **virtudes não são conhecidas, são habituadas**. Você não ensina honestidade — você cria condições para a prática repetida da honestidade.

### Princípio de design

**Não existe "aula de virtude". Existe estrutura de prática.**

### Estrutura proposta

**1. Exame noturno (Stoic-inspired, 3 perguntas, 2 min)**

Toda noite, opcional (mas ritual). 3 perguntas que rotacionam:

- "O que você fez hoje que te orgulha?"
- "O que você fez hoje que te incomoda?"
- "Se pudesse repetir, mudaria o quê?"

Privado. Pais nunca veem o conteúdo. Apenas: "kid fez exame X vezes este mês."

**Importante:** o app **não comenta** as respostas no momento. Só acumula. A acumulação é o trabalho.

Inspirado em: Sêneca, *De Ira* III.36. Marco Aurélio, *Meditações* I. Práticas reflexivas de Pierre Hadot.

**2. Dilemas anônimos**

1×/semana, kid recebe um dilema real (anonimizado de outros kids ou histórico):

> "Você quebrou um vaso da sua mãe. Ninguém viu. Conta?"
>
> Opções (não certas/erradas): conta agora · espera ela perceber · conserta e fica quieto · conta amanhã

Vê distribuição de outras crianças (anonimizada). Vê o que **1 adulto ponderado** pensa, com raciocínio (não regra). Não há resposta correta, há raciocínios visíveis.

Isso ensina **deliberação moral**, não regra moral. Diferença é tudo.

**3. Microações reportadas (não pontuadas)**

Kid pode (opcional) logar microações de virtude:
- "Pedi desculpa para X"
- "Devolvi algo emprestado"
- "Esperei minha vez quando queria não esperar"

Vai pro Caderno. Não pontua. Não gamifica. Cria registro autobiográfico. Em 6 meses kid vê: "fiz 23 pedidos de desculpa este ano". Isso é identidade formada por evidência.

**4. Histórias densas, não fábulas**

Substituir "aula de coragem com hook + curiosidade + insight" por:
- 1 história real (8-12 min), narrada com tempo
- 2 perguntas no fim (não checkpoints — perguntas abertas)
- Silêncio depois

Repertório: vidas de Sócrates infantil, Anne Frank, Malala (versão criança), Frederick Douglass jovem, biografias contemporâneas. Tolstói para crianças. Saint-Exupéry. Mitos.

A história *é* a aula. Não há pílula. **A narrativa carrega o peso moral sem dizer "seja corajoso".**

**5. Espelho semestral**

A cada 6 meses, kid responde 12 perguntas sobre si mesmo. Sistema mostra: comparado a 6 meses atrás, suas respostas mudaram em X dimensões. Pais recebem versão narrada por LLM (não numérica):

> "Mariana está se vendo mais responsável e menos paciente que há 6 meses. Em particular, ela menciona mais frequentemente situações onde sentiu raiva. Vale uma conversa sobre o que tem acontecido."

### Como medir sem gamificar

**Não medir o quê o kid faz. Medir consistência da prática.**

- Quantas vezes fez exame noturno este mês? (privado)
- Quantos dilemas refletiu? (privado)
- Variação na auto-percepção ao longo do tempo (privado)
- Quantos microregistros no caderno? (privado)

**Pais recebem:** narrativa qualitativa, não score. "Seu filho refletiu sobre honestidade 4 vezes este mês."

Nunca medalha "Honesto bronze/prata/ouro". Isso transforma virtude em troféu, exatamente o que destrói virtude.

---

## 5. Aprendizado emocionalmente memorável

### O que torna memória de longo prazo

Pesquisa de memória autobiográfica (Conway, Pillemer): lembramos do que teve **carga emocional, novidade, ou marcou identidade**. Quase nada do que não tem.

V2 atual: insight + checkpoint + animação. Zero carga emocional duradoura.

### Mecanismos para mudar isso

**1. Cold open cinematográfico**

Aula começa **sem contexto**, em medias res:

> "Em 1962, num laboratório de Yale, um homem segurou um botão por 47 horas. Quando soltou, ele chorou. Mas não chorou de cansaço."

Pausa. Reage o kid. Só depois vem o conceito.

Inspiração: Pixar opens. Sandman openings. Documentários BBC.

**2. Predição antes da revelação**

Antes do conceito, kid prediz: "o que vc acha que vai acontecer com o homem do botão?" Kid se compromete com palpite. **Compromisso aumenta carga emocional do reveal em 3-4x** (literatura de educação científica).

**3. Misdirection ética**

Aula sobre justiça começa contando história onde "o bandido óbvio" não é o bandido real. Kid recebe a virada. Aprende que primeira impressão engana — sem ninguém dizer "primeira impressão engana".

**4. Silêncio como design**

Algumas aulas terminam **sem fechamento**. Sem card. Sem skill+. Sem "próxima aula amanhã!". Apenas:

> "Pense nisso até amanhã."

Tela escura. App fecha sozinho em 10s.

A ausência de gratificação é o que faz a coisa ficar martelando. **Sistema 2 do Kahneman só ativa quando o Sistema 1 não fecha.**

**5. Áudio real, multimídia escassa**

Maioria das aulas é texto. Ocasionalmente:
- Áudio real de Carl Sagan (15s)
- Foto antiga de um experimento
- Vídeo de 8 segundos de algo improvável

Raro = memorável. Constante = ruído.

**6. Personal callback (longo prazo)**

3 meses depois, aula nova abre com:

> "Quando vc tinha 9 anos e 3 meses, vc me disse que [resposta antiga do kid]. Hoje, eu queria voltar nisso."

Citação literal da própria criança. **Profundamente desestabilizador** (no bom sentido). Cria sensação de continuidade narrativa pessoal.

### Arco emocional de uma aula

```
Curiosidade → Tensão → Predição → Reveal → Pertencimento → Silêncio
```

NÃO:

```
Hook → Quiz → Win → Animation → Reward → Next
```

Diferença: o primeiro é narrativa, o segundo é máquina caça-níquel intelectualizada.

---

## 6. Anti-overstimulation — filosofia de "calm tech for kids"

### Comparação real entre paradigmas

| Sistema | Filosofia de reward | Resultado em criança |
|---|---|---|
| **Duolingo** | Reward de alta frequência + perda (hearts) + ansiedade (streak) | Engajamento alto, retenção em domínio fraca, ansiedade documentada |
| **Nintendo (Zelda BotW)** | Reward é *exploração nova do mundo* | Foco, awe, brincadeira intrínseca |
| **Montessori** | Material auto-corretivo, sem reward externo | Concentração de 40+ min em 6 anos |
| **Journey/GRIS** | Beleza estética + descoberta narrativa | Memória emocional durável |
| **Khan Academy (modo focado)** | Progresso silencioso, sem fanfarra | Adesão em quem tem motivação |

LittleStars v2 está **estruturalmente mais próximo de Duolingo**. Isso é, ironicamente, a coisa exata que a "aula de notificações" denuncia. Auto-contradição do produto.

### Princípio de design v3: **reward só quando insubstituível**

Toda celebração no app deve passar este filtro:

1. Esse reward é *irreplaceable* (a coisa em si não foi recompensa suficiente)?
2. Se removermos, o kid para?
3. Estamos treinando *aprender* ou *querer o reward*?

Se a resposta 3 é "querer reward" → remover.

### UI calma

- **Cores semânticas, não decorativas.** Verde só quando significa progresso real. Não para enfeitar botão.
- **Tipografia generosa.** Espaço em branco. Sem densidade de feed.
- **Animações mínimas.** Spring suave, sem confete.
- **Som: ausente por padrão.** Som ocasional, propositado.
- **Sem badge counts.** Sem "(3 new)" em qualquer lugar.
- **Sem notificações** por default. Opt-in com fricção.

### Reward loops maduros propostos

**Ao final de aula** — substituir os 5 efeitos atuais por **uma das três coisas, escolhida pelo contexto:**

1. Frase final do Guia + tela escura por 3s. Acabou.
2. Card minted (raro — 1×/semana max) com momento solene de reveal.
3. Nada. Volta pra home. Próxima aparece amanhã.

**Streak semanal, não diário.** Pressure-free. Perder uma semana não zera nada, só pausa.

**Skill scores: invisíveis ao kid por default.** Visíveis ao pai. Kid pode pedir pra ver. Não é o eixo da experiência.

**Rank: descartar.** Substituir por "fases da jornada" narrativa (Iniciante → Aprendiz → Praticante → Mentor), avanço quase invisível, sem celebração. Acontece quando acontece.

**Atlas cresce em silêncio.** Conceito novo aparece sem fanfara. Kid descobre na próxima visita. Surpresa quieta.

### A regra mestre

> **Se a remoção de uma animação faria o kid parar, o problema não é a animação. É a aula.**

---

## 7. Arquitetura v3 ideal

### Modelo conceitual (entidades core)

```
Learner (perfil + trajetória)
  ├── CognitiveProfile        # estilo inferido (não auto-declarado)
  ├── Trajectory              # event-source de tudo
  └── ParentLink              # relação leve com adulto co-responsável

Concept (atômico)
  ├── Edges (typed)           # generalizes, manifests_in, requires, ...
  └── Difficulty              # 1-5, ajustado por dados

Encounter (substitui Mission)
  ├── concept_ids[]
  ├── format                  # story | dilemma | experiment | reflection | recall
  ├── duration_target         # 5-15min
  ├── prerequisite_concepts   # do grafo
  └── version                 # CMS-versioned

Practice (não é encounter — é repetição)
  ├── concept_id
  ├── trigger                 # contextual: hora, frase digitada, evento parent
  └── ritual_type             # if-then, journal, exame, microação

Reflection (resposta livre do kid)
  ├── encounter_id?           # opcional, pode ser orgânico
  ├── llm_analysis            # extraído: temas, conceitos, valência
  ├── privacy_level           # private | shared_with_parent | public_pseudo
  └── parent_visibility       # narrativa, não literal

Evidence (artefato)
  ├── type                    # text | photo | audio | parent_observation
  ├── encounter_id
  └── confidence              # triangulado

Adaptation (proposta do sistema)
  ├── candidates[]            # 3 opções pro kid escolher
  ├── reasoning               # explicável, auditável
  └── chosen_id               # kid escolheu
```

### Camadas (separação dura)

```
┌──────────────────────────────────────────────────┐
│  Content Layer (CMS)                             │
│  - Encounters, Concepts, Practices               │
│  - Versionado, A/B, revisado por pedagogo        │
│  - Editorial review + safety review obrigatórios │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│  Personalization Layer                           │
│  - Funções puras sobre Trajectory                │
│  - Adaptation::Propose → 3 candidates + reason   │
│  - Auditável: "por que esse encontro?"           │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│  LLM Layer (sandboxed)                           │
│  - Stateless inference                           │
│  - Prompts versionados                           │
│  - Eval suite obrigatório por mudança            │
│  - Multi-model: DeepSeek primary, GPT fallback   │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│  Verification Layer                              │
│  - Triangulation engine                          │
│  - Combina self-report + evidence + parent       │
│  - Output: confidence_score, não pass/fail       │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│  Safety Layer                                    │
│  - Pre/post LLM content filter                   │
│  - Topic locks (parent-controlled)               │
│  - Audit log (parent-readable)                   │
│  - Crisis detection (suicídio, abuso, etc.)      │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│  Analytics Layer (read-only sink)                │
│  - ETL para warehouse separado                   │
│  - Cohort analysis, retention, transfer          │
│  - NÃO toca a UX do kid (separação dura)         │
└──────────────────────────────────────────────────┘
```

### Pipeline de eventos (event-sourced)

```
EncounterStarted
  → ConceptIntroduced (1..n)
  → CheckpointAttempted (com timing)
  → EvidenceSubmitted?
  → ReflectionWritten?
  → EncounterCompleted (com confidence_score)

PracticeAttempted (durante o dia, fora de encounter)
  → RitualLogged

ParentObservationSubmitted

RecallTriggered → RecallSuccess | RecallFail

TransferDetected (LLM identifica uso espontâneo cross-area)

AdaptationProposed → AdaptationChosen | AdaptationDeclined

CrisisSignalDetected (safety hard path)
```

Trajetória inteira = sequência imutável desses eventos. Adaptation lê do replay. Analytics lê do replay. Parent dashboard lê do replay. **Single source of truth**.

### Personalização real

`Adaptation::Propose(learner)` retorna 3 candidatos com `reason` legível:

```ruby
{
  candidates: [
    { encounter_id: 142, reason: "Conecta a 'dopamina' que vc viu há 5 dias", confidence: 0.8 },
    { encounter_id: 89,  reason: "Outra área — Caráter — que vc pouco visitou", confidence: 0.6 },
    { encounter_id: 201, reason: "Volta em 'açúcar' que vc reportou difícil", confidence: 0.7 },
  ],
  cognitive_signal: {
    style: "verbal-reflective",
    pace: "medium-slow",
    avoidance_pattern: "skip on long checkpoints"
  }
}
```

Kid escolhe. Agência é parte da pedagogia.

### Versionamento pedagógico

- Cada `Encounter` tem versão semântica (major.minor.patch).
- Mudança major = re-revisão pedagógica obrigatória.
- A/B: kid em cohort A vê v2.3.0, cohort B vê v2.4.0. Análise mede transferência em 30d.
- Reverter encounter ruim: deprecate, kids ativos terminam o que começaram, novos pegam substituta.

### Safety + moderação

- Pre-LLM: prompt injection filter (kid type tentativa de jailbreak → bloqueia).
- Post-LLM: content classifier — idade-apropriado, sem medicina/legal/risk advice.
- Topic locks parentais: "sem dinheiro até 10 anos", "sem morte/luto até autorizar".
- Crisis detection: padrões em reflexões livres (auto-lesão, abuso). Trigger humano + parent (com tato).
- Audit log: parent pode ler transcrição completa de qualquer dia, com nota "isso pode quebrar confiança — use com cuidado".

### Explainability para pais

Toda decisão do sistema é explicável:
- Por que esse encontro? → reason legível.
- Por que essa skill subiu? → eventos que contribuíram.
- O que o sistema acha sobre meu filho? → narrativa LLM, com flag "isso é opinião do sistema, não diagnóstico".

---

## 8. Como testar se o produto funciona

### Métricas reais (norte verdadeiro)

1. **Transfer rate em 90d.** Kid usa conceito de área A em encounter de área B espontaneamente. Detectável por LLM-judge sobre reflections livres. Meta: 25% dos encounters em 90d mostram transferência.

2. **Behavioral persistence em 30d.** Kid reporta comportamento novo + evidência ≥1 + ainda fazendo aos 30d (probe deslocado). Meta: 35%.

3. **Self-narrative complexity.** Reflexões livres do kid ao longo de 6 meses. LLM mede: diversidade de vocabulário emocional, referências a próprio passado, articulação de causa-efeito interna. Meta: subir 30% em 6 meses.

4. **Parent-reported life change.** Trimestral, 1 pergunta: "no último trimestre, seu filho fez/disse algo que vc atribuí a esse app?" Resposta qualitativa. Meta: 60% de pais com pelo menos 1 evento citável.

5. **Voluntary depth.** Kid revisita Atlas / Caderno sem prompt. Sinal de internalização. Meta: 40% dos kids ativos visitam Atlas espontaneamente 1×/semana após mês 2.

### Métricas falsas (descartar como North Star)

- ❌ Aulas completadas
- ❌ Tempo no app
- ❌ Daily active users
- ❌ Streak de login
- ❌ Cards acumulados
- ❌ Skill score raw
- ❌ Quiz accuracy
- ❌ NPS de criança (criança fala bem de tudo que pisca)

Todas são *vanity metrics* de engajamento. Não medem aprendizado.

### Estudos necessários

**1. Pré/pós no enrollment (sempre, para todos).**
- Day 0: kid responde 12 perguntas que medem 5 dimensões (auto-controle, curiosidade, empatia, reflexão, responsabilidade). 8 min.
- Day 90: repete mesmas 12 perguntas.
- Day 180: repete.
- Delta = sinal de transformação.

**2. Cohort A/B (contínuo).**
- Features novas vão para 20% antes de 100%.
- Métrica: transfer rate em 60d, não engajamento em 7d.
- Decisão: mantém se transfer rate ≥ baseline, mesmo se engajamento cair.

**3. Estudo etnográfico (10 famílias, 6 meses).**
- Visitas mensais (presencial ou vídeo).
- Diário do pai.
- Entrevista trimestral com criança.
- Procura: efeitos não-óbvios. Negativos. Inesperados.

**4. Estudo de evasão (todos os kids que pararam após 60d).**
- Entrevista de 15 min com pai.
- "Por que parou? O que faltou? Algum efeito que ficou?"
- **Mais valioso que qualquer survey de feliz.**

**5. Estudo longitudinal (3 anos, 50 famílias, anual).**
- Sem variável de controle ainda, mas baseline rico.
- Pergunta: aos 12 anos, kids que fizeram 3 anos da app são *diferentes* dos que não fizeram? Em quê?

### Placebo pedagógico — sinais de autoengano

🚨 **Pais elogiam mas não citam exemplo concreto.** Sinal de placebo. "Adoro esse app!" sem "ontem ela falou X".

🚨 **Kid ama, mas pergunta sobre conceito 1 mês depois = silêncio.** Engajamento ritual, não aprendizado.

🚨 **Completion alto + transfer rate baixo.** Maioria dos quiz apps. Você está fazendo um Duolingo.

🚨 **Skills sobem mas comportamento real do kid (relatado por professor independente) não muda.** Você está medindo o próprio sistema, não o mundo.

🚨 **Pais usam dashboard como prova social pra outros pais.** Sinal de que dashboard virou produto-para-pais, não ferramenta-pra-criança.

🚨 **Time celebra release de feature, não release de evidência de aprendizado.**

---

## 9. A grande tese

### Frase única

> **LittleStars é uma prática quieta e plurianual de autoconhecimento e formação de modelos mentais para crianças. O app é a estrutura; o pai e a vida real são o laboratório.**

### O que isso significa concretamente

**Estamos construindo:** um *companion* de formação humana de longo prazo. Pensar em décadas, não em sessões.

**Estamos prometendo:** não que seu filho aprenderá uma lista de coisas. Estamos prometendo que ele **notará coisas sobre si mesmo e o mundo que de outra forma passariam batidas**, e que essas notícias se acumularão em discernimento ao longo de anos.

**Nos diferenciamos por:**
- Medir **transferência**, não completion.
- Recusar **gamificar virtude**.
- Tratar **pais como co-pedagogos**, não clientes.
- Aceitar **menos crianças mais profundas** do que mais crianças superficiais.
- Conteúdo **revisado por humano formado**, não LLM solto.

### O que NÃO devemos virar

- ❌ Duolingo de curiosidades humanísticas.
- ❌ TikTok com narrativa pedagógica.
- ❌ Substituto de escola.
- ❌ Ferramenta de vigilância parental disfarçada.
- ❌ App que pais compram pra aliviar culpa por dar tela demais.
- ❌ Plataforma de "growth hacking" para kids.

### Princípios não-negociáveis

1. **Slow is good.** Anti-binge por design. Nunca otimizar para sessão > 15 min.
2. **Práticas > conteúdo.** Repetir > novo. Caderno > aula nova.
3. **Quieto > alto.** Calma como estética + ética.
4. **Evidência > alegação.** Triangulação sobre self-report.
5. **Transferência > completion.** Atlas > listão de aulas.
6. **Palavras do kid > palavras do LLM.** Reflexão livre é central.
7. **Conversa pai-filho > dashboard.** O app produz pretextos para diálogo.
8. **Virtude não pontua.** Caráter é anti-gamificável. Não tentar.
9. **Opt-in everything.** Sem notificações ofensivas, sem gancho ansioso.
10. **LLM é escritor, não professor.** Pedagogia humana revisa. Sempre.

---

## 10. Reconstrução com 20%

### KEEP (o que sobrevive — ~20%)

| Componente | Por quê |
|---|---|
| Taxonomia das 7 áreas | Boa cobertura humanística |
| 45 conceitos + edges (com novos tipos) | Espinha dorsal do grafo |
| Discovery Card (raríssima) | Bom artefato, se usado com escassez |
| Isolamento `Academy::` | Arquitetura ótima |
| Schema `LearnerSignal` + `Trajectory` event-source | Base para personalização |
| Recall scaffolding (reformulado para generativo) | Reaproveitar SM-2 lite |
| Voz contraintuitiva do Guia | Anti-moralizante, concreto |
| Conteúdo das áreas Mente Forte + Corpo & Saúde | Melhor trabalho do v2 |

### DESTROY (jogar fora — sem cerimônia)

- **Sistema de Rank** (contador travestido de progresso, anti-pedagógico)
- **Medalhas** (dopamina barata)
- **Skill score como gamificação visível** (manter privado/parental)
- **Secrets-as-decoration** (não desbloqueia nada real)
- **Honor-system challenge report** (substituir por evidência + caderno)
- **Celebração múltipla no end-of-mission** (remover todas)
- **session_complete controlado por LLM** (system-controlled)
- **Atlas como scroll grid** (rebuild como mapa)
- **Pílula-do-dia como ritual principal** (substituir por reflexão noturna)
- **Notificações pra retenção** (todas opt-in)
- **Streak diário** (substituir por semanal)
- **Skill awarding na conclusão** (só após evidência + delay)
- **"Aula de virtude"** (substituir por dilema + exame noturno + história)

### REDESIGN COMPLETAMENTE

**1. Unidade de produto.** "Aula de 5 minutos" → "Encontro + Prática + Reflexão" distribuídos em 3-5 dias por conceito.

**2. Verificação de comportamento.** Honor-system → Triangulação multimodal (evidência + probe deslocado + parent ping).

**3. Recall.** SM-2 reconhecimento → Generativo com LLM-judge + Reativação emocional aos 60d.

**4. Atlas.** Grid scroll → Mapa 2D com gravidade visual + arestas tipadas + clique → biografia do conceito.

**5. Parent dashboard.** Métricas → **Digest narrativo semanal** (LLM gera 1 parágrafo: "esta semana, sua filha refletiu sobre X, mencionou Y, e parece estar processando Z").

**6. Personalização.** Bandit aleatório → Adaptação com 3 opções + razão legível + kid escolhe.

**7. Checkpoint.** Multiple choice dominante → **Explain-back com LLM-judge** dominante.

**8. Onboarding.** "Bem-vindo, escolha avatar" → **Manifesto de 60 segundos**: "Aqui é diferente. A gente vai devagar. Vc vai pensar mais que clicar. Pai e mãe estão nessa também. Topa?"

### SIMPLIFICAR RADICALMENTE

**Home do kid: 1 entrada.** "Sua coisa para hoje." Não 6 opções. Uma. Pode ser encounter, recall, reflexão, ou "tira folga hoje".

**Métrica visível pro kid: 1.** "Coisas que vc notou" (lista crescente de reflexões + cards). Não rank, não skills, não medals.

**Tempo de sessão alvo: 8-12 min.** Não maximizar. Limitar.

**Conteúdo: profundidade > volume.** 8 encontros excelentes por área >> 40 encontros bons.

**Notificação por default: 1 por semana.** Domingo à noite: "ritual de espelho disponível". Não opcionalmente: 0.

**Equipe editorial: pedagogo + psicólogo infantil + escritor.** Não engenheiro escrevendo aula. Não LLM gerando solo.

---

## Coda — onde isso te leva

Se você fizer 60% disso, você sai do território de "edtech infantil" e entra num território quase vazio: **prática contemplativa para crianças, com tecnologia ao redor, não no centro**.

Não há concorrente direto. Não há mercado óbvio. Não há viralidade fácil. Os pais que entenderão serão minoria — mas alta convicção.

A pergunta estratégica que precisa responder antes de seguir:

> Quero construir um negócio de 10 milhões de usuários superficiais ou de 200 mil famílias profundas?

São produtos diferentes. Os trade-offs não são compatíveis. V3 como proposto é o segundo. Se você quer o primeiro, jogue fora esta proposta e refine o v2 — ele já está alinhado com isso.

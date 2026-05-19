# Change: Academy v5 — Missões por Lentes

## Why

A Academy v4 entregou capacidade técnica (formatos `discovery`/`story_choice`/`pattern_meta`, Pokédex evolutiva, apostas numéricas, Bússola) mas, na prática, 97% das missões em produção continuam sendo chat Q&A linear — um Guia LLM disparando 6 beats de texto enquanto o aprendiz clica 1 opção de múltipla escolha por sessão. Isso teto-fixa a profundidade cognitiva em DOK ≤ 2 (Webb): o aprendiz reconhece o conceito, mas não o transfere.

A pesquisa sobre aprendizagem profunda é consistente: **transferência depende de exposição por múltiplos ângulos do mesmo conceito**, não de exposição repetida ao mesmo ângulo. LittleStars existe para formação humana, não para passar de ano — e formação humana é exatamente o domínio onde DOK 3-4 (síntese, transferência cross-contexto) é o que importa.

A v5 refunda a Academy em torno deste princípio: cada missão atravessa um mesmo conceito por N lentes — científica, narrativa, ética, estatística, histórica, primeira-pessoa, analogia — escolhidas e ordenadas algoritmicamente pela melhor didática para aquele aprendiz naquele momento. Lentes são geradas por uma LLM altamente refinada com prompts específicos por tipo de lente; o sistema (não o aprendiz) decide a sequência; lentes estão sempre presentes (não são unlock condicional).

## What Changes

**Refundação da unidade pedagógica**

- A missão continua sendo a unidade atômica e ensina **um conceito** (cardinalidade 1:1 missão↔conceito-foco).
- Internamente, cada missão é uma jornada por N lentes do mesmo conceito (4–7 lentes, fechamento avaliado por critérios didáticos, não por contagem fixa).
- Lentes substituem o atual modelo de "sessões" (`sessions_count`) e o framework PÍLULA de 6 beats por sessão.
- Cada lente é um mini-formato interativo (não chat): predição→revelação, comparação de casos, reconstrução sequencial, ensine-pro-Téo, caçada de padrão entre 3 cenas, narrativa-bifurcação, exploração estatística, encarnação histórica.

**Geração de conteúdo por LLM refinada**

- Cada tipo de lente tem um prompt template altamente curado (estilo, restrições, formato JSON de saída).
- Lente gerada 1x por `(concept_slug, lens_type, age_band, locale)` e cacheada em `academy_lens_cache`. Personalização leve (nome do aprendiz, dados do contexto familiar) injetada na renderização sem regenerar.
- Curadoria humana opcional via admin (override do output do LLM por lente individual).

**Sistema didático escolhe a ordem**

- Novo serviço `Academy::Lens::ChooseNext` decide qual lente abrir a seguir com base em: heurística pedagógica padrão (concreto antes de abstrato, narrativa antes de generalização, transferência ao final), sinais do aprendiz coletados durante a missão (tempo gasto, erros em micro-checks, sinal afetivo), e variedade obrigatória (não repete tipo de lente seguidamente).
- Aprendiz não escolhe a próxima lente. Pode revisitar lentes já vistas via Pokédex.

**Pokédex repensada**

- Pokédex passa a marcar profundidade conceitual: L1 = uma lente vista, L2 = missão completa (todas lentes do conceito visitadas em UMA missão), L3 = conceito visto em 2+ missões de áreas diferentes (transferência confirmada).
- Mantém o tooling visual atual (silhueta → spotted → recognized → mastered, animação pulse, sons WebAudio).

**Limpeza profunda (no backward compat)**

- `mission.format` enum (`discovery`/`story_choice`/`pattern_meta`) removido — todas as missões agora são lens journeys.
- `mission.sessions_count`, `scenes_tree`, `teaser_for_next_mission_id` removidos.
- `Academy::AdvanceTurn`, `Academy::StartMission`, `Academy::Llm::GuidePersona`, `Academy::Llm::GuideAgent` removidos. Substituídos por `Lens::*` services.
- `academy_aula_concept` (M:N) substituído por coluna direta `mission.concept_id` (1:1).
- `academy_practice_wagers` mantido (vira lente Predict→Reveal); `academy_learner_story_paths` mantido (vira estado interno da lente narrativa).
- Conteúdo v4 (40 missões discovery + 1 story_choice) migrado: cada missão velha vira semente cujas lentes a LLM gera no primeiro acesso.

**Recompensas dos pais por aprender → fora de escopo**

- Pais ganharão capacidade de oferecer pontos por completar missões/conceitos, em paridade com o sistema atual de tarefas. **Esta é uma fase posterior** (v5.1 ou v6), não faz parte deste change.

## Impact

- **Affected specs**: cria `lens-mission`, `lens-generation`, `pokedex-depth`, `mission-content-pipeline`. Remove especificações implícitas de `mission-discovery-chat`, `mission-story-choice`, `mission-pattern-meta`, `mission-sessions`.
- **Affected code**: praticamente todo `app/{models,services,controllers,views,components}/{academy,kid/academy,parent/academy}`. Migrations destrutivas em `academy_missions`, `academy_aula_concepts`. Stimulus controllers de chat (`academy_chat_controller.js`) saem; novos controllers de lente entram (`lens_carousel_controller.js`, `lens_predict_controller.js`, etc).
- **Affected jobs**: `Academy::Transfer::Detect` revisitado (agora é gatilho explícito de avanço L2→L3 da Pokédex). `Academy::Digests::Compose` revisitado para narrar lentes visitadas em vez de checkpoints.
- **Data migration**: tabela `academy_lens_cache` nova. Backfill: pra cada missão v4 existente, gerar `lens_seed` (conceito-foco + objetivo de aprendizado), descartar `scenes_tree`/`sessions_count`/`format`. Lentes em si são geradas lazy no primeiro acesso por aprendiz.
- **LLM cost**: trade-off intencional — autoria humana cai drasticamente, custo run-time de LLM sobe na primeira passagem por lente. Cache global por `(concept, lens_type, age_band, locale)` amortiza para custo aproximadamente zero a partir da segunda exposição.
- **Risco maior**: qualidade das lentes geradas. Cada tipo de lente precisa de prompt-eval rigoroso antes de ir pra produção. Eval suite v5 é parte do escopo deste change.

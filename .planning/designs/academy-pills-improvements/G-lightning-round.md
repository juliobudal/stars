# G — Lightning Round (retrieval gamificado semanal)

> **Objetivo.** Criar um modo de retrieval lúdico de 60-90 segundos —
> 5 micro-checks de conceitos com maestria caindo — que use a tabela
> `LearnerConcept` já existente para combater o esquecimento sem soar
> como "revisão de matéria escolar".

## Motivação

- A Academy v2 já tem `LearnerConcept` com sinal de maestria
  (`app/models/academy/learner_concept.rb`).
- Spaced repetition é mencionada em `docs/academy-v2.md` como feature
  de design.
- Mas hoje **não há experiência de uso** desses dados — o kid revisa
  apenas se voltar a missões antigas (raríssimo).

Lightning Round monetiza esses dados como **gamificação ativa**:
- 60-90 segundos.
- 5 perguntas múltipla escolha extraídas de conceitos com
  `last_seen_at > 7d` e `mastery_score in [0.4..0.7]` (zona de
  esquecimento, não de domínio nem de novato).
- Acertou 5/5 → "Mente brilhante!" + pontos extras.
- Acertou 3-4/5 → "Quase lá!" + revisão do que errou.
- Acertou 0-2/5 → "Vamos com calma" + sugere refazer 1 missão.

É a única estrutura no produto que **consolida** o conhecimento
distribuído por missões esparsas.

## Escopo

**Entra:**
- Service `Academy::Pills::BuildLightningRound` — escolhe 5 conceitos.
- View `kid/academy/lightning/show` — UI rapidona (1 pergunta por tela,
  swipe ou click, timer visível).
- Resultado + delta de maestria no `LearnerConcept`.
- Badge "Lightning Champion da semana" se mantiver streak de 4
  Lightning Rounds com 4+/5.

**NÃO entra:**
- Geração de perguntas novas — usa o `micro_check` já existente nas
  lentes curadas.
- Lightning Round adaptativo em tempo real (responder errado não troca
  as próximas perguntas).
- Multiplayer (kid contra irmão) — fica pra V2.

## Trabalho

### Passo 1 — Service de seleção (2h)

`app/services/academy/pills/build_lightning_round.rb`:

```ruby
class Academy::Pills::BuildLightningRound < Academy::ApplicationService
  def call(learner:)
    candidates = Academy::LearnerConcept.where(learner_id: learner.id)
                                        .where(mastery_score: 0.4..0.7)
                                        .where("last_seen_at < ?", 7.days.ago)
                                        .order(Arel.sql("RANDOM()"))
                                        .limit(20)

    return fail_with(:not_enough_concepts) if candidates.size < 5

    picked = candidates.first(5)
    rounds = picked.map { |lc| pick_micro_check_for(lc.concept) }.compact
    return fail_with(:no_micro_checks) if rounds.size < 5

    ok(rounds: rounds)
  end

  private

  def pick_micro_check_for(concept)
    # Pega o micro_check de uma lens curada do concept.
    cache = Academy::LensCache.where(
      source: "curated", age_band: "kid", locale: "pt-BR",
      concept_id: concept.id
    ).where("payload->'micro_check' IS NOT NULL")
     .order(Arel.sql("RANDOM()")).first

    return nil if cache.nil?
    {
      concept_id: concept.id,
      concept_name: concept.name,
      question: cache.payload.dig("micro_check", "question"),
      options: cache.payload.dig("micro_check", "options"),
      correct_index: cache.payload.dig("micro_check", "correct_index"),
      rationale: cache.payload.dig("micro_check", "rationale")
    }
  end
end
```

### Passo 2 — Controller + view (3h)

`app/controllers/kid/academy/lightning_controller.rb`:
- `show` — chama service e renderiza wizard.
- `answer` (POST) — recebe resposta de uma pergunta; atualiza score
  em sessão; avança.
- `finish` — calcula resultado, atualiza `LearnerConcept` (delta
  positivo se acertou, leve negativo se errou), renderiza tela final.

`app/views/kid/academy/lightning/show.html.erb`:
- UI inspirada em Duolingo Lessons: timer no topo (90s), barra de
  progresso (1/5, 2/5...), pergunta no centro, 4 botões grandes (uma
  por opção).
- Animações simples: shake em erro, sparkle em acerto.
- Sons opcionais (mute por default no produto pro respeito de
  contexto familiar).

### Passo 3 — Acesso (1h)

Onde aparece o Lightning Round?
- Card secundário no kid home, **abaixo** da Pílula do Dia (item D).
  Texto: "⚡ Lightning Round — 90s pra testar memória".
- Disponível 1x por dia ou 1x por semana? **Recomendação: 1x por dia**
  com cooldown intra-day, e candidatos suficientes (basta ter ~25
  conceitos com maestria 0.4-0.7 no histórico).

### Passo 4 — Streak/badge (1h)

- Tabela `lightning_round_runs` (learner_id, started_at, correct_count,
  total).
- Badge "⚡ Lightning Champion" se ≥4 runs em 7 dias com ≥4 acertos
  cada.
- Mostra no parent dashboard como "esta semana Lia entrou em rotina
  de retrieval".

## Critérios de aceite

1. Kid com 25+ concepts em zona [0.4, 0.7] consegue iniciar Lightning
   Round.
2. Wizard completa em ≤90s (timer).
3. `LearnerConcept.mastery_score` muda no sentido correto após cada
   resposta.
4. Specs:
   - `spec/services/academy/pills/build_lightning_round_spec.rb` —
     seleção + corner cases (<5 candidatos).
   - `spec/system/kid/academy/lightning_round_spec.rb` — fluxo full.

## Riscos

- **Sensação de prova**: kid pode achar que é teste escolar. Mitigação:
  copywriting (não dizer "teste"/"prova"; usar "round", "desafio",
  "Lightning"); música opcional; cores e animações ágeis.
- **Sem candidatos suficientes** nos primeiros dias de uso. Mitigação:
  fallback gentil: "Tomou poucas pílulas ainda. Vai virar Lightning
  Champion quando tiver mais aulas!".
- **Erros frustrantes em cadeia** (0/5). Mitigação: tela final
  enfatiza "isso é jogo, não é prova — você tá treinando".

## Estimativa

- Total: **~8h**.

## Dependências

- **Depende de A** (mais conteúdo curado = mais maestria distribuída).
- **Depende de F** (sinergia: poderia priorizar conceitos relacionados
  ao interesse declarado pra adicionar uma camada de personalização).
- **Independe de B/C/D** mas casa bem com D no kid home.

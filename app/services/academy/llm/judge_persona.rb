# frozen_string_literal: true

module Academy
  module Llm
    # LLM-as-judge prompt — v4 (rubrica enxuta, version-agnostic).
    #
    # Avalia UMA lente pedagógica (payload já validado por schema). NÃO audita
    # tom nem didática — essas responsabilidades vivem nos templates `lens/`,
    # e evoluem livremente a cada bump de `template_version` (v3 → v4 → v5…).
    # Acoplar o juiz a uma persona específica (Bill Nye, O Guia v2, etc.) faria
    # o juiz rejeitar conteúdo bom só porque a voz mudou de versão.
    #
    # Mandato do juiz:
    #   1. FACTUAL    — sem alucinação (data, fonte, número, citação fabricada)
    #   2. CONCEITO   — a lente ensina o conceito declarado, não derivou
    #   3. SEGURANÇA  — apropriado pra 7-12, respeita valores da família
    #
    # Score: 0..100 (confiança consolidada). Substitui o overall_score 0..12
    # da rubrica v3 — old cache rows ficam naturalmente fora do example pool
    # (filtro `>= 85` exclui valores 0..12 antigos).
    #
    # Verdict:
    #   PASS   = nenhum problema detectado · score >= 85
    #   REVISE = drift de conceito leve · 50 <= score < 85
    #   FAIL   = alucinação OU violação de segurança OU score < 50
    module JudgePersona
      VOICE = <<~PROMPT
        Você é um JUIZ factual para o LittleStars Academy, um produto de
        formação humana para crianças de 7-12 anos. Sua função é UMA só:
        impedir que conteúdo factualmente errado, fora do conceito, ou
        inapropriado chegue à criança.

        # O QUE VOCÊ NÃO FAZ

        - Não audita tom, voz, persona, ou estilo. Templates já cuidam disso.
        - Não pontua "gancho", "concretude", "voz do narrador", "encaixe etário".
        - Não reescreve. Não conserta. Não continua a lente.
        - Não pune por escolha estética (humor seco, frases curtas, gíria leve).

        # O QUE VOCÊ VERIFICA — 3 EIXOS

        ## 1. FACTUAL (alucinação)
        - Datas, lugares, nomes próprios são reais ou plausíveis?
        - Fontes citadas existem ou são honestas como estimativa? ("Common
          Sense Media 2023" ok; URL específica inventada NÃO ok)
        - Números soam verossímeis pra o domínio? Não precisam ser exatos,
          mas não podem ser absurdos.
        - Citações atribuídas (Bíblia, filósofos, cientistas) batem com o
          autor citado? Se inventada → falha factual.

        ## 2. CONCEITO (drift)
        O `concept.name` declarado no contexto é REALMENTE o que a lente
        ensina, ou ela derivou pra um conceito vizinho/parecido?
        Exemplo: lente declarada como "dopamina" que na verdade ensina
        "vício" genérico → drift. Aceitar tangência leve; rejeitar quando
        a sacada principal não é do conceito.

        ## 3. SEGURANÇA (gate)
        Conteúdo apropriado pra 7-12 anos? Verifique:
        - Sem violência gráfica, erotização, ou trauma desnecessário
        - Sem incentivo a desonestidade, desrespeito a pais, ou auto-dano
        - Sem ridicularização de fé (família cristã — Bíblia ao lado de
          filósofos universais é bem-vindo; sermão não é)
        - Tema sensível (morte, sofrimento, medo) tratado com gravidade
          adequada à idade, não evitado nem explorado

        # SCORE — 0..100

        Confiança consolidada de que a lente pode ser entregue à criança.
        - 100 = nenhum problema detectado
        -  85 = pequenos detalhes (fonte vaga, número aproximado declarado)
        -  70 = drift de conceito leve mas reparável
        -  50 = drift significativo OU número/data com erro factual
        -  30 = alucinação clara (fonte inventada, citação fake)
        -   0 = violação de segurança

        # VERDICT

        PASS   = score >= 85 E sem violação de segurança
        REVISE = score entre 50 e 84 (drift reparável)
        FAIL   = score < 50 OU violação de segurança (independente do score)

        # FORMATO DE SAÍDA — JSON ESTRITO

        Responda APENAS um objeto JSON válido, sem texto antes/depois,
        sem ```json fences:

        {
          "score": 0..100,
          "verdict": "PASS" | "REVISE" | "FAIL",
          "factual_issue": "1 frase específica · null se sem problema",
          "concept_drift": "1 frase específica · null se sem problema",
          "safety_issue":  "1 frase específica · null se sem problema",
          "critique":      "1 frase: a MAIOR fragilidade · null se PASS perfeito",
          "rewrite_hint":  "1 instrução acionável focada na alavanca · null se PASS"
        }

        Seja preciso, breve, calibrado. O `rewrite_hint` precisa nomear
        ESPECIFICAMENTE o que mudar (não "melhore a fidelidade" — "troque
        'estudos da OMS' por uma estimativa honesta declarada como tal").
      PROMPT

      # User prompt builder — recebe a lente concreta + contexto do conceito.
      # `payload` é o hash já validado por schema (8 formatos possíveis).
      # Renderizamos o payload bruto em JSON pra evitar perder estrutura
      # específica por lens_type (cada tipo tem campos próprios).
      def self.user_prompt(concept:, lens_type:, payload:, age_band: "kid")
        action_label = ::Academy::Lens::Catalog.kid_action_label(lens_type)

        <<~USR
          # CONTEXTO

          Conceito alvo (slug): #{concept.slug}
          Nome do conceito: #{concept.name}
          #{concept_description_block(concept)}
          Tipo de lente: #{lens_type} (kid vê: "#{action_label[:emoji]} #{action_label[:action]}")
          Faixa etária: #{age_band == 'kid' ? '7-12 anos' : age_band}

          # LENTE A SER JULGADA (payload validado por schema)

          ```json
          #{JSON.pretty_generate(payload)}
          ```

          # SUA TAREFA

          Avalie os 3 eixos (factual · conceito · segurança). Retorne APENAS
          o JSON do veredito.
        USR
      end

      def self.concept_description_block(concept)
        desc = concept.respond_to?(:description) ? concept.description : nil
        return "" if desc.blank?
        "Descrição do conceito: #{desc.to_s.strip}\n"
      end
    end
  end
end

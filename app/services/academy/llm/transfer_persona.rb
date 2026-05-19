# frozen_string_literal: true

module Academy
  module Llm
    # Prompt for the cross-area transfer judge (Academy::Transfer::Detect).
    # Asks the LLM: in this learner's text, did they spontaneously APPLY any
    # concept they already encountered in *another* mission?
    module TransferPersona
      VOICE = <<~PROMPT
        # IDENTIDADE
        Você é um avaliador de TRANSFERÊNCIA conceitual em aprendizado infantil.
        Sua tarefa: ler uma resposta livre de um aprendiz e identificar se ele
        aplicou ESPONTANEAMENTE algum conceito que já encontrou em OUTRO contexto.

        # CRITÉRIO DE TRANSFERÊNCIA
        Transferência genuína = o aprendiz traz à tona um conceito não óbvio
        (não está na missão atual; não está sendo perguntado a ele) para
        explicar/ilustrar algo na resposta dele.
        Exemplo: missão atual é sobre açúcar; aprendiz menciona "dopamina" ou
        "recompensa variável" sem ser cobrado → TRANSFERÊNCIA.

        # SEJA EXIGENTE
        Falsos positivos são piores que falsos negativos. Só marque com
        confidence ≥ 0.75 quando o conceito FOI realmente aplicado (não só
        nomeado).

        # FORMATO DE SAÍDA — JSON ESTRITO
        Você responde APENAS com JSON, sem prosa antes/depois:
        {
          "applied": [
            { "slug": "dopamina", "confidence": 0.82, "snippet": "trecho onde aparece" }
          ]
        }
        Se nada aplica, retorne: { "applied": [] }
      PROMPT

      def self.user_prompt(content:, known_concepts:, current_concept_slugs:)
        known_lines = known_concepts.map do |concept|
          headline = concept.try(:definition).to_s.split(".").first
          "- #{concept.slug}: #{concept.name}#{headline.present? ? " — #{headline}" : ''}"
        end

        <<~USER
          # TEXTO DO APRENDIZ
          """
          #{content.to_s.strip}
          """

          # CONCEITOS QUE ELE JÁ ENCONTROU (em outras missões — candidatos a transferência)
          #{known_lines.join("\n")}

          # CONCEITOS DA MISSÃO ATUAL (NÃO conte esses como transferência)
          #{Array(current_concept_slugs).join(', ').presence || '(nenhum)'}

          # PERGUNTA
          O aprendiz aplicou algum conceito da primeira lista? Responda em JSON.
        USER
      end
    end
  end
end

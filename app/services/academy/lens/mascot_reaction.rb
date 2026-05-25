# frozen_string_literal: true

require "zlib"

module Academy
  module Lens
    # One-line owl reactions surfaced under the micro_check after the kid
    # answers. Pure module: no LLM, no DB. Deterministic — the same seed
    # always picks the same line so reactions stay stable across renders.
    #
    # Bucketed by (lens_type, correct?). Each bucket has 3–4 short lines
    # voiced under the broader "O Guia" persona: authoritative, mysterious,
    # fascinated; no moralizing.
    module MascotReaction
      Reaction = Data.define(:emoji, :text, :tier)

      EMOJI = "🦉"

      POOL = {
        scientific: {
          correct: [
            "Mecanismo entendido. Próxima peça.",
            "Você viu o circuito por dentro.",
            "É isso — a engrenagem só ficou clara depois que você desmontou.",
            "Resposta certa. O 'porquê' é mais bonito que o 'qual'."
          ],
          wrong: [
            "Volta um passo. O corpo não mente.",
            "Quase. O mecanismo tem uma peça a mais no meio.",
            "Erro normal — a intuição salta a etapa do meio.",
            "Não é essa. Mas você tá olhando o lugar certo."
          ]
        },
        statistical: {
          correct: [
            "Calibragem afiada.",
            "Você sentiu a ordem de grandeza.",
            "A intuição estatística vem com prática — e você tem.",
            "Cravou. Adultos erram muito mais que isso."
          ],
          wrong: [
            "O número é mais raro do que parece.",
            "Erro de zero é comum — a gente conta o que aparece, não o que falta.",
            "A intuição te traiu — números pequenos enganam.",
            "Olha de novo: cada zero a menos divide a chance por dez."
          ]
        },
        narrative: {
          correct: [
            "Você leu a cena inteira.",
            "Pegou o detalhe que só aparece relendo.",
            "Resposta de quem prestou atenção no que NÃO foi dito.",
            "Cena entendida — agora ela fica."
          ],
          wrong: [
            "Volta na cena. O detalhe tá lá.",
            "Quase. A história é mais sutil que o resumo.",
            "Você pulou uma frase — aconteceu o oposto.",
            "Boa tentativa, mas a cena te contou outra coisa."
          ]
        },
        ethical: {
          correct: [
            "Coragem registrada.",
            "Você viu o que o medo escondia.",
            "Acertou — é a escolha mais difícil de explicar pra si mesmo.",
            "Resposta de quem topa pagar o custo."
          ],
          wrong: [
            "A coragem mora no outro lado.",
            "É o caminho fácil — não é o errado, mas não é o que essa lente pede.",
            "Olha de novo: qual escolha exige você presente?",
            "Errou — e tudo bem. Errar aqui é mais comum que acertar."
          ]
        },
        analogy_bridge: {
          correct: [
            "A ponte se formou.",
            "Você viu a mesma forma em dois mundos.",
            "Resposta de quem reconhece padrão.",
            "Cravou — agora o conceito vale em qualquer lugar."
          ],
          wrong: [
            "A analogia é parecida, mas não idêntica.",
            "Você viu metade do paralelo.",
            "Os mundos batem em outro ponto. Olha de novo.",
            "Não é essa — a ponte sobe por outro lado."
          ]
        },
        first_person: {
          correct: [
            "Você sentiu na pele.",
            "Resposta de corpo, não de cabeça.",
            "Cravou — o experimento foi você.",
            "Acertou porque você fez, não porque leu."
          ],
          wrong: [
            "Volta e tenta com o corpo, não com a cabeça.",
            "Você descreveu o que pensou, não o que aconteceu.",
            "A resposta tá no que o corpo registrou.",
            "Tenta de novo prestando atenção no que você sentiu."
          ]
        },
        historical: {
          correct: [
            "Padrão histórico lido.",
            "Você viu o mesmo gesto em séculos diferentes.",
            "Resposta de historiador.",
            "Cravou — o que importa é o que se repete."
          ],
          wrong: [
            "O padrão é mais antigo do que isso.",
            "Quase. A história rima, mas não copia.",
            "Você olhou só uma das cenas — o padrão pede três.",
            "Não é essa. Mas tá perto."
          ]
        },
        engineering: {
          correct: [
            "Trade-off entendido.",
            "Você escolheu pagar o preço certo.",
            "Resposta de engenheiro: ninguém ganha sem perder algo.",
            "Cravou — todo design é uma escolha sobre o que sacrificar."
          ],
          wrong: [
            "Toda escolha custa. Você não considerou um dos custos.",
            "Não tem combo perfeito — esse troca dor por outra dor.",
            "Volta e olha o que essa escolha DEIXA DE FORA.",
            "Errou pela primeira intuição — a segunda é mais cara, mas funciona."
          ]
        },
        default: {
          correct: [
            "Acertou.",
            "Resposta certa.",
            "Cravou.",
            "Boa — segue."
          ],
          wrong: [
            "Não é essa.",
            "Tenta de novo.",
            "Quase.",
            "Erra pra acertar depois."
          ]
        }
      }.freeze

      def self.for(lens_type:, correct:, seed:)
        bucket = POOL[lens_type.to_sym] || POOL[:default]
        options = bucket[correct ? :correct : :wrong]
        return nil if options.blank?

        Reaction.new(
          emoji: EMOJI,
          text: options[stable_index(seed, options.length)],
          tier: correct ? :correct : :wrong
        )
      end

      def self.stable_index(seed, modulo)
        return 0 if modulo <= 1
        if seed.is_a?(Integer)
          seed.abs % modulo
        else
          Zlib.crc32(seed.to_s) % modulo
        end
      end
    end
  end
end

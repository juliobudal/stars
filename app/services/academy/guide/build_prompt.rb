# frozen_string_literal: true

module Academy
  module Guide
    # Assembles the system prompt for one Guide chat turn.
    #
    # Output: ok(system:, lesson_topic:)
    #
    # The `system` string ships `Persona::VOICE` followed by a single
    # "ESTA AULA" block built from the lesson's curated content (the enigma,
    # the revelation, and the clues). The persona references the lesson topic
    # where it would otherwise say [NOME-DO-CONCEITO].
    class BuildPrompt < ApplicationService
      def initialize(learner:, lesson:)
        @learner = learner
        @lesson = lesson
      end

      def call
        ok(system: compose, lesson_topic: @lesson.title)
      end

      private

      def compose
        <<~TXT
          #{Persona::VOICE}

          # ESTA AULA (o único assunto permitido)

          Tópico (use no lugar de [NOME-DO-CONCEITO]): #{@lesson.title}
          Trilha: #{@lesson.trail.title}

          O enigma de abertura: #{@lesson.enigma}

          A revelação central (o insight que a criança acabou de ver):
          #{@lesson.revelation}

          Pistas que ela viu pelo caminho:
          #{clues_block}
        TXT
      end

      def clues_block
        @lesson.clues.map { |c| "- #{c}" }.join("\n")
      end
    end
  end
end

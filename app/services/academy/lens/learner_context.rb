# frozen_string_literal: true

module Academy
  module Lens
    # Snapshot of everything the LLM should know about the learner-vs-concept
    # state at generation time. Stays inside the Academy boundary — the host
    # (Profile/Family) is never reached. Built from `learner_id` + `concept`.
    #
    # `mastery_tier` is bucketed (2 tiers + the learner-agnostic "any") to
    # keep the LensCache footprint bounded:
    #
    #   level 0..1  → "introductory"  (silhouette / spotted)
    #   level 2..3  → "advanced"      (recognized / mastered)
    #   no learner  → "any"           (warmup / prewarm)
    class LearnerContext < Data.define(:learner_id, :mastery_tier, :wrong_streak, :related_concept_names)
      MASTERY_TIERS = %w[any introductory advanced].freeze

      def self.build(learner_id:, concept:)
        return any_for(concept) if learner_id.nil?

        level = ::Academy::LearnerConcept
                  .where(learner_id: learner_id, concept_id: concept.id)
                  .pick(:level) || 0
        tier  = level >= 2 ? "advanced" : "introductory"

        streak = ::Academy::LensSignal
                   .where(learner_id: learner_id, concept_id: concept.id,
                          signal_type: "micro_check_wrong")
                   .where(recorded_at: 24.hours.ago..)
                   .count

        new(learner_id: learner_id, mastery_tier: tier, wrong_streak: streak,
            related_concept_names: related_concept_names(concept))
      end

      def self.any_for(concept)
        new(learner_id: nil, mastery_tier: "any", wrong_streak: 0,
            related_concept_names: related_concept_names(concept))
      end

      def self.related_concept_names(concept)
        outgoing = concept.outgoing_edges.includes(:to_concept).limit(4).map { |e| e.to_concept&.name }
        incoming = concept.incoming_edges.includes(:from_concept).limit(2).map { |e| e.from_concept&.name }
        (outgoing + incoming).compact.uniq.first(5)
      end

      # Plain-text hint emitted into the prompt. Empty when learner is absent
      # so prewarm generations stay generic and cache-shareable.
      def difficulty_hint
        case mastery_tier
        when "introductory"
          "Aprendiz NOVATO neste conceito — ancore em exemplos concretos do dia-a-dia, evite jargão."
        when "advanced"
          "Aprendiz já familiarizado — pode trazer nuance, edge case, ou aplicação não-óbvia."
        else
          ""
        end
      end

      def adaptive_hint
        if wrong_streak >= 2
          "ATENÇÃO: aprendiz errou últimas 2 micro-checks deste conceito. Reduza dificuldade desta lente; reancore."
        else
          ""
        end
      end
    end
  end
end

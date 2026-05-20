# frozen_string_literal: true

module Academy
  module Lens
    # Snapshot of the learner-vs-concept state used by the Guide chat
    # prompt builder. Stays inside the Academy boundary — the host
    # (Profile/Family) is never reached. Built from `learner_id` + `concept`.
    #
    # `level` is the raw `Academy::LearnerConcept#level` (0..3):
    #   0 silhouette · 1 spotted · 2 recognized · 3 mastered
    # `wrong_streak` is the count of `micro_check_wrong` signals in the
    # last 24 hours — the BuildPrompt voice softens when ≥ 2.
    class LearnerContext < Data.define(:learner_id, :level, :wrong_streak, :related_concept_names, :interests)
      def self.build(learner_id:, concept:, interests: [])
        return any_for(concept, interests: interests) if learner_id.nil?

        level = ::Academy::LearnerConcept
                  .where(learner_id: learner_id, concept_id: concept.id)
                  .pick(:level) || 0

        streak = ::Academy::LensSignal
                   .where(learner_id: learner_id, concept_id: concept.id,
                          signal_type: "micro_check_wrong")
                   .where(recorded_at: 24.hours.ago..)
                   .count

        new(learner_id: learner_id, level: level, wrong_streak: streak,
            related_concept_names: related_concept_names(concept),
            interests: Array(interests))
      end

      def self.any_for(concept, interests: [])
        new(learner_id: nil, level: 0, wrong_streak: 0,
            related_concept_names: related_concept_names(concept),
            interests: Array(interests))
      end

      def self.related_concept_names(concept)
        outgoing = concept.outgoing_edges.includes(:to_concept).limit(4).map { |e| e.to_concept&.name }
        incoming = concept.incoming_edges.includes(:from_concept).limit(2).map { |e| e.from_concept&.name }
        (outgoing + incoming).compact.uniq.first(5)
      end

      def advanced? = level >= 2
      def novice?   = !advanced?

      # Top interest entry — used by `Lens::ResolveCuratedPayload` to pick a
      # variant payload (e.g. narrative/<slug>.<interest>.json). Nil when
      # the learner declared none. The shape comes from `Academy::Interest`
      # (responds to #key/#label) when built from a Profile; raw strings
      # are also tolerated.
      def top_interest = Array(interests).first

      def top_interest_key
        i = top_interest
        i.respond_to?(:key) ? i.key : i&.to_s
      end

      # Friendly label-only list ("Dinossauros, Lego, Gatos") to thread
      # into LLM prompts without leaking internal slugs. Caps at 3 to keep
      # the prompt tight.
      def interests_str
        Array(interests).first(3).map { |i|
          i.respond_to?(:label) ? i.label : i.to_s
        }.reject(&:blank?).join(", ")
      end
    end
  end
end

# frozen_string_literal: true

module Academy
  module Pills
    # Builds a 5-question Lightning Round — a 60-90s retrieval round drawn
    # from concepts the learner has previously seen but is fading on
    # (spotted/recognized levels) and hasn't touched in a week.
    #
    # Result data shape:
    #   { rounds: [ { concept_id:, concept_name:, question:, options:, correct_index:, rationale: }, ... ] }
    #
    # Fails:
    #   :not_enough_concepts — fewer than 5 fading concepts in pool.
    #   :no_micro_checks     — pool exists but no payloads carry a micro_check.
    class BuildLightningRound < ApplicationService
      MIN_ROUNDS         = 5
      FORGETTING_HORIZON = 7.days

      def initialize(learner:)
        @learner = learner
      end

      def call
        return fail_with(:no_learner) unless @learner

        candidates = candidate_concepts
        return fail_with(:not_enough_concepts) if candidates.size < MIN_ROUNDS

        rounds = candidates.shuffle.take(MIN_ROUNDS * 2).filter_map do |lc|
          micro_check_for(lc)
        end
        rounds = rounds.first(MIN_ROUNDS)

        return fail_with(:no_micro_checks) if rounds.size < MIN_ROUNDS

        ok(rounds: rounds)
      end

      private

      def candidate_concepts
        ::Academy::LearnerConcept.for_learner(@learner.id)
          .where(level: 1..2)
          .where("last_seen_at < ?", FORGETTING_HORIZON.ago)
          .includes(:concept)
          .to_a
      end

      def micro_check_for(learner_concept)
        cache = ::Academy::LensCache.curated.servable
                  .where(concept_id: learner_concept.concept_id,
                         age_band: "kid", locale: "pt-BR")
                  .where("payload ? :k", k: "micro_check")
                  .order(Arel.sql("RANDOM()")).first
        return nil unless cache

        mc = cache.payload["micro_check"]
        return nil if mc.nil? || mc["question"].blank? || mc["options"].blank?

        {
          concept_id:    learner_concept.concept_id,
          concept_name:  learner_concept.concept.name,
          question:      mc["question"],
          options:       Array(mc["options"]),
          correct_index: mc["correct_index"].to_i,
          rationale:     mc["rationale"].to_s
        }
      end
    end
  end
end

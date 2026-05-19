# frozen_string_literal: true

module Academy
  module Lens
    # Nightly proactive warmer. Identifies active learners (login within 7 days),
    # asks Compass::Propose for their likely next missions, and pre-generates
    # missing lens cache rows so the first lens-open at runtime is hot.
    #
    # Idempotent (cache-hit short-circuit in Lens::Generate). Throttled by
    # a hard cap on LLM calls per run.
    #
    # Observability: returns a hash report; consumer logs structured metrics.
    class WarmCacheJob < ApplicationJob
      queue_as :default

      DEFAULT_MAX_LLM_CALLS = 50
      ACTIVE_WINDOW_DAYS    = 7
      MISSIONS_PER_LEARNER  = 3

      def perform(max_llm_calls: DEFAULT_MAX_LLM_CALLS)
        return unless ::Academy.configured?

        @llm_budget = max_llm_calls
        @lenses_warmed = 0
        @llm_calls_made = 0

        active_learner_ids.each do |learner_id|
          break if @llm_budget <= 0
          warm_for_learner(learner_id)
        end

        Rails.logger.info(
          "[Academy::Lens::WarmCacheJob] warmed=#{@lenses_warmed} llm_calls=#{@llm_calls_made} budget_remaining=#{@llm_budget}"
        )

        { lenses_warmed: @lenses_warmed, llm_calls_made: @llm_calls_made }
      end

      private

      def active_learner_ids
        cutoff = ACTIVE_WINDOW_DAYS.days.ago
        ::Academy::MissionProgress
          .where("updated_at >= ?", cutoff)
          .distinct
          .pluck(:learner_id)
      end

      def warm_for_learner(learner_id)
        plan = ::Academy::Compass::Propose.call(learner_id: learner_id)
        return unless plan.success?

        plan.data.cards.first(MISSIONS_PER_LEARNER).each do |card|
          concept = card.mission&.concept
          next unless concept

          warm_concept(concept)
          break if @llm_budget <= 0
        end
      end

      def warm_concept(concept)
        Catalog.types.each do |lens_type|
          break if @llm_budget <= 0

          entry = Catalog.fetch(lens_type)
          already = LensCache.for_key(
            concept_id: concept.id, lens_type: lens_type,
            age_band: "kid", locale: "pt-BR", template_version: entry.template_version
          ).exists?
          next if already

          result = Generate.call(concept: concept, lens_type: lens_type)
          if result.success?
            @lenses_warmed += 1
            @llm_calls_made += 1
            @llm_budget -= 1
          end
        end
      end
    end
  end
end

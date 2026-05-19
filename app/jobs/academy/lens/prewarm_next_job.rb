# frozen_string_literal: true

module Academy
  module Lens
    # Just-in-time warmer dispatched from the kid path after a lens renders.
    # Pre-generates likely-next lens types for the in-flight mission so the
    # next "Continuar →" can render from cache instead of blocking on the LLM.
    #
    # Idempotent: Lens::Generate short-circuits on cache hit, so re-runs are
    # cheap. Bounded by MAX_CANDIDATES per dispatch. Silent on missing
    # progress / unconfigured module so the kid request never depends on it.
    class PrewarmNextJob < ApplicationJob
      queue_as :default

      MAX_CANDIDATES = 2

      def perform(mission_progress_id:)
        return unless ::Academy.configured?

        progress = ::Academy::MissionProgress.find_by(id: mission_progress_id)
        return unless progress&.mission&.concept

        concept = progress.mission.concept
        likely_next_lens_types(progress).first(MAX_CANDIDATES).each do |lens_type|
          result = Generate.call(concept: concept, lens_type: lens_type, learner_id: progress.learner_id)
          next if result.success?

          Rails.logger.warn(
            "[Academy::Lens::PrewarmNextJob] progress=#{progress.id} lens=#{lens_type} failed=#{result.error}"
          )
        end
      end

      private

      # Predicts the next 1-2 lens types the kid is most likely to be served
      # without simulating ChooseNext's full state machine. Uses the same
      # rotation order (concrete → abstract → closure), excluding types
      # already visited in this attempt and the currently open visit's type.
      def likely_next_lens_types(progress)
        visits = ::Academy::LearnerLensVisit
                   .where(mission_progress_id: progress.id)
                   .order(:ordering_position)
                   .pluck(:lens_type)
        visited = visits.map(&:to_sym).uniq
        current_type = visits.last&.to_sym

        rotation = (ChooseNext::CONCRETE_OPENERS +
                    ChooseNext::ABSTRACT_LENSES +
                    ChooseNext::CLOSURE_LENSES).uniq

        # Honor curated coverage: when the concept has any curated rows,
        # only warm types that are actually curated. Otherwise prewarm would
        # trigger LLM generation for types ChooseNext will never pick.
        concept_id = progress.mission&.concept_id
        curated = if concept_id
          ::Academy::LensCache.curated.servable
            .where(concept_id: concept_id, age_band: "kid", locale: "pt-BR")
            .pluck(:lens_type).map(&:to_sym).to_set
        end

        rotation
          .reject { |t| visited.include?(t) || t == current_type }
          .select { |t| curated.nil? || curated.empty? || curated.include?(t) }
      end
    end
  end
end

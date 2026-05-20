# frozen_string_literal: true

module Academy
  module Missions
    # Closes the current open lens visit, scores it, asks ChooseNext for the
    # next lens; if the journey is done, dispatches to Missions::Finalize.
    # Otherwise opens a new visit + generates the next lens.
    #
    # Replaces v4 AdvanceTurn. Transacional.
    class AdvanceLens < ApplicationService
      Stage = Data.define(:progress, :visit, :lens_cache, :mission_complete) do
        def mission_complete? = mission_complete
      end

      def initialize(progress:, signal_payload: {}, outcome: "completed")
        @progress = progress
        @signal_payload = signal_payload || {}
        @outcome = outcome.to_s
      end

      def call
        ApplicationRecord.transaction do
          # Lock the progress row for the duration of the transaction so two
          # concurrent advances (e.g. a double-click before the loading
          # overlay covers the form) can't both compute the same
          # `ordering_position` and crash on the unique index.
          @progress.lock!

          return fail_with(:concept_missing) unless @progress.mission&.concept

          open_visit = current_open_visit
          return fail_with("Nenhuma lente aberta.") unless open_visit

          close_visit!(open_visit)
          score_visit!(open_visit)

          decision = ::Academy::Lens::ChooseNext.call(mission_progress: @progress).data

          if decision.done
            finalize!
            return ok(Stage.new(progress: @progress.reload, visit: open_visit, lens_cache: nil, mission_complete: true))
          end

          cache = try_generate_with_fallbacks!(decision.next_lens)
          unless cache
            # Every candidate failed (e.g. all curated rows flagged, LLM
            # transport broken). Don't 503 the kid — record a signal so the
            # gap is visible to ops/parents, finalize, and let the
            # controller route to the completion screen.
            record_curated_gap_signal!(decision.next_lens)
            finalize!
            return ok(Stage.new(
              progress: @progress.reload, visit: open_visit, lens_cache: nil,
              mission_complete: true
            ))
          end

          visit = create_visit!(decision, cache)
          ok(Stage.new(progress: @progress, visit: visit, lens_cache: cache, mission_complete: false))
        end
      end

      def record_curated_gap_signal!(preferred_type)
        ::Academy::LensSignal.create!(
          mission_progress_id: @progress.id,
          learner_id: @progress.learner_id,
          concept_id: @progress.mission.concept_id,
          lens_type: preferred_type.to_s,
          signal_type: "curated_gap_hit",
          numeric_value: 1,
          recorded_at: Time.current
        )
      rescue ActiveRecord::RecordInvalid
        # Signal is observability-only; never block the kid for a logging failure.
      end

      private

      def current_open_visit
        ::Academy::LearnerLensVisit
          .where(mission_progress_id: @progress.id)
          .open_visits
          .order(:ordering_position)
          .last
      end

      def close_visit!(visit)
        merged = (visit.signal_payload || {}).merge(@signal_payload.stringify_keys)
        visit.update!(
          closed_at: Time.current,
          outcome: @outcome,
          signal_payload: merged
        )
      end

      def score_visit!(visit)
        ::Academy::Lens::ScoreVisit.call(visit: visit)
      end

      def finalize!
        ::Academy::Missions::Finalize.call(progress: @progress)
      end

      # Tries to generate the preferred lens; on schema/transport failure,
      # falls back through the rest of the catalog. Excludes every lens type
      # already visited in this mission_progress so a fallback never serves
      # the same framing twice in one mission. Returns the cache row or nil
      # if every candidate fails.
      def try_generate_with_fallbacks!(preferred_type)
        visited_types = ::Academy::LearnerLensVisit
                          .where(mission_progress_id: @progress.id)
                          .pluck(:lens_type)
                          .map(&:to_sym)
                          .to_set

        candidates = [ preferred_type ] +
                     (::Academy::Lens::Catalog.types - [ preferred_type ] - visited_types.to_a)
        candidates.compact.uniq.each do |lens_type|
          result = ::Academy::Lens::Generate.call(
            concept: @progress.mission.concept, lens_type: lens_type,
            learner_id: @progress.learner_id
          )
          return result.data if result.success?

          Rails.logger.warn(
            "[Missions::AdvanceLens] lens=#{lens_type} failed=#{result.error} — trying next candidate"
          )
        end
        nil
      end

      def create_visit!(decision, cache)
        next_position = (::Academy::LearnerLensVisit
                          .where(mission_progress_id: @progress.id)
                          .maximum(:ordering_position) || 0) + 1
        # Track the cache's actual lens_type (a fallback may have replaced the
        # preferred one); preserve the preferred type in signal_payload so the
        # fallback rate stays observable.
        actual_type = cache.lens_type.to_s
        preferred_type = decision.next_lens.to_s
        ::Academy::LearnerLensVisit.create!(
          mission_progress: @progress,
          learner_id: @progress.learner_id,
          concept_id: @progress.mission.concept_id,
          lens_type: actual_type,
          lens_cache: cache,
          ordering_position: next_position,
          opened_at: Time.current,
          signal_payload: {
            "chooser_version" => decision.version,
            "reason" => decision.reason.to_s,
            "preferred_lens_type" => preferred_type,
            "fallback_used" => (actual_type != preferred_type)
          }
        )
      end
    end
  end
end

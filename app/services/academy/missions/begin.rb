# frozen_string_literal: true

module Academy
  module Missions
    # Idempotent mission opener. Replaces v4 StartMission.
    #
    # Returns the in-flight or freshly-created MissionProgress, the first
    # open LearnerLensVisit, and the LensCache row to render. If the learner
    # already has an open mission attempt, the open visit is replayed (per
    # REQ-LMSN-008 — abandonment preserves lens position).
    class Begin < ApplicationService
      Stage = Data.define(:progress, :visit, :lens_cache)

      def initialize(learner:, mission:)
        @learner = learner
        @mission = mission
      end

      def call
        return fail_with("Missão sem conceito-foco.") unless @mission.concept

        ApplicationRecord.transaction do
          @progress = find_or_create_progress
          # Serialize concurrent begins/advances on the same progress row so
          # the (mission_progress_id, ordering_position) unique index can't
          # be violated by a racing visit-creation.
          @progress.lock!

          # Resume: if there's already an open visit, return it as-is.
          if (open_visit = open_visit_for(@progress))
            cache = lens_cache_for(open_visit)
            return ok(Stage.new(progress: @progress, visit: open_visit, lens_cache: cache))
          end

          # Fresh visit: ChooseNext picks the lens; Generate materializes the cache row.
          decision = Academy::Lens::ChooseNext.call(mission_progress: @progress).data
          # Mission already closed (completed/mastered, no open visit) — let
          # the controller route the kid somewhere meaningful instead of a 503.
          return fail_with(:mission_already_completed) if decision.done

          cache = try_generate_with_fallbacks(decision.next_lens)
          return fail_with(:lens_generation_failed) unless cache

          visit = create_visit!(decision, cache)
          ok(Stage.new(progress: @progress, visit: visit, lens_cache: cache))
        end
      end

      private

      # The unique index on (learner_id, mission_id) guarantees at most one
      # row, so we always return the existing one regardless of status —
      # filtering by status here only led to UniqueConstraint crashes when a
      # completed/mastered row already existed. Status-aware UX (replay,
      # review-only) is handled downstream by ChooseNext + the controller.
      def find_or_create_progress
        ::Academy::MissionProgress.find_or_create_by!(
          learner_id: @learner.id, mission_id: @mission.id
        ) do |progress|
          progress.status = :in_progress
          progress.started_at = Time.current
        end
      end

      def open_visit_for(progress)
        ::Academy::LearnerLensVisit
          .where(mission_progress_id: progress.id)
          .open_visits
          .order(:ordering_position)
          .last
      end

      def lens_cache_for(visit)
        ::Academy::LensCache.find_by(id: visit.lens_cache_id)
      end

      # Tries the preferred lens first; on LLM transport / JSON parse /
      # schema validation failure, walks the catalog so a single bad
      # generation doesn't 500 the kid's session.
      #
      # Curated-static pivot: if the mission's concept has curated payloads,
      # restrict the fallback walk to lens types within that curated set —
      # otherwise the walk would silently fall through to LLM types we
      # explicitly excluded from the curriculum.
      def try_generate_with_fallbacks(preferred_type)
        visited = ::Academy::LearnerLensVisit
                    .where(mission_progress_id: @progress.id)
                    .pluck(:lens_type).map(&:to_sym).uniq

        curated_set = ::Academy::LensCache.curated.servable
                        .where(concept_id: @mission.concept_id, age_band: "kid", locale: "pt-BR")
                        .pluck(:lens_type).map(&:to_sym).to_set

        pool = curated_set.empty? ? ::Academy::Lens::Catalog.types : curated_set.to_a
        candidates = ([ preferred_type ] + pool).uniq - visited
        candidates.unshift(preferred_type).uniq! unless visited.include?(preferred_type)

        candidates.each do |lens_type|
          result = ::Academy::Lens::Generate.call(
            concept: @mission.concept, lens_type: lens_type,
            learner_id: @learner.id, learner: @learner
          )
          return result.data if result.success?

          Rails.logger.warn(
            "[Missions::Begin] lens=#{lens_type} failed=#{result.error} — trying next candidate"
          )
        end
        nil
      end

      def create_visit!(decision, cache)
        next_position = (::Academy::LearnerLensVisit
                          .where(mission_progress_id: @progress.id)
                          .maximum(:ordering_position) || 0) + 1
        # Use the cache's actual lens_type, not the decision's preferred type.
        # When a preferred generation fails and try_generate_with_fallbacks walks
        # to the next candidate, the visit must reflect what was rendered or the
        # kid sees a mismatched UI shell (e.g. narrative chrome with scientific
        # payload). The preferred type is preserved in signal_payload for
        # later analysis of fallback frequency.
        actual_type = cache.lens_type.to_s
        preferred_type = decision.next_lens.to_s
        ::Academy::LearnerLensVisit.create!(
          mission_progress: @progress,
          learner_id: @learner.id,
          concept_id: @mission.concept_id,
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

# frozen_string_literal: true

module Academy
  module Missions
    # Loads a completed mission's visit ledger for read-only review.
    #
    # Returns the same `Begin::Stage`-like shape so the controller can decide
    # which view to render based on state. Only callable for progress in
    # :completed or :mastered — other states fall through to the normal
    # lens-stage flow.
    class ReviewMode < ApplicationService
      Stage = Data.define(:progress, :mission, :visits) do
        def total_visits = visits.size
        def lens_types   = visits.map(&:lens_type).uniq
      end

      VisitEntry = Data.define(:visit, :lens_cache) do
        def lens_type     = visit.lens_type
        def signal_payload = visit.signal_payload || {}
      end

      def initialize(learner:, mission:)
        @learner = learner
        @mission = mission
      end

      def call
        progress = ::Academy::MissionProgress.find_by(
          learner_id: @learner.id, mission_id: @mission.id
        )
        return fail_with(:no_progress) unless progress
        return fail_with(:not_completed) unless reviewable?(progress)

        visits = load_visits(progress)
        ok(Stage.new(progress: progress, mission: @mission, visits: visits))
      end

      def self.fetch_visit_entry(progress:, visit_id:)
        visit = ::Academy::LearnerLensVisit
                  .where(mission_progress_id: progress.id)
                  .where.not(closed_at: nil)
                  .find_by(id: visit_id)
        return nil unless visit

        VisitEntry.new(visit: visit, lens_cache: lens_cache_for(visit))
      end

      def self.lens_cache_for(visit)
        return nil unless visit.lens_cache_id

        ::Academy::LensCache.find_by(id: visit.lens_cache_id)
      end

      private

      def reviewable?(progress)
        progress.completed? || progress.mastered?
      end

      def load_visits(progress)
        visit_rows = ::Academy::LearnerLensVisit
                       .where(mission_progress_id: progress.id)
                       .where.not(closed_at: nil)
                       .order(:ordering_position)
                       .to_a

        cache_ids = visit_rows.map(&:lens_cache_id).compact
        caches_by_id = ::Academy::LensCache.where(id: cache_ids).index_by(&:id)

        visit_rows.map { |v| VisitEntry.new(visit: v, lens_cache: caches_by_id[v.lens_cache_id]) }
      end
    end
  end
end

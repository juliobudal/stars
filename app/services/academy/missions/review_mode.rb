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
      CLOSURE_TYPES = %w[analogy_bridge ethical].freeze

      Stage = Data.define(:progress, :mission, :visits, :card,
                          :next_mission, :trail_total, :trail_position) do
        def total_visits = visits.size
        def lens_types   = visits.map(&:lens_type).uniq

        # First closure lens visited in the journey (rendered as "A sacada"
        # on the completion screen). nil when the concept has no closure
        # lens curated and the mission fell back to :curated_coverage_complete.
        def closure_headline
          closure = visits.find { |v| CLOSURE_TYPES.include?(v.lens_type) }
          return nil unless closure&.lens_cache&.payload

          closure.lens_cache.payload["headline"].presence ||
            closure.lens_cache.payload["central_insight"].presence
        end
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
        ok(Stage.new(
          progress: progress, mission: @mission, visits: visits,
          card: load_card,
          next_mission: load_next_mission,
          trail_total: trail_missions.size,
          trail_position: trail_position
        ))
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

      def load_card
        ::Academy::DiscoveryCard.find_by(
          learner_id: @learner.id, mission_id: @mission.id
        )
      end

      def trail_missions
        @trail_missions ||= @mission.trail&.missions&.where(active: true)
                              &.order(:position_in_trail)&.to_a || [ @mission ]
      end

      def trail_position
        idx = trail_missions.index { |m| m.id == @mission.id }
        idx ? idx + 1 : 1
      end

      def load_next_mission
        return nil unless @mission.trail_id

        trail_missions.each_cons(2) do |current, nxt|
          return nxt if current.id == @mission.id
        end
        nil
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

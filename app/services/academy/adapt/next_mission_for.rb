# frozen_string_literal: true

module Academy
  module Adapt
    # Suggests the "pílula do dia" for a learner. Decision tree:
    #
    #   1. Any mission in_progress that's not finished? → continue it.
    #   2. Pick a fresh mission (not started, not completed/mastered) ranked by:
    #        score = subject_affinity × subject_freshness_boost × random_jitter
    #      where:
    #        affinity = LearnerSignal#affinity_score (default 1 for new subjects)
    #        freshness_boost = 1.4 when learner has 0 completed missions in
    #          that subject yet (encourage exploration of new areas);
    #          1.0 otherwise.
    #        jitter = small random per mission to break ties.
    #   3. If absolutely nothing eligible: return nil (UI falls back to the
    #      generic prompt).
    #
    # Returns: Academy::Mission or nil. Loads subject for the UI.
    class NextMissionFor < ApplicationService
      def initialize(learner_id:)
        @learner_id = learner_id
      end

      def call
        in_progress = continue_in_progress
        return ok(in_progress) if in_progress

        ok(pick_fresh)
      end

      private

      def continue_in_progress
        MissionProgress
          .where(learner_id: @learner_id, status: :in_progress)
          .includes(mission: :subject)
          .order(started_at: :desc)
          .first
          &.mission
      end

      def pick_fresh
        affinity_by_subject = LearnerSignal
                                .for_learner(@learner_id)
                                .pluck(:subject_id, :affinity_score)
                                .to_h
        affinity_by_subject.default = 0

        completed_subject_ids = MissionProgress
                                  .where(learner_id: @learner_id, status: %i[completed mastered])
                                  .joins(:mission)
                                  .distinct
                                  .pluck("academy_missions.subject_id")
                                  .to_set

        done_mission_ids = MissionProgress
                             .where(learner_id: @learner_id)
                             .pluck(:mission_id)

        candidates = Mission
                       .where(active: true)
                       .where.not(trail_id: nil)
                       .where.not(id: done_mission_ids)
                       .includes(:subject)
                       .to_a
        return nil if candidates.empty?

        ranked = candidates.map do |mission|
          base_affinity = affinity_by_subject[mission.subject_id].to_i + 1
          freshness = completed_subject_ids.include?(mission.subject_id) ? 1.0 : 1.4
          jitter = SecureRandom.random_number(0.0..0.2)
          [ mission, (base_affinity * freshness) + jitter ]
        end

        ranked.max_by { |_, score| score }&.first
      end
    end
  end
end

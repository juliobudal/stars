# frozen_string_literal: true

module Academy
  module Pokedex
    # Replays completed MissionProgress rows in completion order and runs
    # Pokedex::Advance for every (learner, concept) pair so accounts that
    # finished missions before v4 still get a populated Pokédex.
    #
    # Idempotent — running twice does not double-level.
    class Backfill < ApplicationService
      def initialize(learner_ids: nil)
        @learner_ids = Array(learner_ids).compact
      end

      def call
        scope = MissionProgress
                  .where(status: %i[completed mastered])
                  .order(:completed_at, :id)
        scope = scope.where(learner_id: @learner_ids) if @learner_ids.any?

        applied = 0
        failed  = 0

        scope.find_each(batch_size: 200) do |progress|
          mission = progress.mission
          concept = mission&.concept
          next unless concept

          result = Pokedex::Advance.call(
            learner_id: progress.learner_id,
            concept: concept,
            mission: mission,
            trigger: :mission_completed
          )
          result.success? ? applied += 1 : failed += 1
        end

        ok(applied: applied, failed: failed)
      end
    end
  end
end

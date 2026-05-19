# frozen_string_literal: true

module Academy
  module Skills
    # Awards skill points to the learner on mission finalization.
    # v5: kid path doesn't expose skills (legacy v2 surface). Kept as a
    # service for the parent dashboard to recompute on demand.
    #
    # Idempotency contract:
    #   :completed / :mastered_bonus → ONCE per mission progress. Guarded
    #     explicitly via `mission_progress.skills_awarded_at` so a future
    #     refactor that allows mission retries can't double the radar.
    #
    # Signal sources:
    #   :completed       → primary skills get +5 × weight, secondary +2 × weight
    #   :mastered_bonus  → +3 extra to the primary skill (perfect run)
    class Award < ApplicationService
      VALID_EVENTS = %i[completed mastered_bonus].freeze
      ONCE_PER_MISSION_EVENTS = %i[completed mastered_bonus].freeze

      def initialize(learner_id:, mission: nil, event:)
        @learner_id = learner_id
        @mission = mission
        @event = event.to_sym
      end

      def call
        return fail_with("Evento desconhecido: #{@event}") unless VALID_EVENTS.include?(@event)
        return ok(:already_awarded) if once_per_mission_already_recorded?

        ActiveRecord::Base.transaction do
          case @event
          when :completed
            award_for_mission_completion!
          when :mastered_bonus
            award_mastered_bonus!
          end
        end

        Rank::Recompute.call(learner_id: @learner_id)
        ok(true)
      end

      private

      # True when the event is once-per-mission and the progress already
      # has a `skills_awarded_at` stamp. The mission finalize chain stamps
      # after running the once-per-mission hooks, so any re-finalize is a
      # no-op.
      def once_per_mission_already_recorded?
        return false unless ONCE_PER_MISSION_EVENTS.include?(@event)
        return false unless @mission

        progress&.skills_awarded_at.present?
      end

      def progress
        return nil unless @mission

        @progress ||= MissionProgress.find_by(learner_id: @learner_id, mission_id: @mission.id)
      end

      def award_for_mission_completion!
        return unless @mission

        @mission.aula_skills.each do |link|
          delta = link.weight >= 2 ? 5 : 2
          bump_id!(link.skill_id, delta * link.weight)
        end
      end

      def award_mastered_bonus!
        return unless @mission

        primary = @mission.aula_skills.where(weight: 2..).first
        bump_id!(primary.skill_id, 3) if primary
      end

      def bump_id!(skill_id, delta)
        record = LearnerSkill.find_or_initialize_by(learner_id: @learner_id, skill_id: skill_id)
        record.score = record.score.to_i + delta
        record.last_event_at = Time.current
        record.save!
      end
    end
  end
end

# frozen_string_literal: true

module Academy
  module Guide
    # Returns the open conversation for (learner × mission × today), if any;
    # otherwise creates a new one frozen at the current Persona::VERSION.
    #
    # Does NOT create a new conversation if today's conversation exists but is
    # closed — that's the "volta amanhã" state, surfaced by QuotaCheck.
    class FindOrStartConversation < ApplicationService
      def initialize(learner:, mission:)
        @learner = learner
        @mission = mission
      end

      def call
        existing = today_open_conversation
        return ok(existing) if existing

        return ok(today_closed) if today_closed

        ok(create_new)
      end

      private

      def today_open_conversation
        scope_today.open_now.order(started_at: :desc).first
      end

      def today_closed
        @today_closed ||= scope_today.where.not(closed_at: nil).order(started_at: :desc).first
      end

      def scope_today
        tz = @learner.timezone.presence || "UTC"
        now_local = Time.current.in_time_zone(tz)
        ::Academy::GuideConversation
          .where(learner_id: @learner.id, mission_id: @mission.id)
          .where(started_at: now_local.beginning_of_day..now_local.end_of_day)
      end

      def create_new
        ::Academy::GuideConversation.create!(
          learner_id: @learner.id,
          mission_id: @mission.id,
          started_at: Time.current,
          prompt_version: Persona::VERSION
        )
      end
    end
  end
end

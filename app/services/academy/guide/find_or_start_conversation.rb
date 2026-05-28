# frozen_string_literal: true

module Academy
  module Guide
    # Returns today's conversation for (learner × lesson) if any, otherwise
    # creates a new one frozen at the current Persona::VERSION.
    #
    # One conversation per local-TZ day per (learner × lesson) keeps the
    # transcript scoped to a clean daily window.
    class FindOrStartConversation < ApplicationService
      def initialize(learner:, lesson:)
        @learner = learner
        @lesson = lesson
      end

      def call
        ok(today_conversation || create_new)
      end

      private

      def today_conversation
        tz = @learner.timezone.presence || "UTC"
        now_local = Time.current.in_time_zone(tz)
        ::Academy::GuideConversation
          .where(learner_id: @learner.id, lesson_id: @lesson.id)
          .where(started_at: now_local.beginning_of_day..now_local.end_of_day)
          .order(started_at: :desc)
          .first
      end

      def create_new
        ::Academy::GuideConversation.create!(
          learner_id: @learner.id,
          lesson_id: @lesson.id,
          started_at: Time.current,
          prompt_version: Persona::VERSION
        )
      end
    end
  end
end

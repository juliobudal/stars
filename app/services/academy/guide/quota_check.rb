# frozen_string_literal: true

module Academy
  module Guide
    # Enforces the chat quota: 5 user messages per session, 1 session per
    # (learner × mission × local-TZ day).
    #
    # Returns a Result whose data is:
    #   {
    #     can_send: true|false,
    #     remaining_messages: 0..MAX_MESSAGES_PER_SESSION,
    #     session_state: :new_session_available | :open | :closed_today,
    #     existing_conversation: GuideConversation | nil
    #   }
    class QuotaCheck < ApplicationService
      MAX_MESSAGES_PER_SESSION = 5

      def initialize(learner:, mission:)
        @learner = learner
        @mission = mission
      end

      def call
        existing = today_conversation
        return ok(new_session_payload) if existing.nil?

        if existing.closed?
          ok(closed_today_payload(existing))
        else
          ok(open_payload(existing))
        end
      end

      private

      def today_conversation
        tz = @learner.timezone.presence || "UTC"
        now_local = Time.current.in_time_zone(tz)
        day_start = now_local.beginning_of_day
        day_end   = now_local.end_of_day

        ::Academy::GuideConversation
          .where(learner_id: @learner.id, mission_id: @mission.id)
          .where(started_at: day_start..day_end)
          .order(started_at: :desc)
          .first
      end

      def new_session_payload
        {
          can_send: true,
          remaining_messages: MAX_MESSAGES_PER_SESSION,
          session_state: :new_session_available,
          existing_conversation: nil
        }
      end

      def open_payload(convo)
        remaining = [ MAX_MESSAGES_PER_SESSION - user_messages_count(convo), 0 ].max
        {
          can_send: remaining.positive?,
          remaining_messages: remaining,
          session_state: :open,
          existing_conversation: convo
        }
      end

      def closed_today_payload(convo)
        {
          can_send: false,
          remaining_messages: 0,
          session_state: :closed_today,
          existing_conversation: convo
        }
      end

      def user_messages_count(convo)
        convo.messages.where(role: ::Academy::GuideMessage.roles[:user]).count
      end
    end
  end
end

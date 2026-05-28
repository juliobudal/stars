# frozen_string_literal: true

module Academy
  module Guide
    # End-to-end orchestrator for one Guide chat turn.
    #
    # Returns:
    #   ok(conversation:, user_message:, guide_message:)
    #
    # Failure modes:
    #   fail_with(:no_llm_key)        — feature disabled (no env)
    #   fail_with(:empty_content)     — kid submitted blank input
    #   fail_with(:quota_exceeded)    — kid hit the daily question cap
    #   fail_with(:llm_error, data:)  — LLM client raised; user msg NOT persisted
    class Ask < ApplicationService
      SAFETY_FLAG_REGEX = /\A\[SAFETY_FLAG\]\[(?<reason>[^\]]+)\]\s*/i

      # Daily cap on kid questions per learner across all lessons.
      DAILY_QUESTION_LIMIT = 5

      def initialize(learner:, lesson:, user_content:, client: ::Academy::Llm::Client.new)
        @learner = learner
        @lesson = lesson
        @user_content = user_content.to_s.strip
        @client  = client
      end

      def call
        return fail_with(:no_llm_key) unless Academy.configured?
        return fail_with(:empty_content) if @user_content.empty?
        return fail_with(:quota_exceeded) if quota_exceeded?

        conversation = FindOrStartConversation.call(learner: @learner, lesson: @lesson).data

        ActiveRecord::Base.transaction do
          user_msg = persist_user(conversation, @user_content)
          response = call_llm(conversation)
          guide_msg = persist_guide(conversation, response)

          @result = ok(
            conversation: conversation,
            user_message: user_msg,
            guide_message: guide_msg
          )
        end

        @result
      rescue ::Academy::Llm::Client::Error => e
        fail_with(:llm_error, data: { message: e.message })
      end

      private

      # Count of kid questions sent today (learner local TZ), across lessons.
      def quota_exceeded?
        tz = @learner.timezone.presence || "UTC"
        now_local = Time.current.in_time_zone(tz)
        conv_ids = ::Academy::GuideConversation.where(learner_id: @learner.id).select(:id)
        used = ::Academy::GuideMessage
                 .where(conversation_id: conv_ids, role: ::Academy::GuideMessage.roles[:user])
                 .where(created_at: now_local.beginning_of_day..now_local.end_of_day)
                 .count
        used >= DAILY_QUESTION_LIMIT
      end

      def persist_user(conversation, content)
        ::Academy::GuideMessage.create!(
          conversation: conversation,
          role: :user,
          content: content
        )
      end

      def call_llm(conversation)
        prompt = BuildPrompt.call(learner: @learner, lesson: @lesson)
        messages = [ { role: "system", content: prompt.data[:system] } ] + transcript_messages(conversation)

        @client.chat(messages: messages)
      end

      def transcript_messages(conversation)
        conversation.messages.where(role: [ ::Academy::GuideMessage.roles[:user], ::Academy::GuideMessage.roles[:guide] ]).map do |m|
          { role: m.guide? ? "assistant" : "user", content: m.content }
        end
      end

      def persist_guide(conversation, response)
        raw = response[:content].to_s
        flagged, reason, kid_facing = detect_safety_flag(raw)

        if flagged
          reasons = (conversation.flag_reasons || []) + [ reason ]
          conversation.update!(flagged: true, flag_reasons: reasons.uniq)
        end

        usage = response[:raw].is_a?(Hash) ? response[:raw]["usage"] : nil
        ::Academy::GuideMessage.create!(
          conversation: conversation,
          role: :guide,
          content: kid_facing,
          tokens_in: usage&.dig("prompt_tokens"),
          tokens_out: usage&.dig("completion_tokens"),
          flagged: flagged
        )
      end

      def detect_safety_flag(raw)
        match = SAFETY_FLAG_REGEX.match(raw)
        return [ false, nil, raw.strip ] unless match
        [ true, match[:reason].to_s.strip.downcase, raw.sub(SAFETY_FLAG_REGEX, "").strip ]
      end
    end
  end
end

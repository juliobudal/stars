# frozen_string_literal: true

module Academy
  module Guide
    # End-to-end orchestrator for one Guide chat turn.
    #
    # Returns:
    #   ok(conversation:, user_message:, guide_message:, remaining_messages:, closed:)
    #
    # Failure modes:
    #   fail_with(:no_llm_key)         — feature disabled (no env)
    #   fail_with(:quota_exhausted)    — session is closed
    #   fail_with(:empty_content)      — kid submitted blank input
    #   fail_with(:llm_error, data:)   — LLM client raised; user msg NOT persisted
    class Ask < ApplicationService
      SAFETY_FLAG_REGEX = /\A\[SAFETY_FLAG\]\[(?<reason>[^\]]+)\]\s*/i

      def initialize(learner:, mission:, user_content:, client: ::Academy::Llm::Client.new)
        @learner = learner
        @mission = mission
        @user_content = user_content.to_s.strip
        @client  = client
      end

      def call
        return fail_with(:no_llm_key) unless Academy.configured?
        return fail_with(:empty_content) if @user_content.empty?

        quota = QuotaCheck.call(learner: @learner, mission: @mission)
        return fail_with(:quota_exhausted) unless quota.data[:can_send]

        convo_result = FindOrStartConversation.call(learner: @learner, mission: @mission)
        conversation = convo_result.data
        return fail_with(:quota_exhausted) if conversation.closed?

        ActiveRecord::Base.transaction do
          user_msg = persist_user(conversation, @user_content)
          response = call_llm(conversation)
          guide_msg = persist_guide(conversation, response)
          maybe_close(conversation)

          remaining = remaining_after(conversation)
          @result = ok(
            conversation: conversation,
            user_message: user_msg,
            guide_message: guide_msg,
            remaining_messages: remaining,
            closed: conversation.reload.closed?
          )
        end

        @result
      rescue ::Academy::Llm::Client::Error => e
        fail_with(:llm_error, data: { message: e.message })
      end

      private

      def persist_user(conversation, content)
        ::Academy::GuideMessage.create!(
          conversation: conversation,
          role: :user,
          content: content
        )
      end

      def call_llm(conversation)
        prompt = BuildPrompt.call(learner: @learner, mission: @mission)
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

      def maybe_close(conversation)
        count = conversation.messages.where(role: ::Academy::GuideMessage.roles[:user]).count
        return unless count >= QuotaCheck::MAX_MESSAGES_PER_SESSION
        conversation.update!(closed_at: Time.current)
      end

      def remaining_after(conversation)
        used = conversation.messages.where(role: ::Academy::GuideMessage.roles[:user]).count
        [ QuotaCheck::MAX_MESSAGES_PER_SESSION - used, 0 ].max
      end
    end
  end
end

# frozen_string_literal: true

module Academy
  # One persisted turn in a GuideConversation. Roles:
  #   - user        : kid input
  #   - guide       : LLM response (may carry a flagged: true if [SAFETY_FLAG] fired)
  #   - system_note : controller-issued note (e.g. "Guia está descansando" on Client::Error)
  #
  # The [SAFETY_FLAG][reason] prefix is stripped from `content` shown to the kid
  # before persistence is unnecessary — we keep the stripped, kid-facing string
  # here and record the trigger reason on the parent conversation. Parents see
  # the trigger via `flagged: true` + the conversation's `flag_reasons`.
  class GuideMessage < ApplicationRecord
    self.table_name = "academy_guide_messages"

    belongs_to :conversation,
               class_name: "Academy::GuideConversation",
               inverse_of: :messages

    enum :role, { user: 0, guide: 1, system_note: 2 }

    validates :content, presence: true

    after_create_commit :increment_conversation_counter

    private

    def increment_conversation_counter
      Academy::GuideConversation
        .where(id: conversation_id)
        .update_all("message_count = message_count + 1, updated_at = NOW()")
    end
  end
end

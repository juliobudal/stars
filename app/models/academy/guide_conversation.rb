# frozen_string_literal: true

module Academy
  # A single (learner × mission × day) Q&A thread with the Guia.
  #
  # `learner_id` is a no-FK bigint per the Academy module isolation contract.
  # `mission_id` is FK into academy_missions.
  #
  # `prompt_version` freezes the persona/scope/safety prompt identifier at
  # conversation start so future iterations of `Academy::Guide::Persona` do
  # not retroactively change how an older transcript should be read.
  #
  # Lifecycle:
  #   - `started_at` set on create.
  #   - `closed_at` set when message_count hits cap OR session expires.
  #   - `flagged` flips to true the first time the LLM emits [SAFETY_FLAG]; the
  #     bracketed reason is appended to `flag_reasons`.
  class GuideConversation < ApplicationRecord
    self.table_name = "academy_guide_conversations"

    belongs_to :mission, class_name: "Academy::Mission"
    has_many :messages, -> { order(:created_at) },
             class_name: "Academy::GuideMessage",
             foreign_key: :conversation_id,
             dependent: :destroy,
             inverse_of: :conversation

    validates :learner_id, presence: true
    validates :started_at, presence: true
    validates :prompt_version, presence: true

    scope :open_now, -> { where(closed_at: nil) }
    scope :flagged_first, -> { order(flagged: :desc, started_at: :desc) }

    def open? = closed_at.nil?
    def closed? = !open?
  end
end

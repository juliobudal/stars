# frozen_string_literal: true

# == Schema Information
#
# Table name: academy_messages
#
#  id         :bigint           not null, primary key
#  content    :text             not null
#  metadata   :jsonb            not null
#  role       :integer          default("guide"), not null
#  tokens     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  session_id :bigint           not null
#
# Indexes
#
#  idx_academy_messages_session       (session_id)
#  idx_academy_messages_session_time  (session_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (session_id => academy_sessions.id)
#
module Academy
  class Message < ApplicationRecord
    self.table_name = "academy_messages"

    belongs_to :session, class_name: "Academy::Session", inverse_of: :messages

    # system: prompt scaffolding the LLM receives but the kid never sees.
    # guide:  the LLM's narrated reply ("O Guia" speaking to the kid).
    # learner: the kid's reply (text or option pick).
    enum :role, { system: 0, guide: 1, learner: 2 }, default: :guide

    validates :content, presence: true

    # v4 — fire cross-area transfer detection on learner free-text turns
    # that are long enough to plausibly carry a concept reference.
    after_commit :enqueue_transfer_detection, on: :create

    # Convenience accessors over the jsonb metadata blob.
    def options         = metadata.fetch("options", [])
    def kind            = metadata["kind"]
    def checkpoint?     = kind == "checkpoint"
    def checkpoint_kind = metadata["checkpoint_kind"] || "multiple_choice"
    def session_done?   = !!metadata["session_complete"]

    private

    def enqueue_transfer_detection
      return unless learner?
      return if kind == "answer" # checkpoint pick, not free-text reasoning
      return if content.to_s.strip.length < ::Academy::Transfer::Detect::MIN_CONTENT_LENGTH

      ::Academy::Transfer::DetectJob.perform_later(id)
    end
  end
end

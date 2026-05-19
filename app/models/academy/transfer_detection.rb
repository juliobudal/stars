# frozen_string_literal: true

module Academy
  # Auditable record of a spontaneous cross-concept transfer detected by the
# == Schema Information
#
# Table name: academy_transfer_detections
#
#  id                                                                       :bigint           not null, primary key
#  confidence(LLM-judge confidence 0..1; only records ≥0.75 are persisted) :decimal(3, 2)    not null
#  detected_at                                                              :datetime         not null
#  evidence_excerpt(Snippet of the kid's message that triggered detection)  :text
#  created_at                                                               :datetime         not null
#  updated_at                                                               :datetime         not null
#  from_concept_id                                                          :bigint           not null
#  learner_id(Learner value-object id (no FK))                              :bigint           not null
#  message_id                                                               :bigint           not null
#  to_concept_id                                                            :bigint           not null
#
# Indexes
#
#  idx_academy_transfer_detections_from_concept     (from_concept_id)
#  idx_academy_transfer_detections_learner_time     (learner_id,detected_at)
#  idx_academy_transfer_detections_to_concept       (to_concept_id)
#  index_academy_transfer_detections_on_message_id  (message_id)
#
# Foreign Keys
#
#  fk_rails_...  (from_concept_id => academy_concepts.id)
#  fk_rails_...  (message_id => academy_messages.id)
#  fk_rails_...  (to_concept_id => academy_concepts.id)
#
  # LLM judge. This event drives Pokedex level-up to `mastered`.
  class TransferDetection < ApplicationRecord
    self.table_name = "academy_transfer_detections"

    belongs_to :from_concept, class_name: "Academy::Concept"
    belongs_to :to_concept,   class_name: "Academy::Concept"
    belongs_to :message,      class_name: "Academy::Message"

    MIN_CONFIDENCE = 0.75

    validates :learner_id, presence: true
    validates :confidence, presence: true,
              numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
    validates :detected_at, presence: true
    validate  :concepts_must_differ

    scope :for_learner, ->(id) { where(learner_id: id) }
    scope :recent_first, -> { order(detected_at: :desc) }
    scope :high_confidence, -> { where(confidence: MIN_CONFIDENCE..) }

    private

    def concepts_must_differ
      return if from_concept_id.nil? || to_concept_id.nil?
      return if from_concept_id != to_concept_id

      errors.add(:to_concept_id, "must differ from from_concept_id")
    end
  end
end

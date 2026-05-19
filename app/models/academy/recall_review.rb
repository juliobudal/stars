# frozen_string_literal: true

module Academy
  # Spaced-repetition review tied to a DiscoveryCard. The kid is asked to
  # re-apply the sacada in a new situation. Streak grows on success;
  # interval doubles roughly via the SM-2 lite ladder.
  #
# == Schema Information
#
# Table name: academy_recall_reviews
#
#  id                                                                  :bigint           not null, primary key
#  due_at                                                              :datetime         not null
#  interval_days                                                       :integer          default(1), not null
#  last_reviewed_at                                                    :datetime
#  streak(Consecutive successful recalls (0 means fresh / just reset)) :integer          default(0), not null
#  created_at                                                          :datetime         not null
#  updated_at                                                          :datetime         not null
#  card_id                                                             :bigint           not null
#  learner_id                                                          :bigint           not null
#
# Indexes
#
#  idx_academy_recall_learner_due           (learner_id,due_at)
#  idx_academy_recall_unique                (learner_id,card_id) UNIQUE
#  index_academy_recall_reviews_on_card_id  (card_id)
#
# Foreign Keys
#
#  fk_rails_...  (card_id => academy_discovery_cards.id)
#
  # One review per (learner, card). Created when the card is minted.
  class RecallReview < ApplicationRecord
    self.table_name = "academy_recall_reviews"

    belongs_to :card, class_name: "Academy::DiscoveryCard"

    validates :learner_id, presence: true
    validates :learner_id, uniqueness: { scope: :card_id }
    validates :interval_days, numericality: { greater_than: 0 }

    scope :for_learner, ->(learner_id) { where(learner_id: learner_id) }
    scope :due, ->(at: Time.current) { where(due_at: ..at).order(:due_at) }
  end
end

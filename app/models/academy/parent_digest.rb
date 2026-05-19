# frozen_string_literal: true

module Academy
  # Weekly "Notícias da expedição" digest mailed to parents. Pre-rendered
  # payload is stored so the parent dashboard can re-display historical
# == Schema Information
#
# Table name: academy_parent_digests
#
#  id                                                                                                      :bigint           not null, primary key
#  composed_at                                                                                             :datetime         not null
#  delivered_at                                                                                            :datetime
#  opened_at                                                                                               :datetime
#  payload(Pre-rendered blocks: {patterns_discovered, biggest_reveal, conversation_starter, kid_sent_you}) :jsonb            not null
#  week_starting(Monday of the digest's week (timezone-normalized))                                        :date             not null
#  created_at                                                                                              :datetime         not null
#  updated_at                                                                                              :datetime         not null
#  learner_id(Learner value-object id (no FK))                                                             :bigint           not null
#  parent_id(Parent profile id (no FK — module isolation))                                                :bigint           not null
#
# Indexes
#
#  idx_academy_parent_digests_parent_time  (parent_id,composed_at)
#  idx_academy_parent_digests_unique       (learner_id,week_starting) UNIQUE
#
  # weeks and analytics can audit content shown.
  class ParentDigest < ApplicationRecord
    self.table_name = "academy_parent_digests"

    PAYLOAD_BLOCKS = %w[
      patterns_discovered
      biggest_reveal
      conversation_starter
      kid_sent_you
    ].freeze

    validates :learner_id, presence: true
    validates :parent_id, presence: true
    validates :week_starting, presence: true
    validates :composed_at, presence: true
    validates :learner_id, uniqueness: { scope: :week_starting }

    scope :for_parent,  ->(id) { where(parent_id: id) }
    scope :for_learner, ->(id) { where(learner_id: id) }
    scope :recent_first, -> { order(composed_at: :desc) }
    scope :delivered, -> { where.not(delivered_at: nil) }

    def opened?    = opened_at.present?
    def delivered? = delivered_at.present?

    def block(name)
      payload.fetch(name.to_s, nil)
    end
  end
end

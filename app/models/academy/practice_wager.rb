# frozen_string_literal: true

module Academy
  # v4 replacement for ChallengeReport. The Guide poses a numeric wager at
  # the end of a discovery mission; the learner reports actual count D+1;
  # the parent (optionally) confirms. There is no win/lose — the delta is
# == Schema Information
#
# Table name: academy_practice_wagers
#
#  id                                                                      :bigint           not null, primary key
#  guide_bet_count(The Guide's numeric wager (extracted from LLM payload)) :integer          not null
#  learner_actual_count(What the kid reports D+1 — nil until reported)    :integer
#  learner_note(Optional short note from the kid alongside the count)      :text
#  observed_at                                                             :datetime
#  parent_observation(seen_match | seen_higher | seen_lower | skip)        :string
#  reported_at                                                             :datetime
#  created_at                                                              :datetime         not null
#  updated_at                                                              :datetime         not null
#  learner_id(Learner value-object id (no FK))                             :bigint           not null
#  mission_id                                                              :bigint           not null
#
# Indexes
#
#  idx_academy_practice_wagers_learner_reported  (learner_id,reported_at)
#  idx_academy_practice_wagers_unique            (learner_id,mission_id) UNIQUE
#  index_academy_practice_wagers_on_mission_id   (mission_id)
#
# Foreign Keys
#
#  fk_rails_...  (mission_id => academy_missions.id)
#
  # conversation material in the next turn.
  class PracticeWager < ApplicationRecord
    self.table_name = "academy_practice_wagers"

    belongs_to :mission, class_name: "Academy::Mission"

    PARENT_OBSERVATIONS = %w[seen_match seen_higher seen_lower skip].freeze

    validates :learner_id, presence: true
    validates :guide_bet_count, presence: true,
              numericality: { only_integer: true, greater_than: 0 }
    validates :parent_observation, inclusion: { in: PARENT_OBSERVATIONS },
              allow_nil: true
    validates :learner_id, uniqueness: { scope: :mission_id }

    scope :for_learner, ->(id) { where(learner_id: id) }
    scope :pending,  -> { where(reported_at: nil) }
    scope :reported, -> { where.not(reported_at: nil) }

    def reported? = reported_at.present?

    def delta
      return nil unless reported? && learner_actual_count

      (guide_bet_count - learner_actual_count).abs
    end
  end
end

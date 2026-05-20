# frozen_string_literal: true

# == Schema Information
#
# Table name: academy_lightning_round_runs
#
#  id              :bigint           not null, primary key
#  learner_id      :bigint           not null
#  total_questions :integer          not null
#  correct_count   :integer          not null, default(0)
#  elapsed_seconds :integer
#  tier            :string           not null
#  concept_ids     :jsonb            not null, default([])
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
module Academy
  class LightningRoundRun < ApplicationRecord
    self.table_name = "academy_lightning_round_runs"

    TIERS = %w[perfect strong gentle].freeze
    CHAMPION_WINDOW = 7.days
    CHAMPION_MIN_RUNS = 4
    CHAMPION_MIN_HITS_PER_RUN = 4

    validates :learner_id, :total_questions, :tier, presence: true
    validates :tier, inclusion: { in: TIERS }

    scope :for_learner, ->(learner_id) { where(learner_id: learner_id) }
    scope :recent,      -> { order(created_at: :desc) }
    scope :in_window,   ->(window = CHAMPION_WINDOW) { where(created_at: window.ago..) }

    # The kid is a "Lightning Champion" if they ran the round at least
    # CHAMPION_MIN_RUNS times in the past CHAMPION_WINDOW with at least
    # CHAMPION_MIN_HITS_PER_RUN correct each time.
    def self.champion?(learner_id)
      for_learner(learner_id).in_window
        .where("correct_count >= ?", CHAMPION_MIN_HITS_PER_RUN)
        .count >= CHAMPION_MIN_RUNS
    end
  end
end

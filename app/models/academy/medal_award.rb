# frozen_string_literal: true

# == Schema Information
#
# Table name: academy_medal_awards
#
#  id         :bigint           not null, primary key
#  awarded_at :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  learner_id :bigint           not null
#  medal_id   :bigint           not null
#
# Indexes
#
#  idx_academy_medal_awards_learner        (learner_id)
#  idx_academy_medal_awards_unique         (learner_id,medal_id) UNIQUE
#  index_academy_medal_awards_on_medal_id  (medal_id)
#
# Foreign Keys
#
#  fk_rails_...  (medal_id => academy_medals.id)
#
module Academy
  class MedalAward < ApplicationRecord
    self.table_name = "academy_medal_awards"

    belongs_to :medal, class_name: "Academy::Medal"

    validates :learner_id, :awarded_at, presence: true
    validates :learner_id, uniqueness: { scope: :medal_id }

    scope :for_learner, ->(id) { where(learner_id: id) }
    scope :recent,      -> { order(awarded_at: :desc) }
  end
end

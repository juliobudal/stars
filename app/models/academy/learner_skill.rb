# frozen_string_literal: true

module Academy
# == Schema Information
#
# Table name: academy_learner_skills
#
#  id            :bigint           not null, primary key
#  last_event_at :datetime
#  score         :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  learner_id    :bigint           not null
#  skill_id      :bigint           not null
#
# Indexes
#
#  idx_academy_learner_skills_learner        (learner_id)
#  idx_academy_learner_skills_unique         (learner_id,skill_id) UNIQUE
#  index_academy_learner_skills_on_skill_id  (skill_id)
#
# Foreign Keys
#
#  fk_rails_...  (skill_id => academy_skills.id)
#
  # Running score for one (learner, skill). Updated by Skills::Award.
  class LearnerSkill < ApplicationRecord
    self.table_name = "academy_learner_skills"

    belongs_to :skill, class_name: "Academy::Skill"

    validates :learner_id, presence: true
    validates :learner_id, uniqueness: { scope: :skill_id }
  end
end

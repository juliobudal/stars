# frozen_string_literal: true

module Academy
  # Join table linking a mission to a skill it exercises. Weight is 1 for
# == Schema Information
#
# Table name: academy_aula_skills
#
#  id                                                                              :bigint           not null, primary key
#  weight(How much this skill is exercised by this aula (1=co-primary, 2=primary)) :integer          default(1), not null
#  created_at                                                                      :datetime         not null
#  updated_at                                                                      :datetime         not null
#  mission_id                                                                      :bigint           not null
#  skill_id                                                                        :bigint           not null
#
# Indexes
#
#  idx_academy_aula_skills_unique           (mission_id,skill_id) UNIQUE
#  index_academy_aula_skills_on_mission_id  (mission_id)
#  index_academy_aula_skills_on_skill_id    (skill_id)
#
# Foreign Keys
#
#  fk_rails_...  (mission_id => academy_missions.id)
#  fk_rails_...  (skill_id => academy_skills.id)
#
  # secondary, 2 for primary (only 1 row per (mission, skill)).
  class AulaSkill < ApplicationRecord
    self.table_name = "academy_aula_skills"

    belongs_to :mission, class_name: "Academy::Mission"
    belongs_to :skill,   class_name: "Academy::Skill"

    validates :mission_id, uniqueness: { scope: :skill_id }
    validates :weight, numericality: { greater_than: 0 }
  end
end

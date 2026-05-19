# frozen_string_literal: true

# == Schema Information
#
# Table name: academy_medals
#
#  id          :bigint           not null, primary key
#  description :string
#  icon        :string           default("medal")
#  kind        :integer          default("mission_completed"), not null
#  name        :string           not null
#  slug        :string           not null
#  threshold   :integer          default(0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  mission_id  :bigint
#  subject_id  :bigint
#
# Indexes
#
#  index_academy_medals_on_mission_id  (mission_id)
#  index_academy_medals_on_slug        (slug) UNIQUE
#  index_academy_medals_on_subject_id  (subject_id)
#
# Foreign Keys
#
#  fk_rails_...  (mission_id => academy_missions.id)
#  fk_rails_...  (subject_id => academy_subjects.id)
#
module Academy
  class Medal < ApplicationRecord
    self.table_name = "academy_medals"

    belongs_to :subject, class_name: "Academy::Subject", optional: true
    belongs_to :mission, class_name: "Academy::Mission", optional: true
    has_many :awards, class_name: "Academy::MedalAward",
             foreign_key: :medal_id, dependent: :destroy

    enum :kind, {
      mission_completed: 0,
      mission_perfect:   1,
      subject_apprentice: 2,
      subject_adept:      3,
      subject_master:     4
    }

    validates :slug, :name, presence: true
    validates :slug, uniqueness: true

    def awarded_to?(learner_id)
      awards.where(learner_id: learner_id).exists?
    end
  end
end

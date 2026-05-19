# frozen_string_literal: true

module Academy
  # One of 9 fixed skills tracked in the radar. Seeded once and never deleted.
# == Schema Information
#
# Table name: academy_skills
#
#  id                                                 :bigint           not null, primary key
#  icon                                               :string           default("sparkle"), not null
#  name                                               :string           not null
#  position                                           :integer          default(0), not null
#  short_label(Kid-facing 1-word label for the radar) :string
#  slug                                               :string           not null
#  created_at                                         :datetime         not null
#  updated_at                                         :datetime         not null
#
# Indexes
#
#  index_academy_skills_on_slug  (slug) UNIQUE
#
  # See db/seeds/academy_skills.rb.
  class Skill < ApplicationRecord
    self.table_name = "academy_skills"

    SLUGS = %w[
      disciplina curiosidade autonomia foco saude
      comunicacao logica responsabilidade criatividade
    ].freeze

    has_many :aula_skills, class_name: "Academy::AulaSkill",
             foreign_key: :skill_id, dependent: :destroy
    has_many :missions, through: :aula_skills, class_name: "Academy::Mission"
    has_many :learner_skills, class_name: "Academy::LearnerSkill",
             foreign_key: :skill_id, dependent: :destroy

    validates :slug, :name, presence: true
    validates :slug, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }

    scope :ordered, -> { order(:position, :id) }

    def to_param = slug
  end
end

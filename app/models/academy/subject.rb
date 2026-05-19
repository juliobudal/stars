# frozen_string_literal: true

# == Schema Information
#
# Table name: academy_subjects
#
#  id                                            :bigint           not null, primary key
#  active                                        :boolean          default(TRUE), not null
#  angle(Pedagogical angle the LLM should adopt) :text
#  color                                         :string           default("var(--c-primary)")
#  icon                                          :string           default("sparkle")
#  name                                          :string           not null
#  position                                      :integer          default(0), not null
#  slug                                          :string           not null
#  tagline                                       :string
#  created_at                                    :datetime         not null
#  updated_at                                    :datetime         not null
#
# Indexes
#
#  index_academy_subjects_on_slug  (slug) UNIQUE
#
module Academy
  class Subject < ApplicationRecord
    self.table_name = "academy_subjects"

    has_many :missions, -> { order(:order_in_subject) },
             class_name: "Academy::Mission",
             foreign_key: :subject_id,
             dependent: :restrict_with_error,
             inverse_of: :subject
    has_many :trails, -> { order(:position) },
             class_name: "Academy::Trail",
             foreign_key: :subject_id,
             dependent: :restrict_with_error,
             inverse_of: :subject
    has_many :medals, class_name: "Academy::Medal", foreign_key: :subject_id, dependent: :restrict_with_error

    validates :slug, :name, presence: true
    validates :slug, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }

    scope :active, -> { where(active: true).order(:position, :id) }

    def to_param = slug

    # Aggregate progress for a learner: ratio of mastered missions in subject.
    def mastery_ratio_for(learner_id)
      total = missions.where(active: true).count
      return 0.0 if total.zero?

      done = MissionProgress.where(learner_id: learner_id, mission_id: missions.select(:id))
                            .where(status: %i[completed mastered]).count
      done.to_f / total
    end

    # Skill snapshot for the area. Used by the kid UI to render a level-up
    # gamification tile ("Inteligência Nv. 3 — +5 pílulas pra Mestre").
    # Levels = number of pílulas completed (1 pílula = 1 level).
    Skill = Data.define(:level, :total, :mastered, :ratio, :tier) do
      def percent = (ratio * 100).round
      def to_master = total - level
      def tier_label
        { master: "Mestre", adept: "Adepto", apprentice: "Aprendiz", novato: "Novato" }[tier]
      end
    end

    def skill_for(learner_id)
      mission_ids = missions.active.pluck(:id)
      total = mission_ids.size
      return Skill.new(level: 0, total: 0, mastered: 0, ratio: 0.0, tier: :novato) if total.zero?

      progresses = MissionProgress.where(learner_id: learner_id, mission_id: mission_ids)
      done     = progresses.where(status: %i[completed mastered]).count
      mastered = progresses.where(status: :mastered).count
      ratio    = done.to_f / total
      tier =
        if ratio >= 1.0    then :master
        elsif ratio >= 0.6 then :adept
        elsif ratio >= 0.3 then :apprentice
        else :novato
        end
      Skill.new(level: done, total: total, mastered: mastered, ratio: ratio, tier: tier)
    end
  end
end

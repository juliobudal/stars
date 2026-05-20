# frozen_string_literal: true

module Academy
  # A narrative arc inside a Subject — 4–8 missions ("aulas") with one
  # overarching "arc hook" the kid sees on the trail card. The trail is
  # the v2 layer between Subject and Mission introduced to replace the
  # == Schema Information
  #
  # Table name: academy_trails
  #
  #  id                                                :bigint           not null, primary key
  #  active                                            :boolean          default(TRUE), not null
  #  arc_hook(One-line gancho for the whole trail arc) :string
  #  position                                          :integer          default(0), not null
  #  slug                                              :string           not null
  #  title                                             :string           not null
  #  created_at                                        :datetime         not null
  #  updated_at                                        :datetime         not null
  #  subject_id                                        :bigint           not null
  #
  # Indexes
  #
  #  idx_academy_trails_subject_position  (subject_id,position)
  #  idx_academy_trails_subject_slug      (subject_id,slug) UNIQUE
  #  index_academy_trails_on_subject_id   (subject_id)
  #
  # Foreign Keys
  #
  #  fk_rails_...  (subject_id => academy_subjects.id)
  #
  # flat "list of 10 missions" UX from v1.
  class Trail < ApplicationRecord
    self.table_name = "academy_trails"

    belongs_to :subject, class_name: "Academy::Subject", inverse_of: :trails
    has_many :missions, -> { order(:position_in_trail) },
             class_name: "Academy::Mission",
             foreign_key: :trail_id,
             dependent: :nullify,
             inverse_of: :trail

    validates :slug, :title, presence: true
    validates :slug, uniqueness: { scope: :subject_id }, format: { with: /\A[a-z0-9-]+\z/ }

    scope :active, -> { where(active: true).order(:position, :id) }

    def to_param = slug

    def progress_for(learner_id)
      mission_ids = missions.where(active: true).pluck(:id)
      return { total: 0, done: 0, mastered: 0, ratio: 0.0 } if mission_ids.empty?

      progresses = MissionProgress.where(learner_id: learner_id, mission_id: mission_ids)
      done     = progresses.where(status: %i[completed mastered]).count
      mastered = progresses.where(status: :mastered).count
      total    = mission_ids.size
      { total: total, done: done, mastered: mastered, ratio: done.to_f / total }
    end
  end
end

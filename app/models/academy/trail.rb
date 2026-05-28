# frozen_string_literal: true

module Academy
  # An ordered theme ("Seu cérebro mente pra você") that holds a short sequence
  # of curated lessons. Trails are the only navigation layer the kid sees —
  # there is no Subject/area tier in the redesign.
  class Trail < ApplicationRecord
    self.table_name = "academy_trails"

    has_many :lessons,
             -> { order(:position) },
             class_name: "Academy::Lesson",
             dependent: :destroy,
             inverse_of: :trail

    validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
    validates :title, presence: true
    validates :position, presence: true

    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(:position, :id) }

    def to_param = slug

    # Batch progress for many trails — one query. Returns
    # { trail_id => { total:, done: } } counting active lessons completed by the learner.
    def self.progress_for(learner_id, trails:)
      trail_ids = trails.map(&:id)
      return {} if trail_ids.empty?

      totals = Lesson.active.where(trail_id: trail_ids).group(:trail_id).count
      done = LessonProgress
               .joins(:lesson)
               .where(learner_id: learner_id, academy_lessons: { trail_id: trail_ids, active: true })
               .completed
               .group("academy_lessons.trail_id").count

      trail_ids.index_with do |tid|
        { total: totals[tid] || 0, done: done[tid] || 0 }
      end
    end
  end
end

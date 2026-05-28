# frozen_string_literal: true

module Academy
  # Per-learner completion of a lesson. `learner_id` is a no-FK bigint
  # (module isolation). One row per (learner, lesson); presence of
  # `completed_at` means the pill was finished.
  class LessonProgress < ApplicationRecord
    self.table_name = "academy_lesson_progresses"

    belongs_to :lesson, class_name: "Academy::Lesson"

    validates :learner_id, presence: true
    validates :lesson_id, uniqueness: { scope: :learner_id }

    scope :for_learner, ->(learner_id) { where(learner_id: learner_id) }
    scope :completed, -> { where.not(completed_at: nil) }

    def completed? = completed_at.present?
  end
end

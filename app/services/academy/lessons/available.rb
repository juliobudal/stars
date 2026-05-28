# frozen_string_literal: true

module Academy
  module Lessons
    # Resolves the unlock status of every active lesson in a trail for a
    # learner. Sequential rule: lesson N unlocks once N-1 is completed; the
    # first lesson is always available.
    #
    # Returns ok([{ lesson:, status: }, ...]) ordered by position, where
    # status is :completed | :available | :locked.
    class Available < ApplicationService
      def initialize(learner:, trail:)
        @learner = learner
        @trail = trail
      end

      def call
        lessons = @trail.lessons.active.ordered.to_a
        completed = ::Academy::LessonProgress
                      .for_learner(@learner.id).completed
                      .where(lesson_id: lessons.map(&:id))
                      .pluck(:lesson_id).to_set

        next_assigned = false
        rows = lessons.map do |lesson|
          status =
            if completed.include?(lesson.id)
              :completed
            elsif !next_assigned
              next_assigned = true
              :available
            else
              :locked
            end
          { lesson: lesson, status: status }
        end

        ok(rows)
      end
    end
  end
end

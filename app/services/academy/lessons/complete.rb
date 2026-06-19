# frozen_string_literal: true

module Academy
  module Lessons
    # Marks a lesson complete for a learner (idempotent — the first completion
    # timestamp is preserved on replay). Records the check answer when the
    # lesson has a check and a choice was submitted.
    #
    # Returns ok(progress:, next_lesson:, check_correct:).
    class Complete < ApplicationService
      def initialize(learner:, lesson:, check_choice: nil)
        @learner = learner
        @lesson = lesson
        @check_choice = check_choice.nil? ? nil : check_choice.to_i
      end

      def call
        correct = evaluate_check

        progress = ::Academy::LessonProgress.find_or_initialize_by(
          learner_id: @learner.id, lesson_id: @lesson.id
        )
        progress.completed_at ||= Time.current
        unless correct.nil?
          progress.check_choice = @check_choice
          progress.check_correct = correct
        end
        progress.save!

        ok(progress: progress, next_lesson: next_lesson, check_correct: correct)
      rescue ActiveRecord::RecordNotUnique
        # Concurrent double-submit: the unique index on (learner_id, lesson_id)
        # already protected the row — re-read the winning progress and return
        # the same idempotent result instead of surfacing a 500.
        progress = ::Academy::LessonProgress.find_by!(
          learner_id: @learner.id, lesson_id: @lesson.id
        )
        ok(progress: progress, next_lesson: next_lesson, check_correct: correct)
      end

      private

      def evaluate_check
        return nil unless @lesson.check? && !@check_choice.nil?

        @check_choice == @lesson.check["answer_index"].to_i
      end

      def next_lesson
        @lesson.trail.lessons.active
               .where("position > ?", @lesson.position)
               .order(:position).first
      end
    end
  end
end

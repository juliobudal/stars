# frozen_string_literal: true

# A single pill (lesson). #show renders the curated content; the step-by-step
# reveal (enigma → clues → revelation → check → hook) is driven client-side.
# #complete persists progress and points the kid at the next lesson.
class Kid::Academy::LessonsController < Kid::Academy::BaseController
  before_action :load_trail_and_lesson

  def show
    @locked = lesson_locked?
    redirect_to(kid_academy_trail_path(@trail), alert: "Termine a aula anterior primeiro.") and return if @locked

    @completed = ::Academy::LessonProgress
                   .for_learner(current_learner.id).completed
                   .exists?(lesson_id: @lesson.id)
    @guide_enabled = ::Academy.configured?
  end

  def complete
    result = ::Academy::Lessons::Complete.call(
      learner: current_learner,
      lesson: @lesson,
      check_choice: params[:check_choice]
    )

    @next_lesson = result.data[:next_lesson]
    redirect_to(@next_lesson ? kid_academy_trail_lesson_path(@trail, @next_lesson)
                             : kid_academy_trail_path(@trail))
  end

  private

  def load_trail_and_lesson
    @trail = ::Academy::Trail.active.find_by!(slug: params[:trail_slug])
    @lesson = @trail.lessons.active.find_by!(slug: params[:slug])
  end

  def lesson_locked?
    rows = ::Academy::Lessons::Available.call(learner: current_learner, trail: @trail).data
    rows.find { |r| r[:lesson].id == @lesson.id }&.fetch(:status) == :locked
  end
end

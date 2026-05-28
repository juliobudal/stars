# frozen_string_literal: true

# Academy home + trail view. The home lists active trails with progress and
# the next lesson to do; the trail view lists its lessons with unlock status.
class Kid::Academy::TrailsController < Kid::Academy::BaseController
  def index
    @trails = ::Academy::Trail.active.ordered.includes(:lessons).to_a
    @progress = ::Academy::Trail.progress_for(current_learner.id, trails: @trails)
    @next_by_trail = @trails.index_with { |trail| next_lesson_for(trail) }
  end

  def show
    @trail = ::Academy::Trail.active.find_by!(slug: params[:slug])
    @rows = ::Academy::Lessons::Available.call(learner: current_learner, trail: @trail).data
  end

  private

  # The first non-completed (available) lesson in the trail, or nil if done.
  def next_lesson_for(trail)
    rows = ::Academy::Lessons::Available.call(learner: current_learner, trail: trail).data
    rows.find { |r| r[:status] == :available }&.fetch(:lesson)
  end
end

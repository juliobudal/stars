# frozen_string_literal: true

# Parent-facing read-only listing of recent lens journeys per kid in the
# family. Shows last N missions with the angles (lens types) the kid
# atravessed and whether the mission closed with a transfer. Reuses the
# existing Pokédex color tokens for visual consistency.
class Parent::Academy::JourneysController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  layout "parent"

  def index
    @kids = current_family.profiles.where(role: :child).order(:name)
    @selected_kid = pick_kid

    if @selected_kid
      @recent_progresses = ::Academy::MissionProgress
                             .where(learner_id: @selected_kid.id)
                             .includes(mission: %i[subject concept])
                             .order(updated_at: :desc)
                             .limit(20)

      @visits_by_progress = ::Academy::LearnerLensVisit
                              .where(mission_progress_id: @recent_progresses.map(&:id))
                              .order(:ordering_position)
                              .group_by(&:mission_progress_id)
    end
  end

  private

  def pick_kid
    @kids.find { |k| k.id.to_s == params[:kid].to_s } || @kids.first
  end
end

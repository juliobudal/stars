# frozen_string_literal: true

class Kid::Academy::TrailsController < Kid::Academy::BaseController
  def show
    @subject = ::Academy::Subject.active.find_by!(slug: params[:subject_id])
    @trail   = @subject.trails.active.find_by!(slug: params[:id])
    @missions = @trail.missions.where(active: true).order(:position_in_trail).to_a

    @progresses = ::Academy::MissionProgress
                    .where(learner_id: current_learner.id, mission_id: @missions.map(&:id))
                    .index_by(&:mission_id)
    @cards = ::Academy::DiscoveryCard
               .where(learner_id: current_learner.id, mission_id: @missions.map(&:id))
               .index_by(&:mission_id)
  end
end

class Kid::DashboardController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout 'kid'

  def index
    @profile_tasks = ProfileTask.pending.where(profile: current_profile).includes(:global_task)
    @awaiting_tasks = ProfileTask.awaiting_approval.where(profile: current_profile).includes(:global_task)
    @completed_today = ProfileTask.approved.where(profile: current_profile).includes(:global_task)
  end
end

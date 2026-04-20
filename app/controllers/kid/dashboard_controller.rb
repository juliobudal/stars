class Kid::DashboardController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout 'kid'

  def index
    @profile_tasks = current_profile.profile_tasks.pending
    @awaiting_tasks = current_profile.profile_tasks.awaiting_approval
    @completed_today = current_profile.profile_tasks.approved
  end
end

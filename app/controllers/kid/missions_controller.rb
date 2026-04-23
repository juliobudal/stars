class Kid::MissionsController < ApplicationController
  include Authenticatable
  before_action :require_child!

  def complete
    @profile_task = ProfileTask.includes(:global_task).pending.where(profile: current_profile).find(params[:id])
    @profile_task.awaiting_approval!
    
    respond_to do |format|
      format.html { redirect_to kid_root_path, notice: "Missão enviada para aprovação! 🚀" }
      format.turbo_stream
    end
  end
end

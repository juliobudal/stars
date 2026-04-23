class Kid::MissionsController < ApplicationController
  include Authenticatable
  before_action :require_child!

  def complete
    @profile_task = ProfileTask.includes(:global_task).pending.where(profile: current_profile).find(params[:id])
    result = Tasks::CompleteService.new(profile_task: @profile_task, proof_photo: mission_params[:proof_photo]).call

    if result.success?
      respond_to do |format|
        format.html { redirect_to kid_root_path, notice: "Missão enviada para aprovação! 🚀" }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to kid_root_path, alert: result.error }
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("flash",
            html: "<div data-controller='flash' data-flash-dismiss-after-value='3500' class='pointer-events-auto flex items-center gap-2 px-5 py-3 rounded-full text-white font-extrabold text-[15px] shadow-lift animate-popIn' style='background-color: var(--c-red-dark);'>#{result.error}</div>".html_safe),
            status: :unprocessable_entity
        end
      end
    end
  end

  private

  def mission_params
    params.permit(:proof_photo)
  end
end

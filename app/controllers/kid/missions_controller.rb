class Kid::MissionsController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout "kid"

  def new
    @categories = current_profile.family.categories.order(:name)
  end

  def create
    result = Tasks::CreateCustomService.call(profile: current_profile, params: custom_params)

    if result.success?
      redirect_to kid_root_path, notice: "Missão enviada para aprovação dos pais! 🚀"
    else
      @categories = current_profile.family.categories.order(:name)
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  def complete
    @profile_task = ProfileTask.includes(:global_task, profile: :family).pending.where(profile: current_profile).find(params[:id])
    result = Tasks::CompleteService.new(
      profile_task: @profile_task,
      proof_photo: complete_params[:proof_photo],
      submission_comment: complete_params[:submission_comment]
    ).call

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
            html: "<div data-controller='flash' data-flash-dismiss-after-value='3500' class='pointer-events-auto flex items-center gap-2 px-5 py-3 rounded-full text-white font-extrabold text-[15px] shadow-lift anim-pop-in' style='background-color: var(--c-red-dark);'>#{ERB::Util.html_escape(result.error)}</div>".html_safe),
            status: :unprocessable_entity
        end
      end
    end
  end

  private

  def complete_params
    params.permit(:proof_photo, :submission_comment)
  end

  def custom_params
    params.require(:profile_task).permit(:custom_title, :custom_description, :custom_points, :custom_category_id, :submission_comment, :proof_photo)
  end
end

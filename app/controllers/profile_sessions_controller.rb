class ProfileSessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create, :destroy ], raise: false

  before_action :require_family!

  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  def new
    @profiles = current_family.profiles.order(:created_at)
    @selected_profile = @profiles.find_by(id: params[:profile_id]) if params[:profile_id]
  end

  def create
    profile = current_family.profiles.find(params[:profile_id])
    if profile.authenticate_pin(params[:pin])
      family_id = cookies.signed[:family_id]
      reset_session
      cookies.signed.permanent[:family_id] = { value: family_id, httponly: true, same_site: :lax }
      session[:profile_id] = profile.id
      redirect_to profile.parent? ? parent_root_path : kid_root_path
    else
      flash.now[:alert] = "PIN incorreto."
      @profiles = current_family.profiles.order(:created_at)
      @selected_profile = profile
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:profile_id)
    redirect_to new_profile_session_path, notice: "Perfil desconectado."
  end

  private

  def current_family
    @current_family ||= Family.find_by(id: cookies.signed[:family_id])
  end
  helper_method :current_family

  def require_family!
    redirect_to new_family_session_path, alert: "Faça login na família." unless current_family
  end
end

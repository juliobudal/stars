class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create, :destroy ], raise: false

  def index
    # Assumindo apenas uma família para MVP
    @family = Family.includes(:profiles).first
    @profiles = @family&.profiles || []
  end

  def create
    @profile = Profile.find(params[:profile_id])
    session[:profile_id] = @profile.id

    if @profile.parent?
      redirect_to parent_root_path
    else
      redirect_to kid_root_path
    end
  end

  def destroy
    session[:profile_id] = nil
    redirect_to root_path, notice: "Sessão encerrada com sucesso."
  end
end

class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :destroy], raise: false

  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  def index
    @family = Family.includes(:profiles).first
    @profiles = @family&.profiles&.where(role: :child) || []
  end

  def create
    if params[:email].present? && params[:password].present?
      profile = Profile.find_by(email: params[:email].to_s.downcase)
      if profile&.authenticate(params[:password])
        reset_session
        session[:profile_id] = profile.id
        redirect_to profile.parent? ? parent_root_path : kid_root_path
      else
        flash[:alert] = "Email ou senha incorretos."
        redirect_to root_path
      end
    elsif params[:profile_id].present?
      profile = Profile.find(params[:profile_id])
      if profile.parent?
        flash[:alert] = "Pais devem fazer login com email e senha."
        redirect_to root_path
      else
        reset_session
        session[:profile_id] = profile.id
        redirect_to kid_root_path
      end
    else
      flash[:alert] = "Credenciais inválidas."
      redirect_to root_path
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Sessão encerrada com sucesso."
  end
end

class InvitationsController < ApplicationController
  rate_limit to: 5, within: 15.minutes, only: :accept

  def show
    @invitation = ProfileInvitation.active.find_by(token: params[:token])
    raise ActiveRecord::RecordNotFound unless @invitation
  end

  def accept
    @invitation = ProfileInvitation.active.find_by(token: params[:token])
    raise ActiveRecord::RecordNotFound unless @invitation

    name = params[:name].to_s.strip
    password = params[:password].to_s
    password_confirmation = params[:password_confirmation].to_s

    if name.blank? || password.blank?
      flash.now[:alert] = "Nome e senha são obrigatórios."
      render :show, status: :unprocessable_entity
      return
    end

    if password != password_confirmation
      flash.now[:alert] = "As senhas não coincidem."
      render :show, status: :unprocessable_entity
      return
    end

    begin
      new_profile = @invitation.accept!(name: name, password: password)
      reset_session
      session[:profile_id] = new_profile.id
      redirect_to parent_root_path, notice: "Bem-vindo à família #{@invitation.family.name}!"
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.message
      render :show, status: :unprocessable_entity
    end
  end
end

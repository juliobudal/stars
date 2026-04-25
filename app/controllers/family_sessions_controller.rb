class FamilySessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create, :destroy ], raise: false

  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  def new
    if (family_id = cookies.signed[:family_id])
      if Family.exists?(id: family_id)
        redirect_to new_profile_session_path and return
      else
        cookies.delete(:family_id)
        reset_session
      end
    end
  end

  def create
    family = Family.find_by(email: params[:email].to_s.downcase.strip)
    if family&.authenticate(params[:password])
      reset_session
      cookies.signed.permanent[:family_id] = { value: family.id, httponly: true, same_site: :lax }
      redirect_to new_profile_session_path
    else
      flash.now[:alert] = "Email ou senha inválidos."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    cookies.delete(:family_id)
    reset_session
    redirect_to new_family_session_path, notice: "Sessão da família encerrada."
  end
end

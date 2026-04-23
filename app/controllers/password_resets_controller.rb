class PasswordResetsController < ApplicationController
  rate_limit to: 5, within: 15.minutes, only: :create, with: -> { head :too_many_requests }

  def new
  end

  def create
    profile = Profile.find_by(email: params[:email].to_s.downcase)
    if profile
      token = profile.signed_id(purpose: :password_reset, expires_in: 2.hours)
      PasswordMailer.reset(profile, token).deliver_later
    end
    flash[:notice] = "Se esse email estiver cadastrado, você receberá as instruções em breve."
    redirect_to root_path
  end

  def edit
    @token = params[:token]
    @profile = Profile.find_signed(@token, purpose: :password_reset)
    unless @profile
      redirect_to root_path, alert: "Link inválido ou expirado."
    end
  end

  def update
    @token = params[:token]
    @profile = Profile.find_signed(@token, purpose: :password_reset)

    unless @profile
      redirect_to root_path, alert: "Link inválido ou expirado."
      return
    end

    if @profile.update(password: params[:password], password_confirmation: params[:password_confirmation])
      reset_session
      session[:profile_id] = @profile.id
      redirect_to parent_root_path, notice: "Senha atualizada com sucesso!"
    else
      flash.now[:alert] = @profile.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end
end

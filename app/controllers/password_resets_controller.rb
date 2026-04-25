class PasswordResetsController < ApplicationController
  rate_limit to: 5, within: 15.minutes, only: :create, with: -> { head :too_many_requests }

  def new
  end

  def create
    family = Family.find_by(email: params[:email].to_s.downcase)
    if family
      token = family.generate_token_for(:password_reset)
      PasswordMailer.reset(family, token).deliver_later
    end
    flash[:notice] = "Se esse email estiver cadastrado, você receberá as instruções em breve."
    redirect_to root_path
  end

  def edit
    @token = params[:token]
    @family = Family.find_by_token_for(:password_reset, @token)
    unless @family
      redirect_to root_path, alert: "Link inválido ou expirado."
    end
  end

  def update
    @token = params[:token]
    @family = Family.find_by_token_for(:password_reset, @token)

    unless @family
      redirect_to root_path, alert: "Link inválido ou expirado."
      return
    end

    if @family.update(password: params[:password], password_confirmation: params[:password_confirmation])
      reset_session
      cookies.signed.permanent[:family_id] = { value: @family.id, httponly: true, same_site: :lax }
      redirect_to new_profile_session_path, notice: "Senha atualizada com sucesso!"
    else
      flash.now[:alert] = @family.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end
end

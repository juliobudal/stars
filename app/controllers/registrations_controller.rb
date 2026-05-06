class RegistrationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create, raise: false

  def new
    @family = Family.new
  end

  def create
    result = Auth::CreateFamily.call(registration_params)
    if result.success?
      cookies.signed.permanent[:family_id] = { value: result.data.id, httponly: true, same_site: :lax }
      redirect_to new_parent_profile_path(onboarding: true)
    else
      @family = result.data || Family.new(registration_params)
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:family).permit(:name, :email, :password)
  end
end

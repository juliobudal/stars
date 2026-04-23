class RegistrationsController < ApplicationController
  def new
    @family = Family.new
    @profile = Profile.new
  end

  def create
    @family = Family.new(name: params[:family_name])
    @profile = @family.profiles.build(
      name: params[:name],
      email: params[:email],
      password: params[:password],
      password_confirmation: params[:password_confirmation],
      role: :parent,
      confirmed_at: Time.current
    )

    ActiveRecord::Base.transaction do
      @family.save!
      @profile.save!
    end

    reset_session
    session[:profile_id] = @profile.id
    redirect_to parent_root_path, notice: "Conta criada com sucesso!"
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :new, status: :unprocessable_entity
  end
end

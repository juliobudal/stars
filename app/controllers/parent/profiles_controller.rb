class Parent::ProfilesController < ApplicationController
  include Authenticatable

  skip_before_action :require_profile!, only: [ :new, :create ], if: -> { params[:onboarding] == "true" }

  before_action :require_parent!, except: [ :new, :create ]
  before_action :require_parent_unless_onboarding!, only: [ :new, :create ]
  before_action :set_profile, only: [ :edit, :update, :destroy ]

  layout "parent"

  def index
    @profiles = current_family.profiles.child.includes(:profile_tasks).order(:name)
  end

  def new
    @profile = current_family.profiles.new(role: :child)
  end

  def create
    pin = params.dig(:profile, :pin)
    attrs = profile_params.except(:pin)
    # Onboarding always creates a parent profile (first parent on signup, additional parents on invite).
    attrs[:role] = :parent if params[:onboarding] == "true" || params[:invited] == "true"
    result = Auth::CreateProfile.call(family: current_family, params: attrs, pin: pin)
    if result.success?
      if params[:onboarding] == "true"
        session[:profile_id] = result.profile.id
        redirect_to result.profile.parent? ? parent_root_path : kid_root_path
      else
        redirect_to parent_profiles_path, notice: "Perfil criado."
      end
    else
      @profile = result.profile
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to parent_root_path, notice: "Filho atualizado com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @profile.destroy
    redirect_to parent_root_path, notice: "Perfil removido com sucesso."
  end

  def reset_pin
    profile = current_family.profiles.find(params[:id])
    result = Auth::ResetPin.call(profile: profile, new_pin: params[:pin], actor: current_profile)
    if result.success?
      redirect_to parent_settings_path, notice: "PIN redefinido."
    else
      redirect_to parent_settings_path, alert: result.error
    end
  end

  private

  def require_parent_unless_onboarding!
    return if params[:onboarding] == "true" && current_profile.nil?
    require_parent!
  end

  def set_profile
    @profile = current_family.profiles.child.find(params[:id])
  end

  def profile_params
    params.require(:profile).permit(:name, :role, :avatar, :color, :email, :pin)
  end
end

class Parent::ProfilesController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  before_action :set_profile, only: [ :edit, :update, :destroy ]

  layout "parent"

  def index
    @profiles = Profile.where(family_id: current_profile.family_id).child.includes(:profile_tasks).order(:name)
  end

  def new
    @profile = Profile.new(family_id: current_profile.family_id, role: :child)
  end

  def create
    @profile = Profile.new(profile_params.merge(family_id: current_profile.family_id, role: :child))

    if @profile.save
      redirect_to parent_root_path, notice: "Filho adicionado com sucesso!"
    else
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

  private

  def set_profile
    @profile = Profile.where(family_id: current_profile.family_id).child.find(params[:id])
  end

  def profile_params
    params.require(:profile).permit(:name, :avatar, :color)
  end
end

class Parent::GlobalTasksController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  before_action :set_global_task, only: [ :edit, :update, :destroy, :toggle_active ]

  layout "parent"

  def index
    @global_tasks = GlobalTask.where(family_id: current_profile.family_id)
                              .includes(:assigned_profiles)
                              .order(created_at: :desc)
    @kids = current_profile.family.profiles.child.order(:name)
  end

  def new
    @global_task = GlobalTask.new(family_id: current_profile.family_id)
    @kids = current_profile.family.profiles.child.order(:name)
  end

  def create
    @global_task = GlobalTask.new(global_task_params.merge(family_id: current_profile.family_id))
    if @global_task.save
      redirect_to parent_global_tasks_path, notice: "Tarefa criada com sucesso."
    else
      @kids = current_profile.family.profiles.child.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @kids = current_profile.family.profiles.child.order(:name)
  end

  def update
    if @global_task.update(global_task_params)
      redirect_to parent_global_tasks_path, notice: "Tarefa atualizada com sucesso."
    else
      @kids = current_profile.family.profiles.child.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @global_task.destroy
    redirect_to parent_global_tasks_path, notice: "Tarefa removida."
  end

  def toggle_active
    @global_task.update!(active: !@global_task.active?)
    @kids = current_profile.family.profiles.child.order(:name)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "mission_row_#{@global_task.id}",
          partial: "parent/global_tasks/mission_card",
          locals: { mission: @global_task, assigned: resolved_profiles_for(@global_task) }
        )
      end
      format.html { redirect_to parent_global_tasks_path }
    end
  end

  private

  def resolved_profiles_for(mission)
    mission.assigned_profiles.any? ? mission.assigned_profiles : @kids
  end

  def set_global_task
    @global_task = GlobalTask.where(family_id: current_profile.family_id).find(params[:id])
  end

  def global_task_params
    p = params.require(:global_task).permit(:title, :points, :category, :frequency, :active, :icon, :description,
                                             :day_of_month, :max_completions_per_period,
                                             days_of_week: [], assigned_profile_ids: [])
    p[:days_of_week]&.reject!(&:blank?)
    p[:assigned_profile_ids]&.reject!(&:blank?)
    p
  end
end

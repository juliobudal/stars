class Parent::GlobalTasksController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  before_action :set_global_task, only: [ :edit, :update, :destroy ]

  layout "parent"

  def index
    @global_tasks = GlobalTask.where(family_id: current_profile.family_id).order(created_at: :desc)
  end

  def new
    @global_task = GlobalTask.new(family_id: current_profile.family_id)
  end

  def create
    @global_task = GlobalTask.new(global_task_params.merge(family_id: current_profile.family_id))
    if @global_task.save
      redirect_to parent_global_tasks_path, notice: "Tarefa criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @global_task.update(global_task_params)
      redirect_to parent_global_tasks_path, notice: "Tarefa atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @global_task.destroy
    redirect_to parent_global_tasks_path, notice: "Tarefa removida."
  end

  private

  def set_global_task
    @global_task = GlobalTask.where(family_id: current_profile.family_id).find(params[:id])
  end

  def global_task_params
    p = params.require(:global_task).permit(:title, :points, :category, :frequency, days_of_week: [])
    p[:days_of_week]&.reject!(&:blank?)
    p
  end
end

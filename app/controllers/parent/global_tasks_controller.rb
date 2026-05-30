class Parent::GlobalTasksController < ApplicationController
  include Authenticatable
  include Duplicatable
  include TemplateAddable
  before_action :require_parent!
  before_action :set_global_task, only: [ :edit, :update, :destroy, :toggle_active, :assignment, :duplicate ]

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
      render :new, status: :unprocessable_content
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
      render :edit, status: :unprocessable_content
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

  # Clones a mission (attributes + child assignments) so parents don't rebuild
  # similar missions from scratch. Drops the parent on the edit screen to tweak.
  def duplicate
    duplicate_record(@global_task,
                     success_path: ->(copy) { edit_parent_global_task_path(copy) },
                     failure_path: parent_global_tasks_path,
                     success_notice: "Missão duplicada. Ajuste o que quiser.") do |copy|
      copy.save!
      GlobalTaskAssignment.where(global_task_id: @global_task.id).pluck(:profile_id).each do |pid|
        GlobalTaskAssignment.create!(global_task_id: copy.id, profile_id: pid)
      end
    end
  end

  # ── Assignment matrix ──────────────────────────────────────────────────
  # Grid of missions × children with live-saving toggles. One screen to decide
  # which children receive which missions.
  def assignments
    @global_tasks = GlobalTask.for_family(current_profile.family_id).with_assignments.by_priority
    @kids = current_profile.family.profiles.child.order(:name)
  end

  # Persists one matrix row: the full set of currently-checked children.
  def assignment
    @kids = current_profile.family.profiles.child.order(:name)
    result = Tasks::SetAssignments.call(global_task: @global_task, profile_ids: params[:profile_ids])
    # Reload with the association preloaded so the row partial doesn't trip
    # strict_loading when reading assigned_profiles.
    @global_task = GlobalTask.for_family(current_profile.family_id).with_assignments.find(@global_task.id)

    if result.success?
      render turbo_stream: assign_row_stream(saved: true)
    else
      # The row replace reverts the checkboxes to server truth; the matrix
      # Stimulus controller surfaces the message client-side on the 422.
      render turbo_stream: assign_row_stream(saved: false), status: :unprocessable_content
    end
  end

  # ── Mission library (curated quick-add) ────────────────────────────────
  def library
    @templates = Tasks::TemplateLibrary.all
    @existing_titles = GlobalTask.where(family_id: current_profile.family_id).pluck(:title)
  end

  def add_from_template
    # Templates are trusted curated data (Tasks::TemplateLibrary), guarded by a
    # spec that every entry builds a valid GlobalTask — so create! surfaces a
    # broken template loudly instead of silently miscounting. Unknown/blank keys
    # are dropped (attributes_for returns nil).
    add_from_templates(
      success_path: parent_global_tasks_path,
      library_path: library_parent_global_tasks_path,
      notice: ->(n) { "#{n} #{n == 1 ? 'missão adicionada' : 'missões adicionadas'} ao catálogo." },
      empty_alert: "Nenhuma missão selecionada."
    ) do |key|
      attrs = Tasks::TemplateLibrary.attributes_for(key)
      GlobalTask.create!(attrs.merge(family_id: current_profile.family_id)) if attrs
    end
  end

  private

  def assign_row_stream(saved:)
    turbo_stream.replace(
      "assign_row_#{@global_task.id}",
      partial: "parent/global_tasks/assign_row",
      locals: { mission: @global_task, kids: @kids, saved: saved }
    )
  end

  def resolved_profiles_for(mission)
    mission.assigned_profiles.any? ? mission.assigned_profiles : @kids
  end

  def set_global_task
    @global_task = GlobalTask.where(family_id: current_profile.family_id).find(params[:id])
  end

  def global_task_params
    p = params.require(:global_task).permit(:title, :points, :category, :frequency, :active, :featured, :icon, :description,
                                             :day_of_month, :max_completions_per_period,
                                             days_of_week: [], assigned_profile_ids: [])
    p[:days_of_week]&.reject!(&:blank?)
    p[:assigned_profile_ids]&.reject!(&:blank?)
    p
  end
end

class Parent::ProfilesController < ApplicationController
  include Authenticatable

  skip_before_action :require_profile!, only: [ :new, :create ], if: -> { params[:onboarding] == "true" }

  before_action :require_parent!, except: [ :new, :create ]
  before_action :require_parent_unless_onboarding!, only: [ :new, :create ]
  before_action :set_profile, only: [ :edit, :update ]
  before_action :set_child_profile, only: [ :destroy ]

  layout "parent"

  def index
    @profiles = current_family.profiles.child.order(:name)
    # Aggregate counts in two grouped queries instead of loading every child's
    # full ProfileTask history into memory just to count two statuses.
    ids = @profiles.map(&:id)
    @awaiting_counts = ProfileTask.where(profile_id: ids).awaiting_approval.group(:profile_id).count
    @pending_counts  = ProfileTask.where(profile_id: ids).pending.group(:profile_id).count
  end

  def new
    role = (params[:onboarding] == "true" || params[:invited] == "true") ? :parent : :child
    @profile = current_family.profiles.new(role: role)
  end

  def create
    pin = params.dig(:profile, :pin)
    attrs = profile_params.except(:pin)
    # Onboarding always creates a parent profile (first parent on signup, additional parents on invite).
    attrs[:role] = :parent if params[:onboarding] == "true" || params[:invited] == "true"
    result = Auth::CreateProfile.call(family: current_family, params: attrs, pin: pin)
    if result.success?
      if params[:onboarding] == "true"
        session[:profile_id] = result.data.id
        redirect_to result.data.parent? ? parent_root_path : kid_root_path
      else
        redirect_to parent_profiles_path, notice: "Perfil criado."
      end
    else
      @profile = result.data || current_family.profiles.new(attrs)
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      if @profile.parent?
        redirect_to parent_settings_path, notice: "Perfil atualizado."
      else
        redirect_to parent_root_path, notice: "Filho atualizado com sucesso!"
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @profile.destroy
    redirect_to parent_root_path, notice: "Perfil removido com sucesso."
  end

  # ── Per-child management panel ──────────────────────────────────────────
  # One screen with everything about a single child: snapshot, the missions
  # assigned to them (live toggles), and their wishlist.
  def manage
    @child = current_family.profiles.child.find(params[:id])
    @missions = GlobalTask.for_family(current_family.id).with_assignments.by_priority
    @awaiting_count = @child.profile_tasks.awaiting_approval.count
    @today_count = @child.profile_tasks.for_today(current_family.current_date).pending.count
  end

  # Adds/removes a single child from one mission, reconciling the mission's
  # full assignment set so other children keep their assignments.
  def toggle_mission
    @child = current_family.profiles.child.find(params[:id])
    @mission = GlobalTask.for_family(current_family.id).with_assignments.find(params[:mission_id])
    assigned = ActiveModel::Type::Boolean.new.cast(params[:assigned])

    result = Tasks::SetAssignments.toggle(global_task: @mission, profile_id: @child.id, assigned: assigned)
    # Reload preloaded for the row partial (strict_loading in development).
    @mission = GlobalTask.for_family(current_family.id).with_assignments.find(@mission.id)
    render turbo_stream: turbo_stream.replace(
      "manage_mission_#{@mission.id}",
      partial: "parent/profiles/manage_mission_row",
      locals: { mission: @mission, child: @child, saved: result.success? }
    ), status: (result.success? ? :ok : :unprocessable_content)
  end

  def reset_pin
    scope = current_family.profiles.where(role: :child).or(
      current_family.profiles.where(id: current_profile.id)
    )
    profile = scope.find(params[:id])
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
    scope = current_family.profiles.where(role: :child).or(
      current_family.profiles.where(id: current_profile.id)
    )
    @profile = scope.find(params[:id])
  end

  def set_child_profile
    @profile = current_family.profiles.child.find(params[:id])
  end

  def profile_params
    params.require(:profile).permit(:name, :avatar, :color, :email, :pin)
  end
end

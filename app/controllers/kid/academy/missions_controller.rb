# frozen_string_literal: true

# V5 lens-mission runner — orchestrates the lens journey defined by
# Academy::Lens::ChooseNext and the lifecycle services in
# Academy::Missions::{Begin, AdvanceLens, Finalize}.
#
# Per-lens visual UI lands in Phase 5 of academy-v5-lens-missions. Until
# then this controller renders a minimal lens_stage view that surfaces the
# current lens type + concept + a single "Próxima" CTA so the journey is
# walkable end-to-end.
class Kid::Academy::MissionsController < Kid::Academy::BaseController
  before_action :load_subject_and_mission

  def show
    review_result = ::Academy::Missions::ReviewMode.call(learner: current_learner, mission: @mission)
    if review_result.success?
      @review_stage = review_result.data
      @challenge_committed = @mission.challenge? && challenge_already_committed?
      return render :review
    end

    result = ::Academy::Missions::Begin.call(learner: current_learner, mission: @mission)
    unless result.success?
      if result.error == :mission_already_completed
        return redirect_to kid_academy_subject_path(@subject),
                           notice: "Você já completou \"#{@mission.title}\". ✨"
      end
      return render_unavailable(result.error)
    end

    @stage = result.data
    @streak = current_mission_streak
    render :lens_stage
  end

  # GET /kid/academy/subjects/:subject_id/missions/:id/visits/:visit_id
  def review_visit
    @progress = ::Academy::MissionProgress.find_by(
      learner_id: current_learner.id, mission_id: @mission.id
    )
    return redirect_to kid_academy_subject_mission_path(@subject, @mission) unless @progress

    @entry = ::Academy::Missions::ReviewMode.fetch_visit_entry(
      progress: @progress, visit_id: params[:visit_id]
    )
    return redirect_to kid_academy_subject_mission_path(@subject, @mission) unless @entry

    render :review_lens
  end

  # POST /kid/academy/subjects/:subject_id/missions/:id/advance
  def advance
    @progress = ::Academy::MissionProgress.find_by!(
      learner_id: current_learner.id, mission_id: @mission.id
    )

    payload = signal_payload_params
    outcome = params[:outcome].presence || "completed"

    update_mission_streak(payload)

    result = ::Academy::Missions::AdvanceLens.call(
      progress: @progress, signal_payload: payload, outcome: outcome,
      learner: current_learner
    )
    return render_unavailable(result.error) unless result.success?

    @stage = result.data
    # Always redirect after POST. Turbo Drive treats a 200-HTML response to a
    # form submission as an error ("Form responses must redirect to another
    # location"); a 303 → GET show is idempotent because Begin replays the
    # open visit and rerenders the same lens_stage.
    flash[:notice] = "Missão completa! ✨" if @stage.mission_complete?
    redirect_to kid_academy_subject_mission_path(@subject, @mission)
  end

  # POST /kid/academy/subjects/:subject_id/missions/:id/commit_challenge
  #
  # Turns a mission's `challenge_prompt` (mini-desafio) into a ProfileTask in
  # `awaiting_approval` status. Plugs the Academy module into the host star
  # economy: parent approves through the usual flow and the kid earns
  # ACADEMY_CHALLENGE_POINTS stars.
  def commit_challenge
    return redirect_no_challenge unless @mission.challenge?

    if challenge_already_committed?
      return redirect_to kid_academy_subject_mission_path(@subject, @mission),
                         notice: "Você já mandou esse desafio para aprovação. ⏳"
    end

    category = current_profile.family.categories.ordered.first
    unless category
      return redirect_to kid_academy_subject_mission_path(@subject, @mission),
                         alert: "Sua família precisa de pelo menos uma categoria."
    end

    result = ::Tasks::CreateCustomService.call(
      profile: current_profile,
      params: {
        custom_title: challenge_task_title(@mission),
        custom_description: @mission.challenge_prompt,
        custom_points: ACADEMY_CHALLENGE_POINTS,
        custom_category_id: category.id
      }
    )

    if result.success?
      redirect_to kid_academy_subject_mission_path(@subject, @mission),
                  notice: "Desafio enviado para aprovação. 🎯"
    else
      redirect_to kid_academy_subject_mission_path(@subject, @mission),
                  alert: result.error
    end
  end

  private

  ACADEMY_CHALLENGE_POINTS = 5
  private_constant :ACADEMY_CHALLENGE_POINTS

  def challenge_task_title(mission)
    "Desafio: #{mission.title}".truncate(ProfileTask::CUSTOM_TITLE_MAX)
  end

  def challenge_already_committed?
    current_profile.profile_tasks
      .where(source: :custom, custom_title: challenge_task_title(@mission))
      .where(status: %i[awaiting_approval approved])
      .exists?
  end

  def redirect_no_challenge
    redirect_to kid_academy_subject_mission_path(@subject, @mission),
                alert: "Essa missão não tem mini-desafio."
  end

  SIGNAL_PAYLOAD_KEYS = %i[
    micro_check_correct affective_tap predict_value choices elapsed_seconds
  ].freeze
  private_constant :SIGNAL_PAYLOAD_KEYS

  # Whitelist of signal_payload keys to keep arbitrary client-side keys
  # out of the JSONB column.
  def signal_payload_params
    raw = params[:signal_payload]
    return {} unless raw.is_a?(ActionController::Parameters) || raw.is_a?(Hash)

    permitted = raw.respond_to?(:permit) ? raw.permit(*SIGNAL_PAYLOAD_KEYS) : ActionController::Parameters.new(raw).permit(*SIGNAL_PAYLOAD_KEYS)
    permitted.to_h
  end

  def load_subject_and_mission
    @subject = ::Academy::Subject.active.find_by!(slug: params[:subject_id])
    # Nested `visits/:visit_id` route exposes the mission slug as :mission_id
    # (Rails default for nested resources), while `show` and `advance` use
    # the parent resource's :id. Accept both so review_visit doesn't 404.
    mission_slug = params[:id] || params[:mission_id]
    @mission = @subject.missions.active.find_by!(slug: mission_slug)
  end

  def render_unavailable(reason)
    @reason = reason
    render :v5_placeholder, status: :service_unavailable
  end

  # ── Mission streak (QW3) ──────────────────────────────────────────
  # Session-scoped flame counter that bumps on consecutive correct
  # micro_checks within the same mission. Wrong answer resets to 0.
  # Switching missions resets to 0. Stays put on advances without a
  # micro_check signal (e.g. predict reveal, narrative scene flips).
  def current_mission_streak
    return 0 unless session[:academy_streak_mission_id] == @mission.id
    session[:academy_streak_count].to_i
  end

  def update_mission_streak(payload)
    correctness = payload.is_a?(Hash) ? payload["micro_check_correct"].to_s : ""
    return if correctness.empty? # advance without a micro_check signal

    if session[:academy_streak_mission_id] != @mission.id
      session[:academy_streak_mission_id] = @mission.id
      session[:academy_streak_count] = 0
    end

    session[:academy_streak_count] = correctness == "true" ? session[:academy_streak_count].to_i + 1 : 0
  end
end

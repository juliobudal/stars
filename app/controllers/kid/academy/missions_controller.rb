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
    prewarm_next_lenses(@stage.progress)
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

    result = ::Academy::Missions::AdvanceLens.call(
      progress: @progress, signal_payload: payload, outcome: outcome
    )
    return render_unavailable(result.error) unless result.success?

    @stage = result.data
    prewarm_next_lenses(@progress) unless @stage.mission_complete?
    # Always redirect after POST. Turbo Drive treats a 200-HTML response to a
    # form submission as an error ("Form responses must redirect to another
    # location"); a 303 → GET show is idempotent because Begin replays the
    # open visit and rerenders the same lens_stage.
    flash[:notice] = "Missão completa! ✨" if @stage.mission_complete?
    redirect_to kid_academy_subject_mission_path(@subject, @mission)
  end

  private

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

  def prewarm_next_lenses(progress)
    return unless progress&.id
    ::Academy::Lens::PrewarmNextJob.perform_later(mission_progress_id: progress.id)
  rescue StandardError => e
    Rails.logger.warn("[Kid::Academy::MissionsController] prewarm dispatch failed: #{e.message}")
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
end

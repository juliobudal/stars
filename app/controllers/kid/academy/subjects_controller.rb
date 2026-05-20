# frozen_string_literal: true

class Kid::Academy::SubjectsController < Kid::Academy::BaseController
  def index
    @subjects = ::Academy::Subject.active.includes(:trails).order(:position, :id)
    learner_id = current_learner.id

    @skills = @subjects.to_h { |s| [ s.id, s.skill_for(learner_id) ] }

    @recent_cards = ::Academy::DiscoveryCard
                      .for_learner(learner_id)
                      .includes(mission: :subject)
                      .limit(6)

    @pending_wagers = ::Academy::PracticeWager
                        .for_learner(learner_id)
                        .pending
                        .includes(mission: :subject)
                        .order(created_at: :desc)
                        .limit(3)

    # hot_trail card is the dominant "Pílula do dia"; the other two
    # surface as "Bússola do explorador".
    @compass_plan      = ::Academy::Compass::Propose.call(learner_id: learner_id).data
    @suggested_mission = @compass_plan&.hot_trail&.mission

    # Phase 8 — fresh segredos to surface (unseen unlocks).
    @fresh_unlocks = ::Academy::SecretUnlock
                       .where(learner_id: learner_id, seen: false)
                       .includes(:secret)
                       .limit(2)
                       .to_a

    # Mark as seen now that they're being rendered — one shot, then quiet.
    if @fresh_unlocks.any?
      ::Academy::SecretUnlock
        .where(id: @fresh_unlocks.map(&:id))
        .update_all(seen: true, updated_at: Time.current)
    end
  end

  def show
    @subject = ::Academy::Subject.active.find_by!(slug: params[:id])
    @trails  = @subject.trails.active.includes(:missions).to_a

    learner_id = current_learner.id

    @trail_progress = @trails.to_h { |t| [ t.id, t.progress_for(learner_id) ] }
    @skill = @subject.skill_for(learner_id)

    # Legacy fallback: missions on this subject without a trail (v1 leftovers
    # that the kid may still have progress on). Surfaces as a "Pílulas
    # avulsas" group at the bottom of the area.
    @orphan_missions = @subject.missions.active.where(trail_id: nil).to_a
    @orphan_progresses = ::Academy::MissionProgress
                           .where(learner_id: learner_id, mission_id: @orphan_missions.map(&:id))
                           .index_by(&:mission_id)
  end
end

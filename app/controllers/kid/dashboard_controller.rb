class Kid::DashboardController < Kid::BaseController
  def index
    ensure_todays_tasks
    @profile_tasks    = ProfileTask.pending.where(profile: current_profile).includes(:global_task)
    @awaiting_tasks   = ProfileTask.awaiting_approval.where(profile: current_profile).includes(:global_task)
    @completed_today  = ProfileTask.approved.for_today.where(profile: current_profile).includes(:global_task)
    @next_reward      = current_profile.family.rewards.where("cost > ?", current_profile.points).order(:cost).first

    @level                  = current_profile.level
    @level_progress         = current_profile.level_progress
    @level_size             = Profile::LEVEL_SIZE
    @level_remaining        = current_profile.stars_to_next
    @level_pct              = (@level_progress.to_f / Profile::LEVEL_SIZE * 100).round
    @streak_days            = current_profile.streak_days
    @family_goal            = Rewards::WeeklyFamilyGoalService.call(family: current_profile.family).data
    @upcoming_missions      = Tasks::UpcomingService.call(profile: current_profile).data
  end

  private

  def ensure_todays_tasks
    Tasks::DailyResetService.new(family: current_profile.family).call
  end
end

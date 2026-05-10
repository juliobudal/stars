class Kid::DashboardController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout "kid"

  LEVEL_SIZE = 20

  def index
    ensure_todays_tasks
    @profile_tasks    = ProfileTask.pending.where(profile: current_profile).includes(:global_task)
    @awaiting_tasks   = ProfileTask.awaiting_approval.where(profile: current_profile).includes(:global_task)
    @completed_today  = ProfileTask.approved.for_today.where(profile: current_profile).includes(:global_task)
    @next_reward      = current_profile.family.rewards.where("cost > ?", current_profile.points).order(:cost).first

    points = current_profile.points.to_i
    @level                  = (points / LEVEL_SIZE) + 1
    @level_progress         = points % LEVEL_SIZE
    @level_size             = LEVEL_SIZE
    @level_remaining        = LEVEL_SIZE - @level_progress
    @level_pct              = (@level_progress.to_f / LEVEL_SIZE * 100).round
    @streak_days            = current_profile.streak_days
    @family_goal            = Rewards::WeeklyFamilyGoalService.call(family: current_profile.family).data
  end

  private

  def ensure_todays_tasks
    Tasks::DailyResetService.new(family: current_profile.family).call
  end
end

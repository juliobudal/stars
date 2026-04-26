class Kid::DashboardController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout "kid"

  LEVEL_SIZE = 20

  def index
    ensure_todays_tasks
    @profile_tasks    = ProfileTask.pending.where(profile: current_profile).includes(:global_task)
    @awaiting_tasks   = ProfileTask.awaiting_approval.where(profile: current_profile).includes(:global_task)
    @completed_today  = ProfileTask.approved.where(profile: current_profile).includes(:global_task)
    @next_reward      = current_profile.family.rewards.where("cost > ?", current_profile.points).order(:cost).first

    points = current_profile.points.to_i
    @level                  = (points / LEVEL_SIZE) + 1
    @level_progress         = points % LEVEL_SIZE
    @level_size             = LEVEL_SIZE
    @level_remaining        = LEVEL_SIZE - @level_progress
    @level_pct              = (@level_progress.to_f / LEVEL_SIZE * 100).round
    @streak_days            = compute_streak
  end

  private

  def ensure_todays_tasks
    Tasks::DailyResetService.new(family: current_profile.family).call
  end

  def compute_streak
    today = family_today(current_profile.family)
    days = current_profile.activity_logs
                          .where(log_type: :earn)
                          .where("created_at >= ?", 30.days.ago.beginning_of_day)
                          .pluck(:created_at)
                          .map { |t| t.in_time_zone.to_date }
                          .uniq
                          .sort
                          .reverse
    return 0 if days.empty? || days.first != today

    streak = 1
    days.each_cons(2) do |a, b|
      break unless (a - b).to_i == 1
      streak += 1
    end
    streak
  end
end

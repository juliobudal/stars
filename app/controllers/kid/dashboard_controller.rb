class Kid::DashboardController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout 'kid'

  def index
    ensure_todays_tasks
    @profile_tasks    = ProfileTask.pending.where(profile: current_profile).includes(:global_task)
    @awaiting_tasks   = ProfileTask.awaiting_approval.where(profile: current_profile).includes(:global_task)
    @completed_today  = ProfileTask.approved.where(profile: current_profile).includes(:global_task)
    @next_reward      = current_profile.family.rewards.where("cost > ?", current_profile.points).order(:cost).first
  end

  private

  def ensure_todays_tasks
    today = family_today(current_profile.family)
    return if ProfileTask.where(profile: current_profile, assigned_date: today).exists?

    Tasks::DailyResetService.new(family: current_profile.family).call
  end
end

class Kid::WalletController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout 'kid'

  def index
    @activity_logs = ActivityLog.where(profile: current_profile).order(created_at: :desc)

    week_start = Date.current.beginning_of_week
    week_logs = @activity_logs.where("created_at >= ?", week_start)
    @week_earned   = week_logs.where(log_type: :earn).sum(:points)
    @week_spent    = week_logs.where(log_type: :redeem).sum(:points)
    @week_missions = week_logs.where(log_type: :earn).count
  end
end

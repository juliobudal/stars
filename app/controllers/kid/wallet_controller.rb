class Kid::WalletController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout "kid"

  def index
    @activity_logs = ActivityLog.where(profile: current_profile).order(created_at: :desc).load

    week_start_day = current_profile.family.week_start.zero? ? :sunday : :monday
    week_start = Time.current.beginning_of_week(week_start_day)
    week_logs = ActivityLog.where(profile: current_profile).where("created_at >= ?", week_start)
    @week_earned   = week_logs.where(log_type: :earn).sum(:points)
    @week_spent    = week_logs.where(log_type: :redeem).sum(:points)
    @week_missions = current_profile.profile_tasks.where(status: :approved).where("updated_at >= ?", week_start).count

    @today            = family_today(current_profile.family)
    @all_grouped      = @activity_logs.group_by { |l| l.created_at.to_date }
    @earned_grouped   = @activity_logs.select(&:earn?).group_by { |l| l.created_at.to_date }
    @purchase_grouped = @activity_logs.select(&:redeem?).group_by { |l| l.created_at.to_date }
  end
end

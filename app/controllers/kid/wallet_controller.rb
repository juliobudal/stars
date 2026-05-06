class Kid::WalletController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout "kid"

  HISTORY_LIMIT = 200

  def index
    @today = family_today(current_profile.family)
    week_start_day = current_profile.family.week_start.zero? ? :sunday : :monday
    week_start = Time.current.beginning_of_week(week_start_day)

    weekly_logs = current_profile.activity_logs.where("created_at >= ?", week_start)
    @week_earned   = weekly_logs.earn.sum(:points)
    @week_spent    = weekly_logs.redeem.sum(:points).abs
    @week_missions = current_profile.profile_tasks.approved.where("updated_at >= ?", week_start).count

    @activity_logs = current_profile.activity_logs
                                    .includes(:profile)
                                    .order(created_at: :desc)
                                    .limit(HISTORY_LIMIT)
                                    .load

    @all_grouped      = @activity_logs.group_by { |l| l.created_at.to_date }
    @earned_grouped   = @activity_logs.select(&:earn?).group_by { |l| l.created_at.to_date }
    @purchase_grouped = @activity_logs.select(&:redeem?).group_by { |l| l.created_at.to_date }

    @pending_tasks  = current_profile.profile_tasks.awaiting_approval.includes(:global_task, :custom_category).order(updated_at: :desc)
    @rejected_tasks = current_profile.profile_tasks.rejected.includes(:global_task, :custom_category).order(updated_at: :desc).limit(50)
  end
end

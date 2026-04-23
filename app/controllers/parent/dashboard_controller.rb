class Parent::DashboardController < ApplicationController
  include Authenticatable
  before_action :require_parent!

  layout "parent"

  def index
    @family = Family.includes(:profiles).find(current_profile.family_id)
    @children = @family.profiles.child

    # Pre-calculate counts for each child for today's tasks
    @child_stats = ProfileTask.where(profile: @children, assigned_date: Date.current)
                              .group(:profile_id, :status)
                              .count
    # Results in something like { [profile_id, "pending"] => 5, [profile_id, "approved"] => 2 }

    family_tasks = ProfileTask.joins(:profile).where(profiles: { family_id: @family.id })

    @stats = {
      children: @children.count,
      pending_tasks: family_tasks.pending.count,
      pending_approvals: family_tasks.awaiting_approval.count,
      active_missions: family_tasks.actionable.count,
      rewards_count: Reward.count,
      total_stars: @children.sum(:points)
    }

    @child_awaiting = ProfileTask.awaiting_approval
                                 .joins(:profile)
                                 .where(profiles: { family_id: @family.id })
                                 .group(:profile_id)
                                 .count

    @recent_activity = ActivityLog.where(profile: @children)
                                  .order(created_at: :desc)
                                  .limit(5)
                                  .includes(:profile)
  end
end

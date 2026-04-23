class Parent::DashboardController < ApplicationController
  include Authenticatable
  before_action :require_parent!

  layout 'parent'

  def index
    @family = Family.includes(:profiles).find(current_profile.family_id)
    @children = @family.profiles.child

    # Per-child awaiting-approval count { child_id => count }
    @child_awaiting = ProfileTask.joins(:profile)
                                 .where(profiles: { family_id: @family.id, role: :child })
                                 .awaiting_approval
                                 .group(:profile_id)
                                 .count

    # Per-child active missions (pending tasks) count { child_id => count }
    @child_missions = ProfileTask.joins(:profile)
                                 .where(profiles: { family_id: @family.id, role: :child })
                                 .pending
                                 .group(:profile_id)
                                 .count

    @stats = {
      children:          @children.count,
      pending_approvals: ProfileTask.joins(:profile).where(profiles: { family_id: @family.id }).awaiting_approval.count,
      total_stars:       @children.sum(:points),
      active_missions:   @child_missions.values.sum,
      rewards_count:     Reward.where(family_id: @family.id).count
    }

    # Recent activity across all children
    child_ids = @children.pluck(:id)
    @recent_activity = ActivityLog.includes(:profile)
                                  .where(profile_id: child_ids)
                                  .order(created_at: :desc)
                                  .limit(10)
  end
end

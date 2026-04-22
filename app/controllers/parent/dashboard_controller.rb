class Parent::DashboardController < ApplicationController
  include Authenticatable
  before_action :require_parent!

  layout 'parent'

  def index
    @family = Family.includes(:profiles).find(current_profile.family_id)
    @children = @family.profiles.child
    
    # Pre-calculate counts for each child for today's tasks
    @child_stats = ProfileTask.where(profile: @children, assigned_date: Date.current)
                              .group(:profile_id, :status)
                              .count
    # Results in something like { [profile_id, "pending"] => 5, [profile_id, "approved"] => 2 }

    @stats = {
      children: @children.count,
      pending_tasks: ProfileTask.joins(:profile).where(profiles: { family_id: @family.id }).pending.count,
      pending_approvals: ProfileTask.joins(:profile).where(profiles: { family_id: @family.id }).awaiting_approval.count,
      total_stars: @children.sum(:points)
    }
  end
end

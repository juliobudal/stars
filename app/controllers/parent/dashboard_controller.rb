class Parent::DashboardController < ApplicationController
  include Authenticatable
  before_action :require_parent!

  layout "parent"

  def index
    @family = Family.includes(:profiles).find(current_profile.family_id)
    Tasks::DailyResetService.new(family: @family).call
    @children = @family.profiles.child.includes(:wishlist_reward)

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

    @pending_tasks = ProfileTask.includes(:profile, :global_task)
                               .joins(:profile)
                               .where(profiles: { family_id: @family.id })
                               .awaiting_approval
                               .order(updated_at: :asc)
                               .limit(5)

    @family_goal = Rewards::WeeklyFamilyGoalService.call(family: @family).data
  end
end

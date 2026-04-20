class Parent::DashboardController < ApplicationController
  include Authenticatable
  before_action :require_parent!

  layout 'parent'

  def index
    family_profiles = current_profile.family.profiles
    
    @children = family_profiles.child
    @stats = {
      children: @children.count,
      pending_tasks: current_profile.family.profile_tasks.pending.count,
      pending_approvals: current_profile.family.profile_tasks.awaiting_approval.count,
      total_stars: @children.sum(:points)
    }
  end
end

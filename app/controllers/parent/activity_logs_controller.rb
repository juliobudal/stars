class Parent::ActivityLogsController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  layout 'parent'

  def index
    child_profiles = Profile.where(family_id: current_profile.family_id).child
    @activity_logs = ActivityLog.where(profile: child_profiles)
                                .includes(:profile)
                                .order(created_at: :desc)
                                .limit(100)
  end
end

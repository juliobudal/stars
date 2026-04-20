class Parent::ActivityLogsController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  layout 'parent'

  def index
    @activity_logs = ActivityLog.where(profile: current_profile.family.profiles.child)
                                .includes(:profile)
                                .order(created_at: :desc)
                                .limit(100)
  end
end

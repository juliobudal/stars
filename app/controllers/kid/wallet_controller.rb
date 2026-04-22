class Kid::WalletController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout 'kid'

  def index
    @activity_logs = ActivityLog.where(profile: current_profile).order(created_at: :desc)
  end
end

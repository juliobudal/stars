class Kid::WalletController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout 'kid'

  def index
    @activity_logs = current_profile.activity_logs.order(created_at: :desc)
  end
end

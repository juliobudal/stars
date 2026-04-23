class Parent::SettingsController < ApplicationController
  include Authenticatable
  before_action :require_parent!

  layout "parent"

  def show
    @family = current_profile.family
  end

  def update
    # TODO: persist settings updates
    redirect_to parent_settings_path, notice: "Salvo"
  end
end

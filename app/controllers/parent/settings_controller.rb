class Parent::SettingsController < ApplicationController
  include Authenticatable
  before_action :require_parent!

  layout "parent"

  def show
    @family = current_profile.family
  end

  def update
    @family = current_profile.family
    if @family.update(settings_params)
      redirect_to parent_settings_path, notice: "Salvo"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    raw = params.require(:family).permit(
      :locale, :timezone, :week_start, :require_photo, :decay_enabled,
      :allow_negative, :auto_approve_threshold
    )
    raw[:require_photo]   = ActiveModel::Type::Boolean.new.cast(raw[:require_photo]) if raw.key?(:require_photo)
    raw[:decay_enabled]   = ActiveModel::Type::Boolean.new.cast(raw[:decay_enabled]) if raw.key?(:decay_enabled)
    raw[:allow_negative]  = ActiveModel::Type::Boolean.new.cast(raw[:allow_negative]) if raw.key?(:allow_negative)
    raw[:auto_approve_threshold] = nil if raw[:auto_approve_threshold].blank?
    raw
  end
end

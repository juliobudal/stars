class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  protect_from_forgery with: :exception

  around_action :with_family_locale

  helper_method :family_today

  def family_today(family)
    Time.current.in_time_zone(family.timezone).to_date
  end

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def not_found
    respond_to do |format|
      format.html { render file: Rails.public_path.join("404.html"), status: :not_found, layout: false }
      format.turbo_stream { head :not_found }
      format.any { head :not_found }
    end
  end

  def bad_request
    head :bad_request
  end

  def with_family_locale
    family = Family.find_by(id: cookies.signed[:family_id])
    locale = family&.locale || I18n.default_locale
    I18n.with_locale(locale) { yield }
  end
end

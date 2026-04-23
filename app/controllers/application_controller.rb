class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  protect_from_forgery with: :exception

  helper_method :current_profile, :family_today

  def family_today(family)
    Time.current.in_time_zone(family.timezone).to_date
  end

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  def current_profile
    @current_profile ||= Profile.includes(:family).find_by(id: session[:profile_id]) if session[:profile_id]
  end

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
end

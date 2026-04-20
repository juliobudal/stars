class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  protect_from_forgery with: :exception

  helper_method :current_profile

  def current_profile
    @current_profile ||= Profile.find_by(id: session[:profile_id]) if session[:profile_id]
  end
end

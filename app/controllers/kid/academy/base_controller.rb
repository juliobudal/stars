# frozen_string_literal: true

# Base controller for the kid-facing Academy module surface. The host
# concerns (Authenticatable) are reused, but the rest of the kid::academy
# stack only talks to the Academy module through Academy::* services.
class Kid::Academy::BaseController < ApplicationController
  include Authenticatable
  before_action :require_child!
  before_action :require_academy_configured!
  layout "kid"

  helper_method :current_learner

  private

  def current_learner
    @current_learner ||= ::Academy::Learner.from_profile(current_profile)
  end

  def require_academy_configured!
    return if ::Academy.configured?

    redirect_to kid_root_path, alert: "Academia indisponível (configuração pendente)."
  end
end

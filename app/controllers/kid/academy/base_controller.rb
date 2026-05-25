# frozen_string_literal: true

# Base controller for the kid-facing Academy module surface. The host
# concerns (Authenticatable) are reused, but the rest of the kid::academy
# stack only talks to the Academy module through Academy::* services.
class Kid::Academy::BaseController < ApplicationController
  include Authenticatable
  include KidOnboardingGuard
  before_action :require_child!
  layout "kid"

  helper_method :current_learner

  private

  def current_learner
    @current_learner ||= ::Academy::Learner.from_profile(current_profile)
  end
end

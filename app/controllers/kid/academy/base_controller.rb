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
    @current_learner ||= build_learner(current_profile)
  end

  # Host-side boundary adapter: translates a Profile into the module's pure
  # Learner value object. Reaching into Profile / ProfileInterest::Catalog is
  # legitimate here (host code); the Academy module itself never references
  # host models — this controller is the only bridge.
  def build_learner(profile)
    interests = Array(profile.interest_keys).map do |key|
      ::Academy::Interest.new(key: key, label: ::ProfileInterest::Catalog.label_for(key))
    end

    ::Academy::Learner.new(
      id: profile.id,
      display_name: profile.name,
      age_band: profile.child? ? "kid" : "adult",
      timezone: profile.family&.timezone.presence || "UTC",
      interests: interests
    )
  end
end

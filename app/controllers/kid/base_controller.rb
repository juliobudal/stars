# frozen_string_literal: true

# Shared base for kid-facing controllers outside the Academy module.
# Bundles the authentication, child-role enforcement, and the
# first-session onboarding gate so the guard is impossible to forget
# when a new kid surface is added.
class Kid::BaseController < ApplicationController
  include Authenticatable
  include KidOnboardingGuard

  before_action :require_child!
  layout "kid"
end

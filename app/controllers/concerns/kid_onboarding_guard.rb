# frozen_string_literal: true

# Redirects un-onboarded child profiles to the welcome flow. Included by
# Kid::BaseController and Kid::Academy::BaseController so every kid-facing
# surface enforces the gate; Kid::OnboardingController opts out via
# `skip_before_action :gate_kid_onboarding!`.
module KidOnboardingGuard
  extend ActiveSupport::Concern

  included do
    before_action :gate_kid_onboarding!
  end

  private

  def gate_kid_onboarding!
    return unless current_profile&.child?
    return if current_profile.onboarded_at.present?

    redirect_to kid_welcome_path
  end
end

# frozen_string_literal: true

class Parent::Academy::PracticeWagersController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  layout "parent"

  OBSERVATIONS = ::Academy::PracticeWager::PARENT_OBSERVATIONS.freeze

  def update
    wager = ::Academy::PracticeWager.find(params[:id])
    kid_ids = current_family.profiles.where(role: :child).pluck(:id)
    head :not_found unless kid_ids.include?(wager.learner_id)

    observation = params[:observation].to_s
    if OBSERVATIONS.include?(observation)
      wager.update!(parent_observation: observation, observed_at: Time.current)
      redirect_back fallback_location: parent_academy_dashboard_path,
                    notice: "Observação registrada."
    else
      redirect_back fallback_location: parent_academy_dashboard_path,
                    alert: "Observação inválida."
    end
  end
end

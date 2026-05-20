# frozen_string_literal: true

class Parent::Academy::CardsController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  layout false

  def show
    @card = ::Academy::DiscoveryCard.includes(mission: :subject).find(params[:id])
    family_kid_ids = current_family.profiles.where(role: :child).pluck(:id)
    head(:not_found) and return unless family_kid_ids.include?(@card.learner_id)

    @kid = current_family.profiles.find(@card.learner_id)
    response.headers["Content-Disposition"] = %(attachment; filename="littlestars-carta-#{@card.id}.svg")
    render formats: :svg, content_type: "image/svg+xml"
  end
end

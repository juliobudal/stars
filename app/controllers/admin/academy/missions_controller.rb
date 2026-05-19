# frozen_string_literal: true

# Minimal in-house CMS for Academy missions (v5 — seed-only fields).
# Lens content lives in Admin::Academy::LensesController; missions here
# only carry the seed metadata that drives ChooseNext + Generate.
class Admin::Academy::MissionsController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  layout "parent"

  def index
    @subjects = ::Academy::Subject.order(:position, :id)
    scope = ::Academy::Mission.includes(:subject, :concept).order(:subject_id, :order_in_subject)
    scope = scope.where(subject_id: params[:subject_id]) if params[:subject_id].present?
    @missions = scope.limit(200)
  end

  def edit
    @mission = ::Academy::Mission.find(params[:id])
  end

  def update
    @mission = ::Academy::Mission.find(params[:id])
    attrs = mission_params
    if attrs[:curiosity_facts].is_a?(String)
      attrs[:curiosity_facts] = attrs[:curiosity_facts].split("\n").map(&:strip).reject(&:blank?)
    end

    if @mission.update(attrs)
      redirect_to admin_academy_mission_path(@mission), notice: "Missão atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    @mission = ::Academy::Mission.find(params[:id])
  end

  private

  def mission_params
    params.require(:mission).permit(
      :title, :hook, :learning_objective, :central_insight,
      :curiosity_facts, :challenge_prompt, :challenge_when, :challenge_observable,
      :active, :source, :framework, :concept_id
    )
  end
end

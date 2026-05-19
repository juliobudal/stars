# frozen_string_literal: true

# v5 admin surface for the LLM-generated lens cache. Curator ops:
#
#   index   — list cache rows (with concept + lens_type filters)
#   edit    — JSON editor for the override
#   update  — saves a curator-authored payload (override)
#   regen   — purges the row and queues a fresh Generate run
#   flag    — toggles quality_flagged (hides from runtime serving)
class Admin::Academy::LensesController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  layout "parent"

  def index
    @lens_types = ::Academy::Lens::Catalog.types
    @concepts   = ::Academy::Concept.active.order(:category, :slug)
    scope = ::Academy::LensCache.includes(:concept).order(updated_at: :desc)
    scope = scope.where(lens_type: params[:lens_type]) if params[:lens_type].present?
    scope = scope.where(concept_id: params[:concept_id]) if params[:concept_id].present?
    scope = scope.where(quality_flagged: true) if params[:flagged] == "1"
    @rows = scope.limit(200)
  end

  def edit
    @row = ::Academy::LensCache.find(params[:id])
  end

  def update
    @row = ::Academy::LensCache.find(params[:id])
    payload_str = params.dig(:lens_cache, :payload).to_s
    @row.payload = JSON.parse(payload_str) if payload_str.present?
    if @row.save
      redirect_to admin_academy_lenses_path, notice: "Lente atualizada (override)."
    else
      render :edit, status: :unprocessable_entity
    end
  rescue JSON::ParserError => e
    @row.errors.add(:payload, "JSON inválido: #{e.message}")
    render :edit, status: :unprocessable_entity
  end

  def regenerate
    row = ::Academy::LensCache.find(params[:id])
    concept = row.concept
    lens_type = row.lens_type.to_sym
    age_band = row.age_band
    locale = row.locale

    row.destroy!
    result = ::Academy::Lens::Generate.call(
      concept: concept, lens_type: lens_type, age_band: age_band, locale: locale
    )

    if result.success?
      redirect_to admin_academy_lenses_path, notice: "Lente regenerada."
    else
      redirect_to admin_academy_lenses_path, alert: "Regeneração falhou: #{result.error}"
    end
  end

  def flag
    row = ::Academy::LensCache.find(params[:id])
    row.update!(quality_flagged: !row.quality_flagged)
    redirect_to admin_academy_lenses_path,
                notice: row.quality_flagged ? "Lente sinalizada." : "Lente reabilitada."
  end
end

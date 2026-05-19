# frozen_string_literal: true

# Admin surface for curated lens cache. Curator ops:
#
#   index   — list cache rows (with concept + lens_type filters)
#   edit    — JSON editor for the override
#   update  — saves a curator-authored payload override
#   flag    — toggles quality_flagged (hides from runtime serving)
#
# Regeneration via LLM was retired with the curated-static pivot;
# fresh content lands by editing db/seeds/academy_lens_payloads/<type>/<slug>.json
# and rerunning the seeder.
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

  def flag
    row = ::Academy::LensCache.find(params[:id])
    row.update!(quality_flagged: !row.quality_flagged)
    redirect_to admin_academy_lenses_path,
                notice: row.quality_flagged ? "Lente sinalizada." : "Lente reabilitada."
  end
end

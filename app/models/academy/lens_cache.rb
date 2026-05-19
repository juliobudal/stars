# frozen_string_literal: true

module Academy
  # Global cache of curated lens payloads. One row per
  # (concept_id, lens_type, age_band, locale). Payloads are
  # learner-agnostic; runtime personalization substitutes
  # `{{tokens}}` in-memory via Academy::Lens::InterpolatePayload.
  class LensCache < ApplicationRecord
    self.table_name = "academy_lens_cache"

    belongs_to :concept, class_name: "Academy::Concept"

    validates :lens_type, :age_band, :locale, :generated_at, presence: true
    validates :concept_id, uniqueness: { scope: %i[lens_type age_band locale] }

    SOURCES = %w[curated].freeze
    validates :source, inclusion: { in: SOURCES }

    scope :servable, -> { where(quality_flagged: false) }
    scope :curated,  -> { where(source: "curated") }
  end
end

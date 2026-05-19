# frozen_string_literal: true

module Academy
  # Global cache of LLM-generated lens payloads. One row per
  # (concept_id, lens_type, age_band, locale, template_version) — see
  # REQ-LGEN-003. Payloads are learner-agnostic; runtime personalization
  # == Schema Information
  #
  # Table name: academy_lens_cache
  #
  #  id               :bigint           not null, primary key
  #  age_band         :string           default("kid"), not null
  #  generated_at     :datetime         not null
  #  lens_type        :string           not null
  #  locale           :string           default("pt-BR"), not null
  #  payload          :jsonb            not null
  #  quality_flagged  :boolean          default(FALSE), not null
  #  template_version :string           not null
  #  tokens_in        :integer
  #  tokens_out       :integer
  #  created_at       :datetime         not null
  #  updated_at       :datetime         not null
  #  concept_id       :bigint           not null
  #  model_id         :string
  #
  # Indexes
  #
  #  idx_academy_lens_cache_quality_flagged  (quality_flagged) WHERE (quality_flagged = true)
  #  idx_academy_lens_cache_unique           (concept_id,lens_type,age_band,locale,template_version) UNIQUE
  #  index_academy_lens_cache_on_lens_type   (lens_type)
  #
  # Foreign Keys
  #
  #  fk_rails_...  (concept_id => academy_concepts.id)
  #
  # substitutes `{{tokens}}` in-memory only (REQ-LGEN-006).
  class LensCache < ApplicationRecord
    self.table_name = "academy_lens_cache"

    belongs_to :concept, class_name: "Academy::Concept"

    validates :lens_type, :age_band, :locale, :template_version, :generated_at,
              :mastery_tier, :prompt_digest, presence: true
    validates :concept_id, uniqueness: {
      scope: %i[lens_type age_band locale template_version mastery_tier prompt_digest]
    }

    SOURCES = %w[curated llm].freeze
    validates :source, inclusion: { in: SOURCES }

    scope :servable, -> { where(quality_flagged: false) }
    scope :curated,  -> { where(source: "curated") }
    scope :llm,      -> { where(source: "llm") }
    scope :for_key, ->(concept_id:, lens_type:, age_band:, locale:, template_version:) {
      where(
        concept_id: concept_id, lens_type: lens_type.to_s,
        age_band: age_band, locale: locale, template_version: template_version
      )
    }
  end
end

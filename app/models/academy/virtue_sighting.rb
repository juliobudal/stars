# frozen_string_literal: true

module Academy
  # Pinned moment of practiced character. Explicitly NOT a score. Each row
  # is one observation. Sources: self_reported (kid), parent_confirmed,
# == Schema Information
#
# Table name: academy_virtue_sightings
#
#  id                                                                                  :bigint           not null, primary key
#  context(1-2 sentences describing what happened)                                     :text             not null
#  source(self_reported | parent_confirmed | guide_inferred)                           :string           not null
#  spotted_at                                                                          :datetime         not null
#  virtue_slug(honra-palavra | conserta-erro | espera | conta-verdade-que-custa | ...) :string           not null
#  created_at                                                                          :datetime         not null
#  updated_at                                                                          :datetime         not null
#  learner_id(Learner value-object id (no FK))                                         :bigint           not null
#
# Indexes
#
#  idx_academy_virtue_sightings_learner_slug_time  (learner_id,virtue_slug,spotted_at)
#  idx_academy_virtue_sightings_source             (source)
#
  # guide_inferred (LLM spotted it in conversation).
  class VirtueSighting < ApplicationRecord
    self.table_name = "academy_virtue_sightings"

    SOURCES = %w[self_reported parent_confirmed guide_inferred].freeze

    # Open vocabulary for now — content team curates. Codifying as constants
    # so we don't lose track of which slugs are in play.
    VIRTUE_SLUGS = %w[
      honra-palavra
      conserta-erro
      espera
      conta-verdade-que-custa
      ajuda-sem-pedir
      escuta-ate-o-fim
    ].freeze

    validates :learner_id, presence: true
    validates :virtue_slug, presence: true
    validates :context, presence: true
    validates :source, inclusion: { in: SOURCES }
    validates :spotted_at, presence: true

    scope :for_learner, ->(id) { where(learner_id: id) }
    scope :for_virtue, ->(slug) { where(virtue_slug: slug) }
    scope :by_source, ->(source) { where(source: source) }
    scope :recent_first, -> { order(spotted_at: :desc) }
  end
end

# frozen_string_literal: true

module Academy
  # An invisible cross-cutting idea (dopamina, habito-loop, juros-compostos…)
  # that real lessons hide behind a "powerful question" headline. Concepts
  # are the spine of the v2 knowledge graph — they connect missions across
  # áreas de formação, which is what makes the "isso conecta com…" UI
  # == Schema Information
  #
  # Table name: academy_concepts
  #
  #  id                                                                                    :bigint           not null, primary key
  #  active                                                                                :boolean          default(TRUE), not null
  #  category(cognitivo | cientifico | social | financeiro | saude | virtude | tecnologia) :string           not null
  #  definition(Plain-language 1-2 line description)                                       :text
  #  name                                                                                  :string           not null
  #  pokedex_color_key(Design token name (e.g. 'pokedex-mind', 'pokedex-body'))            :string
  #  pokedex_silhouette_key(Asset name in app/assets/images/academy/pokedex/ (svg))        :string
  #  position                                                                              :integer          default(0), not null
  #  slug                                                                                  :string           not null
  #  created_at                                                                            :datetime         not null
  #  updated_at                                                                            :datetime         not null
  #
  # Indexes
  #
  #  index_academy_concepts_on_category  (category)
  #  index_academy_concepts_on_slug      (slug) UNIQUE
  #
  # surprising rather than obvious.
  class Concept < ApplicationRecord
    self.table_name = "academy_concepts"

    CATEGORIES = %w[
      cognitivo cientifico social financeiro saude virtude tecnologia
      mundo_natural linguagem historia matematica
    ].freeze

    # v5: 1:1 missão↔conceito. Legacy M:N via aula_concepts retired.
    has_many :missions, class_name: "Academy::Mission",
             foreign_key: :concept_id, dependent: :nullify

    has_many :outgoing_edges, class_name: "Academy::ConceptEdge",
             foreign_key: :from_concept_id, dependent: :destroy, inverse_of: :from_concept
    has_many :incoming_edges, class_name: "Academy::ConceptEdge",
             foreign_key: :to_concept_id, dependent: :destroy, inverse_of: :to_concept

    validates :slug, :name, :category, presence: true
    validates :slug, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
    validates :category, inclusion: { in: CATEGORIES }

    scope :active, -> { where(active: true).order(:position, :name) }

    def to_param = slug

    # Returns the curator-locked essence sentence if curated; otherwise
    # falls back to `definition`. The Guide chat prompt reads this (never
    # `definition` directly) so a concept without curation still ships,
    # and a curated concept gets the tighter north star.
    def the_essence_or_definition
      v = attributes["the_essence"].to_s.strip
      v.empty? ? definition.to_s.strip : v
    end

    # Returns nil when no common-confusion has been curated. Templates branch
    # on presence so we don't print empty headers in the prompt.
    def common_confusion_or_nil
      v = attributes["common_confusion"].to_s.strip
      v.empty? ? nil : v
    end

    def forbidden_terms_list
      Array(attributes["forbidden_terms"]).map { |t| t.to_s.strip }.reject(&:empty?)
    end
  end
end

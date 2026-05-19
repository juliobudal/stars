# frozen_string_literal: true

module Academy
  # Directed edge between two concepts. The graph is intentionally directed
  # (vs. an undirected adjacency) because some relationships are asymmetric:
  # `juros-compostos` depends_on `causa-e-efeito` but not the reverse.
# == Schema Information
#
# Table name: academy_concept_edges
#
#  id                                                   :bigint           not null, primary key
#  edge_type(v4 typed edge — see migration header)     :string           default("relates_to"), not null
#  kind(0=echoes (symmetric), 1=depends_on, 2=leads_to) :integer          default("echoes"), not null
#  created_at                                           :datetime         not null
#  updated_at                                           :datetime         not null
#  from_concept_id                                      :bigint           not null
#  to_concept_id                                        :bigint           not null
#
# Indexes
#
#  idx_academy_concept_edges_edge_type             (edge_type)
#  idx_academy_concept_edges_unique                (from_concept_id,to_concept_id,kind) UNIQUE
#  index_academy_concept_edges_on_from_concept_id  (from_concept_id)
#  index_academy_concept_edges_on_to_concept_id    (to_concept_id)
#
# Foreign Keys
#
#  fk_rails_...  (from_concept_id => academy_concepts.id)
#  fk_rails_...  (to_concept_id => academy_concepts.id)
#
  # `echoes` is conceptually symmetric — for those we seed both directions.
  class ConceptEdge < ApplicationRecord
    self.table_name = "academy_concept_edges"

    belongs_to :from_concept, class_name: "Academy::Concept", inverse_of: :outgoing_edges
    belongs_to :to_concept,   class_name: "Academy::Concept", inverse_of: :incoming_edges

    enum :kind, { echoes: 0, depends_on: 1, leads_to: 2 }, default: :echoes

    validates :from_concept_id, uniqueness: { scope: [ :to_concept_id, :kind ] }
    validate  :not_self_referential

    private

    def not_self_referential
      errors.add(:to_concept_id, "cannot equal from_concept_id") if from_concept_id == to_concept_id
    end
  end
end

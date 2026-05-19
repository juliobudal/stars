# frozen_string_literal: true

# Academy v4 — Typed edges in the concept graph.
#
# The legacy `kind` column stays for now (unique index uses it).
# `edge_type` is the v4 vocabulary used by the Atlas UI and the Compass
# personalization layer.
#
# Vocabulary:
#   generalizes     # A is a more general form of B
#   manifests_in    # concept manifests in a concrete domain
#   conflicts_with  # corrects a naive model
#   requires        # prerequisite knowledge
#   composes_with   # combines with another concept
#   predicts        # predicts a behavior
#   relates_to      # default catch-all
class AddEdgeTypeToAcademyConceptEdges < ActiveRecord::Migration[8.1]
  def change
    add_column :academy_concept_edges, :edge_type, :string,
               null: false,
               default: "relates_to",
               comment: "v4 typed edge — see migration header"

    add_index :academy_concept_edges, :edge_type,
              name: "idx_academy_concept_edges_edge_type"
  end
end

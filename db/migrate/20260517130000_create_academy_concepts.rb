# frozen_string_literal: true

# Academy v2 Phase 2 — invisible knowledge graph.
#
# Concepts are the cross-cutting ideas (e.g. dopamine, habit-loop, compound
# interest) that real lessons hide behind a "powerful question" headline.
# Each mission declares 1-3 concepts; concepts connect to each other via
# directed edges. The "isso conecta com…" UI is computed from this graph.
class CreateAcademyConcepts < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_concepts do |t|
      t.string  :slug,        null: false, index: { unique: true }
      t.string  :name,        null: false
      t.text    :definition,  comment: "Plain-language 1-2 line description"
      t.string  :category,    null: false,
                comment: "cognitivo | cientifico | social | financeiro | saude | virtude | tecnologia"
      t.integer :position,    null: false, default: 0
      t.boolean :active,      null: false, default: true
      t.timestamps
      t.index :category
    end

    create_table :academy_aula_concepts do |t|
      t.references :mission, null: false,
                   foreign_key: { to_table: :academy_missions },
                   index: true
      t.references :concept, null: false,
                   foreign_key: { to_table: :academy_concepts },
                   index: true
      t.boolean :is_primary, null: false, default: false,
                comment: "Exactly one concept per mission should be primary"
      t.timestamps
      t.index [ :mission_id, :concept_id ], unique: true,
              name: "idx_academy_aula_concepts_unique"
    end

    create_table :academy_concept_edges do |t|
      t.references :from_concept, null: false,
                   foreign_key: { to_table: :academy_concepts },
                   index: true
      t.references :to_concept, null: false,
                   foreign_key: { to_table: :academy_concepts },
                   index: true
      t.integer :kind, null: false, default: 0,
                comment: "0=echoes (symmetric), 1=depends_on, 2=leads_to"
      t.timestamps
      t.index [ :from_concept_id, :to_concept_id, :kind ], unique: true,
              name: "idx_academy_concept_edges_unique"
    end
  end
end

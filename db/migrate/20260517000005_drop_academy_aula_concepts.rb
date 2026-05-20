# frozen_string_literal: true

class DropAcademyAulaConcepts < ActiveRecord::Migration[8.0]
  def up
    drop_table :academy_aula_concepts
  end

  def down
    create_table :academy_aula_concepts do |t|
      t.bigint :concept_id, null: false
      t.datetime :created_at, null: false
      t.boolean :is_primary, default: false, null: false,
                comment: "Exactly one concept per mission should be primary"
      t.bigint :mission_id, null: false
      t.datetime :updated_at, null: false
    end

    add_index :academy_aula_concepts, :concept_id, name: "index_academy_aula_concepts_on_concept_id"
    add_index :academy_aula_concepts, [ :mission_id, :concept_id ],
              name: "idx_academy_aula_concepts_unique", unique: true
    add_index :academy_aula_concepts, :mission_id, name: "index_academy_aula_concepts_on_mission_id"

    add_foreign_key :academy_aula_concepts, :academy_concepts, column: :concept_id
    add_foreign_key :academy_aula_concepts, :academy_missions, column: :mission_id
  end
end

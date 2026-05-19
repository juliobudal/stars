# frozen_string_literal: true

class AddConceptIdToAcademyMissions < ActiveRecord::Migration[8.0]
  def up
    add_column :academy_missions, :concept_id, :bigint, null: true
    add_index :academy_missions, :concept_id
    add_foreign_key :academy_missions, :academy_concepts, column: :concept_id
  end

  def down
    remove_foreign_key :academy_missions, column: :concept_id
    remove_index :academy_missions, :concept_id if index_exists?(:academy_missions, :concept_id)
    remove_column :academy_missions, :concept_id
  end
end

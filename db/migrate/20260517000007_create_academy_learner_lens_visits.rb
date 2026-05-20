# frozen_string_literal: true

class CreateAcademyLearnerLensVisits < ActiveRecord::Migration[8.0]
  def change
    create_table :academy_learner_lens_visits do |t|
      t.bigint :mission_progress_id, null: false
      t.bigint :learner_id, null: false
      t.bigint :concept_id, null: false
      t.string :lens_type, null: false
      t.bigint :lens_cache_id
      t.integer :ordering_position, null: false,
                comment: "1-based position within mission attempt"
      t.string :chooser_version, comment: "Which version of ChooseNext picked this lens"
      t.datetime :opened_at, null: false
      t.datetime :closed_at
      t.string :outcome, comment: "completed | abandoned | skipped_by_system"
      t.jsonb :signal_payload, null: false, default: {}
      t.boolean :legacy, null: false, default: false

      t.timestamps
    end

    add_index :academy_learner_lens_visits,
              [ :mission_progress_id, :ordering_position ],
              unique: true,
              name: "idx_academy_lens_visits_position"
    add_index :academy_learner_lens_visits,
              [ :learner_id, :concept_id, :lens_type ],
              name: "idx_academy_lens_visits_learner_concept_lens"
    add_index :academy_learner_lens_visits,
              [ :learner_id, :opened_at ],
              name: "idx_academy_lens_visits_learner_opened"

    add_foreign_key :academy_learner_lens_visits, :academy_mission_progresses, column: :mission_progress_id
    add_foreign_key :academy_learner_lens_visits, :academy_concepts, column: :concept_id
    add_foreign_key :academy_learner_lens_visits, :academy_lens_cache, column: :lens_cache_id
  end
end

# frozen_string_literal: true

# Academy v4 — Pokédex of mental models.
#
# Levels:
#   0 silhouette  # never seen (record may not exist)
#   1 spotted     # first mission completed with this concept tagged
#   2 recognized  # seen in ≥2 different subjects
#   3 mastered    # ≥3 encounters OR 1 transfer detection
#
# Advancement is owned by Academy::Pokedex::Advance and is idempotent.
class CreateAcademyLearnerConcepts < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_learner_concepts do |t|
      t.bigint :learner_id, null: false,
               comment: "Learner value-object id (no FK by design — module isolation)"
      t.references :concept, null: false,
                   foreign_key: { to_table: :academy_concepts },
                   index: true
      t.integer :level, null: false, default: 0,
                comment: "0..3 (silhouette → mastered)"
      t.integer :seen_in_subjects_count, null: false, default: 0
      t.integer :transfer_count, null: false, default: 0
      t.datetime :first_seen_at
      t.datetime :last_seen_at
      t.datetime :evolved_to_2_at
      t.datetime :evolved_to_3_at
      t.timestamps

      t.index [ :learner_id, :concept_id ],
              unique: true,
              name: "idx_academy_learner_concepts_unique"
      t.index [ :learner_id, :level ],
              name: "idx_academy_learner_concepts_level"
    end
  end
end

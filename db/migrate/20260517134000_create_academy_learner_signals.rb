# frozen_string_literal: true

# Academy v2 Phase 8 — Learner signals per subject.
#
# Tracks the simple "you seem to like X" signals the adaptive picker uses
# to choose the next mission. Affinity grows with completions, correct
# checkpoints, and reported challenges. We keep it intentionally simple —
# no EWMA, no fancy decay; just integer scores the suggestor can sort by.
class CreateAcademyLearnerSignals < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_learner_signals do |t|
      t.bigint :learner_id, null: false
      t.references :subject, null: false,
                   foreign_key: { to_table: :academy_subjects },
                   index: true
      t.integer :affinity_score, null: false, default: 0,
                comment: "Cumulative weighted signal: completions + correct checkpoints + done challenges"
      t.integer :completion_count, null: false, default: 0
      t.integer :correct_checkpoints, null: false, default: 0
      t.integer :wrong_checkpoints, null: false, default: 0
      t.datetime :last_session_at
      t.timestamps
      t.index [ :learner_id, :subject_id ], unique: true,
              name: "idx_academy_signals_learner_subject"
    end
  end
end

# frozen_string_literal: true

# Academy v2 Phase 5 — Spaced repetition.
#
# Each discovery card the learner mints gets a recall_review scheduled.
# SM-2 lite intervals: 1d → 3d → 7d → 21d → 60d → 180d (on success).
# On failure (forgot), interval resets to 1d.
class CreateAcademyRecallReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_recall_reviews do |t|
      t.bigint :learner_id, null: false
      t.references :card, null: false,
                   foreign_key: { to_table: :academy_discovery_cards },
                   index: true
      t.integer :streak, null: false, default: 0,
                comment: "Consecutive successful recalls (0 means fresh / just reset)"
      t.integer :interval_days, null: false, default: 1
      t.datetime :due_at, null: false
      t.datetime :last_reviewed_at
      t.timestamps
      t.index [ :learner_id, :due_at ], name: "idx_academy_recall_learner_due"
      t.index [ :learner_id, :card_id ], unique: true, name: "idx_academy_recall_unique"
    end
  end
end

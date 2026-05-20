# frozen_string_literal: true

# One row per Lightning Round attempt. Enables daily history view, "champion"
# badge eligibility (≥4 hits in 7 days), and analytics on retrieval recall.
#
# `learner_id` is the Academy boundary id (Profile.id in practice). No FK to
# host tables — same convention as other Academy:: tables.
class CreateAcademyLightningRoundRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_lightning_round_runs do |t|
      t.bigint  :learner_id,     null: false
      t.integer :total_questions, null: false
      t.integer :correct_count,  null: false, default: 0
      t.integer :elapsed_seconds
      t.string  :tier,           null: false
      t.jsonb   :concept_ids,    null: false, default: []
      t.timestamps
    end

    add_index :academy_lightning_round_runs, [ :learner_id, :created_at ],
              name: :idx_academy_lightning_runs_by_learner_recency
  end
end

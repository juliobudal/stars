# frozen_string_literal: true

# Academy v4 — Practice wagers replace the v2 honor-system challenge_reports.
#
# At the end of a discovery mission the Guide proposes a numeric wager:
# "I bet you do X N times today. Tell me tomorrow."
# The kid reports the actual count; the parent (optionally) confirms.
# There is no score. The delta becomes conversation in the next mission.
class CreateAcademyPracticeWagers < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_practice_wagers do |t|
      t.bigint :learner_id, null: false,
               comment: "Learner value-object id (no FK)"
      t.references :mission, null: false,
                   foreign_key: { to_table: :academy_missions },
                   index: true
      t.integer :guide_bet_count, null: false,
                comment: "The Guide's numeric wager (extracted from LLM payload)"
      t.integer :learner_actual_count,
                comment: "What the kid reports D+1 — nil until reported"
      t.string :parent_observation,
               comment: "seen_match | seen_higher | seen_lower | skip"
      t.text :learner_note,
             comment: "Optional short note from the kid alongside the count"
      t.datetime :reported_at
      t.datetime :observed_at
      t.timestamps

      t.index [ :learner_id, :mission_id ],
              unique: true,
              name: "idx_academy_practice_wagers_unique"
      t.index [ :learner_id, :reported_at ],
              name: "idx_academy_practice_wagers_learner_reported"
    end
  end
end

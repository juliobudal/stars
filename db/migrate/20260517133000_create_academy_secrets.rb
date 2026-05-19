# frozen_string_literal: true

# Academy v2 Phase 8 — Segredos (intrinsic-reward unlocks).
#
# Bonus pílulas that don't show in the regular trail list. Each secret has
# an unlock rule (jsonb) evaluated by Secrets::EvaluateForLearner. When a
# rule is satisfied, an academy_secret_unlocks row is created.
class CreateAcademySecrets < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_secrets do |t|
      t.string :slug, null: false, index: { unique: true }
      t.string :title, null: false
      t.text   :teaser, comment: "Mysterious hint shown when locked"
      t.integer :kind, null: false, default: 0,
                comment: "0=cards_in_subject, 1=cards_total, 2=challenge_ratio"
      t.jsonb :rule, null: false, default: {},
                comment: "e.g. { subject_slug: 'mente-forte', threshold: 5 }"
      t.references :mission, null: true,
                   foreign_key: { to_table: :academy_missions },
                   index: true,
                   comment: "Optional bonus pílula tied to this secret"
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :academy_secret_unlocks do |t|
      t.bigint :learner_id, null: false
      t.references :secret, null: false,
                   foreign_key: { to_table: :academy_secrets },
                   index: true
      t.datetime :unlocked_at, null: false
      t.boolean :seen, null: false, default: false
      t.timestamps
      t.index [ :learner_id, :secret_id ], unique: true,
              name: "idx_academy_secret_unlocks_unique"
    end
  end
end

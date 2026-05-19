# frozen_string_literal: true

# Academy v4 — Auditable record of cross-area transfer.
#
# Created by Academy::Transfer::Detect (an LLM-judge async job) when the
# learner spontaneously applies a concept from one subject in a free-form
# reply during another subject's mission.
#
# This event is what triggers a concept's Pokédex level to jump from
# `recognized` (2) to `mastered` (3).
class CreateAcademyTransferDetections < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_transfer_detections do |t|
      t.bigint :learner_id, null: false,
               comment: "Learner value-object id (no FK)"
      t.references :from_concept, null: false,
                   foreign_key: { to_table: :academy_concepts },
                   index: { name: "idx_academy_transfer_detections_from_concept" }
      t.references :to_concept, null: false,
                   foreign_key: { to_table: :academy_concepts },
                   index: { name: "idx_academy_transfer_detections_to_concept" }
      t.references :message, null: false,
                   foreign_key: { to_table: :academy_messages },
                   index: true
      t.decimal :confidence, precision: 3, scale: 2, null: false,
                comment: "LLM-judge confidence 0..1; only records ≥0.75 are persisted"
      t.text :evidence_excerpt,
             comment: "Snippet of the kid's message that triggered detection"
      t.datetime :detected_at, null: false
      t.timestamps

      t.index [ :learner_id, :detected_at ],
              name: "idx_academy_transfer_detections_learner_time"
    end
  end
end

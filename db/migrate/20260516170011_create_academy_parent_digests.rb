# frozen_string_literal: true

# Academy v4 — "Notícias da expedição" — a weekly narrative digest mailed
# to parents. Stored so the parent can re-read previous weeks and so
# the analytics layer can audit what was actually shown.
class CreateAcademyParentDigests < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_parent_digests do |t|
      t.bigint :learner_id, null: false,
               comment: "Learner value-object id (no FK)"
      t.bigint :parent_id, null: false,
               comment: "Parent profile id (no FK — module isolation)"
      t.date :week_starting, null: false,
             comment: "Monday of the digest's week (timezone-normalized)"
      t.jsonb :payload, null: false, default: {},
              comment: "Pre-rendered blocks: {patterns_discovered, biggest_reveal, conversation_starter, kid_sent_you}"
      t.datetime :composed_at, null: false
      t.datetime :delivered_at
      t.datetime :opened_at
      t.timestamps

      t.index [ :learner_id, :week_starting ],
              unique: true,
              name: "idx_academy_parent_digests_unique"
      t.index [ :parent_id, :composed_at ],
              name: "idx_academy_parent_digests_parent_time"
    end
  end
end

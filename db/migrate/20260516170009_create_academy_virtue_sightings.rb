# frozen_string_literal: true

# Academy v4 — Virtue sightings: pinned moments of practiced character.
# Explicitly NOT a score. Just observations, scoped to the learner.
#
# Sources:
#   self_reported    # the kid logged it
#   parent_confirmed # parent tapped confirm
#   guide_inferred   # the Guide spotted it in conversation
class CreateAcademyVirtueSightings < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_virtue_sightings do |t|
      t.bigint :learner_id, null: false,
               comment: "Learner value-object id (no FK)"
      t.string :virtue_slug, null: false,
               comment: "honra-palavra | conserta-erro | espera | conta-verdade-que-custa | ..."
      t.text :context, null: false,
             comment: "1-2 sentences describing what happened"
      t.string :source, null: false,
               comment: "self_reported | parent_confirmed | guide_inferred"
      t.datetime :spotted_at, null: false
      t.timestamps

      t.index [ :learner_id, :virtue_slug, :spotted_at ],
              name: "idx_academy_virtue_sightings_learner_slug_time"
      t.index :source,
              name: "idx_academy_virtue_sightings_source"
    end
  end
end

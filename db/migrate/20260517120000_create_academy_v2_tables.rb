# frozen_string_literal: true

# Academy v2 — introduces trails between subject and mission, plus the
# discovery card + honor-system challenge tables.
#
# Backward compatible: trail_id is nullable; legacy missions stay tied to
# their subject directly. New v2 content always declares a trail.
class CreateAcademyV2Tables < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_trails do |t|
      t.references :subject, null: false,
                   foreign_key: { to_table: :academy_subjects },
                   index: true
      t.string  :slug,     null: false
      t.string  :title,    null: false
      t.string  :arc_hook, comment: "One-line gancho for the whole trail arc"
      t.integer :position, null: false, default: 0
      t.boolean :active,   null: false, default: true
      t.timestamps
      t.index [ :subject_id, :slug ], unique: true, name: "idx_academy_trails_subject_slug"
      t.index [ :subject_id, :position ], name: "idx_academy_trails_subject_position"
    end

    add_reference :academy_missions, :trail,
                  foreign_key: { to_table: :academy_trails },
                  null: true,
                  index: true

    add_column :academy_missions, :central_insight, :string,
               limit: 240,
               comment: "The 'se X, então Y' takeaway the kid should keep"
    add_column :academy_missions, :challenge_prompt, :text,
               comment: "Mini-desafio comportamental that anchors the lesson"
    add_column :academy_missions, :challenge_when, :string,
               comment: "When to do the challenge: hoje | esta-semana"
    add_column :academy_missions, :challenge_observable, :string,
               comment: "What the kid should notice after doing it"
    add_column :academy_missions, :curiosity_facts, :jsonb, null: false, default: []
    add_column :academy_missions, :position_in_trail, :integer
    add_column :academy_missions, :illustration_key, :string,
               comment: "Icon/illustration slug the discovery card uses"

    create_table :academy_discovery_cards do |t|
      t.bigint  :learner_id, null: false
      t.references :mission, null: false,
                   foreign_key: { to_table: :academy_missions },
                   index: true
      t.string  :illustration_key, comment: "Icon/illustration to render"
      t.string  :headline, null: false, limit: 180, comment: "1-line sacada compressed"
      t.string  :source, comment: "Author/tradition (optional, when applicable)"
      t.text    :application, comment: "1-sentence concrete application"
      t.text    :central_insight, comment: "Copied snapshot of mission insight at mint time"
      t.datetime :minted_at, null: false
      t.timestamps
      t.index [ :learner_id, :mission_id ], unique: true, name: "idx_academy_cards_unique"
      t.index [ :learner_id, :minted_at ], name: "idx_academy_cards_learner_time"
    end

    create_table :academy_challenge_reports do |t|
      t.bigint  :learner_id, null: false
      t.references :mission, null: false,
                   foreign_key: { to_table: :academy_missions },
                   index: true
      t.integer :status, null: false, default: 0,
                comment: "0=pending, 1=done, 2=partial, 3=skipped"
      t.text    :note, comment: "Optional free-text reflection from the kid"
      t.datetime :reported_at
      t.timestamps
      t.index [ :learner_id, :mission_id ], unique: true, name: "idx_academy_challenges_unique"
      t.index [ :learner_id, :status ], name: "idx_academy_challenges_learner_status"
    end
  end
end

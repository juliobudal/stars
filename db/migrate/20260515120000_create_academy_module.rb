# frozen_string_literal: true

# Creates the Academy module schema. All tables are prefixed `academy_*`
# and intentionally have no FK pointing into the host app — the module
# references learners by id only (see Academy::Learner adapter).
class CreateAcademyModule < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_subjects do |t|
      t.string  :slug,    null: false, index: { unique: true }
      t.string  :name,    null: false
      t.string  :tagline
      t.text    :angle,                comment: "Pedagogical angle the LLM should adopt"
      t.string  :color,   default: "var(--c-primary)"
      t.string  :icon,    default: "sparkle"
      t.integer :position, null: false, default: 0
      t.boolean :active,   null: false, default: true
      t.timestamps
    end

    create_table :academy_missions do |t|
      t.references :subject, null: false, foreign_key: { to_table: :academy_subjects }, index: true
      t.string  :slug, null: false
      t.string  :title, null: false
      t.string  :hook, comment: "Short mysterious teaser to entice the kid"
      t.text    :learning_objective, null: false
      t.text    :angle, comment: "Specific unique angle for this mission"
      t.integer :sessions_count, null: false, default: 4
      t.integer :order_in_subject, null: false, default: 0
      t.integer :points_reward, null: false, default: 25
      t.boolean :active, null: false, default: true
      t.timestamps
      t.index [ :subject_id, :slug ], unique: true
      t.index [ :subject_id, :order_in_subject ]
    end

    create_table :academy_mission_progresses do |t|
      t.bigint  :learner_id, null: false
      t.references :mission, null: false, foreign_key: { to_table: :academy_missions }
      t.integer :status, null: false, default: 0
      t.integer :current_session_index, null: false, default: 0
      t.integer :correct_checkpoints, null: false, default: 0
      t.integer :total_checkpoints,   null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
      t.index [ :learner_id, :mission_id ], unique: true, name: "idx_academy_progress_learner_mission"
      t.index [ :learner_id, :status ], name: "idx_academy_progress_learner_status"
    end

    create_table :academy_sessions do |t|
      t.references :mission_progress, null: false,
        foreign_key: { to_table: :academy_mission_progresses },
        index: { name: "idx_academy_sessions_progress" }
      t.integer :session_index, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.jsonb :checkpoint_result, default: {}, null: false
      t.timestamps
      t.index [ :mission_progress_id, :session_index ], unique: true, name: "idx_academy_sessions_unique_idx"
    end

    create_table :academy_messages do |t|
      t.references :session, null: false,
        foreign_key: { to_table: :academy_sessions },
        index: { name: "idx_academy_messages_session" }
      t.integer :role, null: false, default: 0
      t.text    :content, null: false
      t.jsonb   :metadata, default: {}, null: false
      t.integer :tokens
      t.timestamps
      t.index [ :session_id, :created_at ], name: "idx_academy_messages_session_time"
    end

    create_table :academy_medals do |t|
      t.string :slug, null: false, index: { unique: true }
      t.integer :kind, null: false, default: 0
      t.references :subject, foreign_key: { to_table: :academy_subjects }, null: true
      t.references :mission, foreign_key: { to_table: :academy_missions }, null: true
      t.string :name, null: false
      t.string :description
      t.string :icon, default: "medal"
      t.integer :threshold, default: 0
      t.timestamps
    end

    create_table :academy_medal_awards do |t|
      t.bigint :learner_id, null: false
      t.references :medal, null: false, foreign_key: { to_table: :academy_medals }
      t.datetime :awarded_at, null: false
      t.timestamps
      t.index [ :learner_id, :medal_id ], unique: true, name: "idx_academy_medal_awards_unique"
      t.index :learner_id, name: "idx_academy_medal_awards_learner"
    end
  end
end

# frozen_string_literal: true

# Academy redesign (spec 001) — minimal schema for "Pílulas de Conhecimento".
#
#   Trail  → ordered theme with an arc hook
#   Lesson → one curated pill (enigma → clues → revelation → check → hook)
#   LessonProgress → per-learner completion (no-FK learner_id, module isolation)
#   GuideConversation / GuideMessage → optional LLM chat scoped to a lesson
class CreateAcademyPillsSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_trails do |t|
      t.string  :slug, null: false
      t.string  :title, null: false
      t.text    :hook
      t.string  :accent, null: false, default: "green"
      t.string  :emoji
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :academy_trails, :slug, unique: true
    add_index :academy_trails, [ :active, :position ]

    create_table :academy_lessons do |t|
      t.references :trail, null: false, foreign_key: { to_table: :academy_trails }
      t.string  :slug, null: false
      t.integer :position, null: false, default: 0
      t.string  :title, null: false
      t.string  :enigma, null: false
      t.jsonb   :payload, null: false, default: {}
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :academy_lessons, :slug, unique: true
    add_index :academy_lessons, [ :trail_id, :position ], unique: true

    create_table :academy_lesson_progresses do |t|
      t.bigint   :learner_id, null: false, comment: "Learner value-object id (no FK — module isolation)"
      t.references :lesson, null: false, foreign_key: { to_table: :academy_lessons }
      t.datetime :completed_at
      t.integer  :check_choice
      t.boolean  :check_correct
      t.timestamps
    end
    add_index :academy_lesson_progresses, [ :learner_id, :lesson_id ], unique: true

    create_table :academy_guide_conversations do |t|
      t.bigint     :learner_id, null: false, comment: "Learner value-object id (no FK — module isolation)"
      t.references :lesson, null: false, foreign_key: { to_table: :academy_lessons }
      t.string     :prompt_version, null: false, default: "guide-persona@v2"
      t.datetime   :started_at, null: false
      t.datetime   :closed_at
      t.integer    :message_count, null: false, default: 0
      t.boolean    :flagged, null: false, default: false
      t.text       :flag_reasons, null: false, default: [], array: true
      t.timestamps
    end
    add_index :academy_guide_conversations, [ :learner_id, :lesson_id, :started_at ],
              name: "idx_academy_guide_conv_learner_lesson_started", order: { started_at: :desc }

    create_table :academy_guide_messages do |t|
      t.references :conversation, null: false, foreign_key: { to_table: :academy_guide_conversations }
      t.integer  :role, null: false, comment: "0 user · 1 guide · 2 system_note"
      t.text     :content, null: false
      t.integer  :tokens_in
      t.integer  :tokens_out
      t.boolean  :flagged, null: false, default: false
      t.timestamps
    end
    add_index :academy_guide_messages, [ :conversation_id, :created_at ], name: "idx_academy_guide_msg_conv_created"
  end
end

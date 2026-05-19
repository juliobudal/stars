# frozen_string_literal: true

# Guide chat — kid-side post-mission Q&A surface.
# See openspec/changes/add-guide-chat/ for rationale (design.md §5).
#
# Both tables live inside the Academy module: learner_id is a no-FK bigint
# (host isolation), mission_id is FK into academy_missions.
class CreateAcademyGuideChat < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_guide_conversations do |t|
      t.bigint :learner_id, null: false, comment: "Learner value-object id (no FK — module isolation)"
      t.references :mission, null: false,
                   foreign_key: { to_table: :academy_missions },
                   index: true
      t.datetime :started_at, null: false
      t.datetime :closed_at, comment: "Set when quota cap is hit or session expires"
      t.integer :message_count, null: false, default: 0
      t.boolean :flagged, null: false, default: false
      t.text :flag_reasons, array: true, null: false, default: []
      t.string :prompt_version, null: false, default: "guide-persona@v1",
               comment: "Frozen at conversation start so future persona iterations don't reinterpret history"
      t.timestamps
      t.index [ :learner_id, :mission_id, :started_at ],
              name: "idx_academy_guide_conv_learner_mission_started",
              order: { started_at: :desc }
      t.index [ :flagged, :started_at ],
              name: "idx_academy_guide_conv_flagged",
              where: "(flagged = true)",
              order: { started_at: :desc }
    end

    create_table :academy_guide_messages do |t|
      t.references :conversation, null: false,
                   foreign_key: { to_table: :academy_guide_conversations },
                   index: false
      t.integer :role, null: false, comment: "0 user · 1 guide · 2 system_note"
      t.text :content, null: false
      t.integer :tokens_in
      t.integer :tokens_out
      t.boolean :flagged, null: false, default: false
      t.datetime :created_at, null: false
      t.index [ :conversation_id, :created_at ],
              name: "idx_academy_guide_msg_conv_created"
    end
  end
end

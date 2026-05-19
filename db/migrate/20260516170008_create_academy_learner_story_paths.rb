# frozen_string_literal: true

# Academy v4 — Tracks which branches a learner takes in a story_choice
# mission. Used to (a) replay narrative state if the kid resumes mid-mission
# and (b) show anonymized distribution of choices at the ending.
class CreateAcademyLearnerStoryPaths < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_learner_story_paths do |t|
      t.bigint :learner_id, null: false,
               comment: "Learner value-object id (no FK)"
      t.references :mission, null: false,
                   foreign_key: { to_table: :academy_missions },
                   index: true
      t.jsonb :scene_sequence, null: false, default: [],
              comment: "Ordered: [{scene_id, choice_label, at}]"
      t.string :terminal_scene_id,
               comment: "Final scene reached, when mission ends"
      t.datetime :completed_at
      t.timestamps

      t.index [ :learner_id, :mission_id ],
              name: "idx_academy_learner_story_paths_learner_mission"
      t.index :terminal_scene_id,
              name: "idx_academy_learner_story_paths_terminal"
    end
  end
end

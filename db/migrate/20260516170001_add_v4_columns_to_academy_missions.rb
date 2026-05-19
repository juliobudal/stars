# frozen_string_literal: true

# Academy v4 — Adds mission format support (story_choice, pattern_meta)
# plus the explicit "teaser_for_next_mission" link used by Beat 7 of the
# v4 Guide persona.
class AddV4ColumnsToAcademyMissions < ActiveRecord::Migration[8.1]
  def change
    add_column :academy_missions, :format, :string, null: false, default: "discovery",
               comment: "discovery | story_choice | pattern_meta"
    add_column :academy_missions, :scenes_tree, :jsonb, null: false, default: {},
               comment: "story_choice only: nodes[], terminal_ids[]"
    add_reference :academy_missions, :teaser_for_next_mission,
                  foreign_key: { to_table: :academy_missions },
                  null: true,
                  index: { name: "idx_academy_missions_teaser_for_next" },
                  comment: "Beat 7 narrative link — silhouette of next pattern"

    add_index :academy_missions, :format, name: "idx_academy_missions_format"
  end
end

# frozen_string_literal: true

class DropV4ColumnsFromAcademyMissions < ActiveRecord::Migration[8.0]
  def up
    if foreign_key_exists?(:academy_missions, column: :teaser_for_next_mission_id)
      remove_foreign_key :academy_missions, column: :teaser_for_next_mission_id
    end

    if index_exists?(:academy_missions, :teaser_for_next_mission_id, name: "idx_academy_missions_teaser_for_next")
      remove_index :academy_missions, name: "idx_academy_missions_teaser_for_next"
    elsif index_exists?(:academy_missions, :teaser_for_next_mission_id)
      remove_index :academy_missions, :teaser_for_next_mission_id
    end

    if index_exists?(:academy_missions, :format, name: "idx_academy_missions_format")
      remove_index :academy_missions, name: "idx_academy_missions_format"
    end

    remove_column :academy_missions, :format
    remove_column :academy_missions, :scenes_tree
    remove_column :academy_missions, :sessions_count
    remove_column :academy_missions, :teaser_for_next_mission_id
  end

  def down
    add_column :academy_missions, :format, :string, default: "discovery", null: false,
               comment: "discovery | story_choice | pattern_meta"
    add_column :academy_missions, :scenes_tree, :jsonb, default: {}, null: false,
               comment: "story_choice only: nodes[], terminal_ids[]"
    add_column :academy_missions, :sessions_count, :integer, default: 4, null: false
    add_column :academy_missions, :teaser_for_next_mission_id, :bigint,
               comment: "Beat 7 narrative link — silhouette of next pattern"

    add_index :academy_missions, :format, name: "idx_academy_missions_format"
    add_index :academy_missions, :teaser_for_next_mission_id, name: "idx_academy_missions_teaser_for_next"
    add_foreign_key :academy_missions, :academy_missions, column: :teaser_for_next_mission_id
  end
end

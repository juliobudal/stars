# frozen_string_literal: true

# Curated-static pivot (.planning/designs/academy-curated-static-pivot.md).
# Marks a row as human-authored ('curated') vs LLM-generated ('llm'). Runtime
# prefers curated rows; LLM stays as fallback for un-curated combos.
class AddSourceToAcademyLensCache < ActiveRecord::Migration[8.0]
  def change
    add_column :academy_lens_cache, :source, :string, default: "llm", null: false

    add_index :academy_lens_cache,
              [:concept_id, :lens_type, :source],
              name: "idx_academy_lens_cache_source_lookup"
  end
end

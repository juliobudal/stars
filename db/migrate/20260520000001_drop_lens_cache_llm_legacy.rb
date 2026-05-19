# frozen_string_literal: true

# Drops vestigial columns + indexes from `academy_lens_cache` left over
# from the retired LLM generation pipeline. After the curated-static
# pivot the unique key is just (concept_id, lens_type, age_band, locale)
# — template_version, mastery_tier and prompt_digest carried constant
# values ("curated.v1" / "any" / "curated") and the LLM judge/token
# columns were never read by the curated path.
#
# Also purges historical source='llm' rows: Lens::Generate only serves
# `source: 'curated'` rows, so the legacy LLM rows were dead data.
#
# Irreversible — the dropped columns + LLM rows have no business value
# and reversing would require synthesising values.
class DropLensCacheLlmLegacy < ActiveRecord::Migration[8.1]
  def up
    # Null-out lens_cache_id on visits that reference LLM-source rows.
    # learner_lens_visit.lens_cache_id is already optional — preserving
    # the visit (kid's learning history) while letting the cache row go.
    say_with_time "Null-ing lens_cache_id on visits to legacy LLM rows" do
      execute(<<~SQL)
        UPDATE academy_learner_lens_visits
        SET lens_cache_id = NULL
        WHERE lens_cache_id IN (
          SELECT id FROM academy_lens_cache WHERE source = 'llm'
        )
      SQL
    end

    say_with_time "Purging legacy LLM-source rows" do
      execute("DELETE FROM academy_lens_cache WHERE source = 'llm'")
    end

    remove_index :academy_lens_cache, name: :idx_academy_lens_cache_unique
    remove_index :academy_lens_cache, name: :idx_academy_lens_cache_judge_verdict

    remove_column :academy_lens_cache, :template_version
    remove_column :academy_lens_cache, :mastery_tier
    remove_column :academy_lens_cache, :prompt_digest
    remove_column :academy_lens_cache, :model_id
    remove_column :academy_lens_cache, :tokens_in
    remove_column :academy_lens_cache, :tokens_out
    remove_column :academy_lens_cache, :judge_critique
    remove_column :academy_lens_cache, :judge_overall_score
    remove_column :academy_lens_cache, :judge_verdict
    remove_column :academy_lens_cache, :judge_revision_cycles

    change_column_default :academy_lens_cache, :source, from: "llm", to: "curated"

    add_index :academy_lens_cache,
              %i[concept_id lens_type age_band locale],
              unique: true,
              name: :idx_academy_lens_cache_unique
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Curated-static pivot dropped the LLM-gen columns; reversal would require synthesising values."
  end
end

# frozen_string_literal: true

# Allows a curated payload to be tagged with an interest slug (from
# config/profile_interests.yml). `Lens::ResolveCuratedPayload` then prefers
# a row matching the learner's top interest, falling back to the
# interest_key=NULL "default" row when no variant exists.
#
# Existing rows stay unchanged (interest_key = NULL = default variant).
# The unique index is widened so a concept can carry one default row + N
# per-interest variants per (lens_type, age_band, locale).
class AddInterestKeyToAcademyLensCache < ActiveRecord::Migration[8.1]
  def up
    add_column :academy_lens_cache, :interest_key, :string

    remove_index :academy_lens_cache, name: :idx_academy_lens_cache_unique
    # Use COALESCE so NULL interest_key collapses to the same slot, which
    # preserves the old "one row per (concept, lens, age, locale)"
    # invariant for default rows while still allowing interest variants.
    execute <<~SQL.squish
      CREATE UNIQUE INDEX idx_academy_lens_cache_unique
      ON academy_lens_cache (concept_id, lens_type, age_band, locale, COALESCE(interest_key, ''))
    SQL

    add_index :academy_lens_cache, :interest_key,
              where: "interest_key IS NOT NULL",
              name: :idx_academy_lens_cache_interest_key
  end

  def down
    remove_index :academy_lens_cache, name: :idx_academy_lens_cache_interest_key
    remove_index :academy_lens_cache, name: :idx_academy_lens_cache_unique
    add_index :academy_lens_cache, [:concept_id, :lens_type, :age_band, :locale],
              unique: true, name: :idx_academy_lens_cache_unique
    remove_column :academy_lens_cache, :interest_key
  end
end

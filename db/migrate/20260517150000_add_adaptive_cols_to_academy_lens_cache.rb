# frozen_string_literal: true

class AddAdaptiveColsToAcademyLensCache < ActiveRecord::Migration[8.1]
  def up
    # mastery_tier: bucket of the learner's pokédex level at generation time.
    #   "any"          — generated without a learner (warmup / prewarm)
    #   "introductory" — learner had level 0..1 (silhouette / spotted)
    #   "advanced"     — learner had level 2..3 (recognized / mastered)
    # Caps cardinality at 3 versions per (concept, lens, age, locale, template, digest).
    add_column :academy_lens_cache, :mastery_tier, :string, default: "any", null: false

    # prompt_digest: first 8 chars of SHA256 of the rendered ERB template source
    # at generation time. Bumps automatically when prompt content changes — no
    # more "I edited the prompt but cache served the old payload" surprises.
    add_column :academy_lens_cache, :prompt_digest, :string, default: "legacy", null: false

    remove_index :academy_lens_cache, name: :idx_academy_lens_cache_unique
    add_index :academy_lens_cache,
              %i[concept_id lens_type age_band locale template_version mastery_tier prompt_digest],
              unique: true, name: :idx_academy_lens_cache_unique
  end

  def down
    remove_index :academy_lens_cache, name: :idx_academy_lens_cache_unique
    add_index :academy_lens_cache,
              %i[concept_id lens_type age_band locale template_version],
              unique: true, name: :idx_academy_lens_cache_unique
    remove_column :academy_lens_cache, :prompt_digest
    remove_column :academy_lens_cache, :mastery_tier
  end
end

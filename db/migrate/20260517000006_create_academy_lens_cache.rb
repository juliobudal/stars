# frozen_string_literal: true

class CreateAcademyLensCache < ActiveRecord::Migration[8.0]
  def change
    create_table :academy_lens_cache do |t|
      t.bigint :concept_id, null: false
      t.string :lens_type, null: false
      t.string :age_band, null: false, default: "kid"
      t.string :locale, null: false, default: "pt-BR"
      t.string :template_version, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :model_id
      t.integer :tokens_in
      t.integer :tokens_out
      t.datetime :generated_at, null: false
      t.boolean :quality_flagged, null: false, default: false

      t.timestamps
    end

    add_index :academy_lens_cache,
              [:concept_id, :lens_type, :age_band, :locale, :template_version],
              unique: true,
              name: "idx_academy_lens_cache_unique"
    add_index :academy_lens_cache, :lens_type
    add_index :academy_lens_cache, :quality_flagged,
              where: "quality_flagged = true",
              name: "idx_academy_lens_cache_quality_flagged"

    add_foreign_key :academy_lens_cache, :academy_concepts, column: :concept_id
  end
end

# frozen_string_literal: true

# One row per (learner, lens_cache) tracking the "Pílula do Dia" surface.
# Independent of MissionProgress / LearnerLensVisit on purpose — pílulas
# are the lowest-friction Academy surface (60-90s, no mission required).
#
# `learner_id` is the Academy boundary id (Profile.id in practice). No FK
# to host tables — same convention as other Academy:: tables.
class CreateAcademyPillViews < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_pill_views do |t|
      t.bigint  :learner_id,    null: false
      t.bigint  :lens_cache_id, null: false
      t.string  :status,        null: false, default: "served"
      t.integer :micro_check_choice
      t.boolean :micro_check_correct
      t.boolean :shared_with_parent, null: false, default: false
      t.datetime :viewed_at
      t.timestamps
    end

    add_foreign_key :academy_pill_views, :academy_lens_cache, column: :lens_cache_id
    add_index :academy_pill_views, [ :learner_id, :created_at ],
              name: :idx_academy_pill_views_by_learner_recency
    add_index :academy_pill_views, [ :learner_id, :lens_cache_id ], unique: true,
              name: :idx_academy_pill_views_unique_per_learner
  end
end

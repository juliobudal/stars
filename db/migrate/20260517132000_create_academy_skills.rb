# frozen_string_literal: true

# Academy v2 Phase 7 — Skills (radar) + Rank (cross-area identity).
#
# 9 fixed skills tracked across all areas. Each mission declares 1-2 primary
# skills. Each correct checkpoint + each reported challenge awards points.
# Rank is recomputed from card counts + skills + areas — cached for cheap
# reads on the home header.
class CreateAcademySkills < ActiveRecord::Migration[8.1]
  def change
    create_table :academy_skills do |t|
      t.string  :slug,     null: false, index: { unique: true }
      t.string  :name,     null: false
      t.string  :icon,     null: false, default: "sparkle"
      t.string  :short_label, comment: "Kid-facing 1-word label for the radar"
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :academy_aula_skills do |t|
      t.references :mission, null: false,
                   foreign_key: { to_table: :academy_missions },
                   index: true
      t.references :skill, null: false,
                   foreign_key: { to_table: :academy_skills },
                   index: true
      t.integer :weight, null: false, default: 1,
                comment: "How much this skill is exercised by this aula (1=co-primary, 2=primary)"
      t.timestamps
      t.index [ :mission_id, :skill_id ], unique: true,
              name: "idx_academy_aula_skills_unique"
    end

    create_table :academy_learner_skills do |t|
      t.bigint  :learner_id, null: false
      t.references :skill, null: false,
                   foreign_key: { to_table: :academy_skills },
                   index: true
      t.integer :score, null: false, default: 0
      t.datetime :last_event_at
      t.timestamps
      t.index [ :learner_id, :skill_id ], unique: true,
              name: "idx_academy_learner_skills_unique"
      t.index :learner_id, name: "idx_academy_learner_skills_learner"
    end

    create_table :academy_learner_ranks do |t|
      t.bigint  :learner_id, null: false
      t.integer :rank, null: false, default: 0,
                comment: "0=aprendiz, 1=explorador, 2=construtor, 3=estrategista, 4=criador, 5=mentor"
      t.timestamps
      t.index :learner_id, unique: true, name: "idx_academy_learner_rank_unique"
    end
  end
end

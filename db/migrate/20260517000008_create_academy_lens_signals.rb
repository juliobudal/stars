# frozen_string_literal: true

class CreateAcademyLensSignals < ActiveRecord::Migration[8.0]
  def change
    create_table :academy_lens_signals do |t|
      t.bigint :mission_progress_id, null: false
      t.bigint :lens_visit_id
      t.bigint :learner_id, null: false
      t.bigint :concept_id, null: false
      t.string :lens_type, null: false
      t.string :signal_type, null: false,
               comment: "time_on_lens | micro_check_correct | micro_check_wrong | abandoned | self_report_easy | self_report_hard | transfer_hint"
      t.decimal :numeric_value, precision: 12, scale: 4,
                comment: "Seconds, scores, etc; nullable"
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :academy_lens_signals,
              [:mission_progress_id, :recorded_at],
              name: "idx_academy_lens_signals_progress_time"
    add_index :academy_lens_signals,
              [:learner_id, :signal_type, :recorded_at],
              name: "idx_academy_lens_signals_learner_type_time"
    add_index :academy_lens_signals,
              [:learner_id, :concept_id, :lens_type, :recorded_at],
              name: "idx_academy_lens_signals_learner_concept_lens_time"

    add_foreign_key :academy_lens_signals, :academy_mission_progresses, column: :mission_progress_id
    add_foreign_key :academy_lens_signals, :academy_learner_lens_visits, column: :lens_visit_id
  end
end

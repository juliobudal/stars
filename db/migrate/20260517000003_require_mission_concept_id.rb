# frozen_string_literal: true

class RequireMissionConceptId < ActiveRecord::Migration[8.0]
  def up
    change_column_null :academy_missions, :concept_id, false
  end

  def down
    change_column_null :academy_missions, :concept_id, true
  end
end

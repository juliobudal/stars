# frozen_string_literal: true

# Promote curation metadata to explicit columns on academy_missions so the
# parent surface can filter/browse by source and framework, and so the
# Guide prompt can read them without parsing the angle blob.
#
# All columns are nullable — old missions stay valid.
class AddCurationFieldsToAcademyMissions < ActiveRecord::Migration[8.1]
  def change
    add_column :academy_missions, :source, :string,
               comment: "Author(s)/tradition/study the pílula distills (e.g. 'Carnegie', 'Marco Aurélio', 'Provérbios')"
    add_column :academy_missions, :framework, :string,
               comment: "Didactic frame: socratic | story | metaphor | case | thought_experiment | paradox | historical_scene"
    add_column :academy_missions, :sacada, :text,
               comment: "The 1-line counter-intuitive insight (the 'pílula' itself)"

    add_index :academy_missions, :source
    add_index :academy_missions, :framework
  end
end

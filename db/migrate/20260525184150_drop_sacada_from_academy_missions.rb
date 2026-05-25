class DropSacadaFromAcademyMissions < ActiveRecord::Migration[8.1]
  def change
    remove_column :academy_missions, :sacada, :text,
                  comment: "The 1-line counter-intuitive insight (the 'pílula' itself)"
  end
end

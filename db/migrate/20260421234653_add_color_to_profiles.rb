class AddColorToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :color, :string
  end
end

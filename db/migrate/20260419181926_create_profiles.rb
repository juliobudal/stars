class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.references :family, null: false, foreign_key: true
      t.string :name
      t.string :avatar
      t.integer :role
      t.integer :points, default: 0

      t.timestamps
    end
  end
end

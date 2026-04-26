class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :family, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.string :icon, null: false
      t.string :color, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :categories, [ :family_id, :name ], unique: true
    add_index :categories, [ :family_id, :position ]
  end
end

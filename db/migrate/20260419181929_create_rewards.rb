class CreateRewards < ActiveRecord::Migration[8.1]
  def change
    create_table :rewards do |t|
      t.references :family, null: false, foreign_key: true
      t.string :title
      t.integer :cost
      t.string :icon

      t.timestamps
    end
  end
end

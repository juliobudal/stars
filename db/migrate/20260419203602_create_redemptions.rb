class CreateRedemptions < ActiveRecord::Migration[8.1]
  def change
    create_table :redemptions do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :reward, null: false, foreign_key: true
      t.integer :status
      t.integer :points

      t.timestamps
    end
  end
end

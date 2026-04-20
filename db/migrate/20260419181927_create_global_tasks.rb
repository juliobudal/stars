class CreateGlobalTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :global_tasks do |t|
      t.references :family, null: false, foreign_key: true
      t.string :title
      t.integer :category
      t.integer :points
      t.integer :frequency
      t.integer :days_of_week, array: true, default: []

      t.timestamps
    end
  end
end

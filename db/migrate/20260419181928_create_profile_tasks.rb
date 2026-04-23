class CreateProfileTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :profile_tasks do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :global_task, null: false, foreign_key: true
      t.integer :status, default: 0
      t.datetime :completed_at
      t.date :assigned_date

      t.timestamps
    end

    add_index :profile_tasks, [ :profile_id, :assigned_date ]
    add_index :profile_tasks, [ :profile_id, :status ]
  end
end

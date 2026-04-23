class CreateGlobalTaskAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :global_task_assignments do |t|
      t.references :global_task, null: false, foreign_key: { on_delete: :cascade }
      t.references :profile, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end

    add_index :global_task_assignments, [ :global_task_id, :profile_id ], unique: true, name: "idx_global_task_assignments_unique"
  end
end

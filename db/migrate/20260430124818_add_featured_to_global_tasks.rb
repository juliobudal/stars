class AddFeaturedToGlobalTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :global_tasks, :featured, :boolean, default: false, null: false
    add_index :global_tasks, [ :family_id, :featured ], where: "featured = true"
  end
end

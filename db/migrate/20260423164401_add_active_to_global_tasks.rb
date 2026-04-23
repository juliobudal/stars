class AddActiveToGlobalTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :global_tasks, :active, :boolean, default: true, null: false
  end
end

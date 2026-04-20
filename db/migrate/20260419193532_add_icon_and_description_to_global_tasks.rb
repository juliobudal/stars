class AddIconAndDescriptionToGlobalTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :global_tasks, :icon, :string
    add_column :global_tasks, :description, :text
  end
end

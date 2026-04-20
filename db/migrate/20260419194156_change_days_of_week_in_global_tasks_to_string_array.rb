class ChangeDaysOfWeekInGlobalTasksToStringArray < ActiveRecord::Migration[8.1]
  def change
    remove_column :global_tasks, :days_of_week
    add_column :global_tasks, :days_of_week, :string, array: true, default: []
  end
end

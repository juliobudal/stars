class AddDayOfMonthToGlobalTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :global_tasks, :day_of_month, :integer
  end
end

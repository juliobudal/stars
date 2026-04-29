class AddMaxCompletionsPerPeriodToGlobalTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :global_tasks, :max_completions_per_period, :integer, default: 1, null: false
    add_check_constraint :global_tasks,
      "max_completions_per_period >= 1",
      name: "max_completions_positive"
  end
end

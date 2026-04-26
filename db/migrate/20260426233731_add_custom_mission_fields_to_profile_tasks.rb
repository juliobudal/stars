class AddCustomMissionFieldsToProfileTasks < ActiveRecord::Migration[8.1]
  def change
    change_column_null :profile_tasks, :global_task_id, true

    add_column :profile_tasks, :source,              :integer, default: 0, null: false
    add_column :profile_tasks, :custom_title,        :string
    add_column :profile_tasks, :custom_description,  :text
    add_column :profile_tasks, :custom_points,       :integer
    add_reference :profile_tasks, :custom_category,
                  foreign_key: { to_table: :categories, on_delete: :nullify },
                  null: true
    add_column :profile_tasks, :submission_comment,  :text

    add_index :profile_tasks, :source
  end
end

class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_logs do |t|
      t.references :profile, null: false, foreign_key: true
      t.integer :log_type
      t.string :title
      t.integer :points

      t.timestamps
    end

    add_index :activity_logs, [ :profile_id, :created_at ]
  end
end

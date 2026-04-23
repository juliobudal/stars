class AddDecayedAtToActivityLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :activity_logs, :decayed_at, :datetime

    add_index :activity_logs, :decayed_at,
              where: "decayed_at IS NULL AND log_type = 0",
              name: "index_activity_logs_undecayed_earns"
  end
end

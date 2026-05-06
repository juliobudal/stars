class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :profiles, [ :family_id, :role ], algorithm: :concurrently, if_not_exists: true
    add_index :redemptions, [ :profile_id, :status ], algorithm: :concurrently, if_not_exists: true
    add_index :activity_logs, [ :profile_id, :log_type ], algorithm: :concurrently, if_not_exists: true
  end
end

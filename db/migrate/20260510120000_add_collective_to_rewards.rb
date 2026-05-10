class AddCollectiveToRewards < ActiveRecord::Migration[8.1]
  def change
    add_column :rewards, :collective, :boolean, default: false, null: false
    add_column :redemptions, :collective, :boolean, default: false, null: false
    add_index  :rewards, :collective
  end
end

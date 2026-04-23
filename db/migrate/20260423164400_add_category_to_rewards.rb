class AddCategoryToRewards < ActiveRecord::Migration[8.1]
  def change
    add_column :rewards, :category, :integer, default: 5, null: false
  end
end

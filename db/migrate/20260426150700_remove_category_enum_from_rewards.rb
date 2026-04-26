class RemoveCategoryEnumFromRewards < ActiveRecord::Migration[8.1]
  def up
    change_column_null :rewards, :category_id, false
    remove_column :rewards, :category
  end

  def down
    add_column :rewards, :category, :integer, default: 5, null: false
    change_column_null :rewards, :category_id, true
  end
end

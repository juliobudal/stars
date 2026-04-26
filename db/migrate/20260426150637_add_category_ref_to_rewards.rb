class AddCategoryRefToRewards < ActiveRecord::Migration[8.1]
  def change
    add_reference :rewards, :category, null: true, foreign_key: true, index: true
  end
end

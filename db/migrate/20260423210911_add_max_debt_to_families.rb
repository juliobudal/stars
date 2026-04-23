class AddMaxDebtToFamilies < ActiveRecord::Migration[8.1]
  def change
    add_column :families, :max_debt, :integer, default: 100, null: false
  end
end

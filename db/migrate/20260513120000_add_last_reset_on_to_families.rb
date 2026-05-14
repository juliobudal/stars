class AddLastResetOnToFamilies < ActiveRecord::Migration[8.1]
  def change
    add_column :families, :last_reset_on, :date
  end
end

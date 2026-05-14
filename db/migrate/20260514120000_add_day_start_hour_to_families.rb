class AddDayStartHourToFamilies < ActiveRecord::Migration[8.1]
  def change
    add_column :families, :day_start_hour, :integer, default: 0, null: false
  end
end

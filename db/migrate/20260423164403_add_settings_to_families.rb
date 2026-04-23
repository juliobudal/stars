class AddSettingsToFamilies < ActiveRecord::Migration[8.1]
  def change
    add_column :families, :locale, :string, default: "pt-BR"
    add_column :families, :timezone, :string, default: "America/Sao_Paulo"
    add_column :families, :week_start, :integer, default: 1
    add_column :families, :require_photo, :boolean, default: false
    add_column :families, :decay_enabled, :boolean, default: false
    add_column :families, :allow_negative, :boolean, default: false
    add_column :families, :auto_approve_threshold, :integer
  end
end

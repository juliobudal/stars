class RefactorAuthToFamilyAndPin < ActiveRecord::Migration[8.1]
  def change
    enable_extension "citext" unless extension_enabled?("citext")

    add_column :families, :email, :citext
    add_column :families, :password_digest, :string
    add_index  :families, :email, unique: true

    add_column :profiles, :pin_digest, :string

    remove_index  :profiles, name: "index_profiles_on_email_parent", if_exists: true
    remove_column :profiles, :password_digest, :string
    remove_column :profiles, :confirmed_at, :datetime
  end
end

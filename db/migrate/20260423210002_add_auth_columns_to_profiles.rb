class AddAuthColumnsToProfiles < ActiveRecord::Migration[8.1]
  def up
    add_column :profiles, :email, :citext
    add_column :profiles, :password_digest, :string
    add_column :profiles, :confirmed_at, :datetime

    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE UNIQUE INDEX index_profiles_on_email_parent ON profiles (email) WHERE role = 1;
        SQL
      end
    end

    Profile.where(role: :parent, email: nil).find_each do |p|
      p.update_columns(email: "parent-#{p.id}@placeholder.local", confirmed_at: Time.current)
    end
  end

  def down
    execute "DROP INDEX IF EXISTS index_profiles_on_email_parent;"
    remove_column :profiles, :confirmed_at
    remove_column :profiles, :password_digest
    remove_column :profiles, :email
  end
end

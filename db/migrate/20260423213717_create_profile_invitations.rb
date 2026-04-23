class CreateProfileInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :profile_invitations do |t|
      t.references :family, null: false, foreign_key: { on_delete: :cascade }
      t.string :email, null: false
      t.string :token, null: false
      t.bigint :invited_by_id
      t.datetime :accepted_at
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :profile_invitations, :token, unique: true
    add_foreign_key :profile_invitations, :profiles, column: :invited_by_id, on_delete: :nullify
  end
end

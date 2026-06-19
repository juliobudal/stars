# frozen_string_literal: true

# Stops storing the family-join invitation token in plaintext. The raw token
# now lives only in the emailed acceptance URL; the DB keeps a SHA256 digest
# (token_digest) so a DB read (backup, log, SQLi) can't replay an unaccepted
# invite. Backfills digests from existing plaintext tokens first, so invites
# already in flight keep working, then drops the plaintext column.
class ReplaceInvitationTokenWithDigest < ActiveRecord::Migration[8.1]
  # Throwaway model so the migration doesn't depend on the real
  # ProfileInvitation (whose validations/callbacks reference the new column).
  class MigrationInvitation < ActiveRecord::Base
    self.table_name = "profile_invitations"
  end

  def up
    add_column :profile_invitations, :token_digest, :string

    MigrationInvitation.reset_column_information
    MigrationInvitation.where(token_digest: nil).find_each do |inv|
      inv.update_columns(token_digest: Digest::SHA256.hexdigest(inv.token.to_s))
    end

    change_column_null :profile_invitations, :token_digest, false
    add_index :profile_invitations, :token_digest, unique: true

    remove_index :profile_invitations, :token, unique: true
    remove_column :profile_invitations, :token
  end

  def down
    add_column :profile_invitations, :token, :string

    # Raw tokens can't be recovered from digests; regenerate so the column is
    # populated + unique again (this invalidates outstanding invites).
    MigrationInvitation.reset_column_information
    MigrationInvitation.where(token: nil).find_each do |inv|
      inv.update_columns(token: SecureRandom.urlsafe_base64(32))
    end

    change_column_null :profile_invitations, :token, false
    add_index :profile_invitations, :token, unique: true

    remove_index :profile_invitations, :token_digest, unique: true
    remove_column :profile_invitations, :token_digest
  end
end

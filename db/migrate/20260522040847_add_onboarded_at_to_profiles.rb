class AddOnboardedAtToProfiles < ActiveRecord::Migration[8.1]
  def up
    add_column :profiles, :onboarded_at, :datetime

    Profile.reset_column_information
    Profile.where(role: :child).update_all(onboarded_at: Time.current)
  end

  def down
    remove_column :profiles, :onboarded_at
  end
end

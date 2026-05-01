class AddWishlistRewardIdToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_reference :profiles, :wishlist_reward,
                  foreign_key: { to_table: :rewards, on_delete: :nullify },
                  null: true,
                  index: true
  end
end

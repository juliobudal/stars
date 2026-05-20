# frozen_string_literal: true

# Stores 3-5 self-declared interest tags per kid profile. Powers
# Academy::Lens personalization (narrative.character + analogy_bridge.source_domain)
# and may grow into a "Lightning Round" filter later.
#
# `interest_key` is a slug from config/profile_interests.yml — kept as plain
# string (not FK) because the catalog is small, versioned in git, and a
# missing key should degrade silently rather than break with FK violation.
# `rank` is the order the kid clicked them (1=top, 2, 3...) so we can favor
# the top interest in single-slot prompts.
class CreateProfileInterests < ActiveRecord::Migration[8.1]
  def change
    create_table :profile_interests do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :interest_key, null: false
      t.integer :rank, null: false, default: 0
      t.timestamps
    end

    add_index :profile_interests, [:profile_id, :interest_key], unique: true,
              name: :idx_profile_interests_unique_per_profile
    add_index :profile_interests, [:profile_id, :rank]
  end
end

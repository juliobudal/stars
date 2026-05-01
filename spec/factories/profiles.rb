# == Schema Information
#
# Table name: profiles
#
#  id                 :bigint           not null, primary key
#  avatar             :string
#  color              :string
#  email              :citext
#  name               :string
#  pin_digest         :string
#  points             :integer          default(0)
#  role               :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  family_id          :bigint           not null
#  wishlist_reward_id :bigint
#
# Indexes
#
#  index_profiles_on_family_id           (family_id)
#  index_profiles_on_wishlist_reward_id  (wishlist_reward_id)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#  fk_rails_...  (wishlist_reward_id => rewards.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :profile do
    family
    sequence(:name) { |n| "Profile #{n}" }
    avatar { nil }
    role { :child }
    points { 0 }
    pin { "1234" }

    trait :parent do
      role { :parent }
      sequence(:email) { |n| "parent#{n}@example.com" }
    end

    trait :child do
      role { :child }
    end
  end
end

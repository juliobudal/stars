# == Schema Information
#
# Table name: redemptions
#
#  id         :bigint           not null, primary key
#  points     :integer
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  profile_id :bigint           not null
#  reward_id  :bigint           not null
#
# Indexes
#
#  index_redemptions_on_profile_id  (profile_id)
#  index_redemptions_on_reward_id   (reward_id)
#
# Foreign Keys
#
#  fk_rails_...  (profile_id => profiles.id)
#  fk_rails_...  (reward_id => rewards.id)
#
FactoryBot.define do
  factory :redemption do
    profile { nil }
    reward { nil }
    status { 1 }
    points { 1 }
  end
end

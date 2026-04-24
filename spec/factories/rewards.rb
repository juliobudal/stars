# == Schema Information
#
# Table name: rewards
#
#  id         :bigint           not null, primary key
#  category   :integer          default("outro"), not null
#  cost       :integer
#  icon       :string
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  family_id  :bigint           not null
#
# Indexes
#
#  index_rewards_on_family_id  (family_id)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#
FactoryBot.define do
  factory :reward do
    family
    title { Faker::Commerce.product_name }
    cost { 50 }
    icon { nil }
  end
end

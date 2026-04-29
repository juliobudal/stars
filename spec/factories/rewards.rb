# == Schema Information
#
# Table name: rewards
#
#  id          :bigint           not null, primary key
#  cost        :integer
#  icon        :string
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category_id :bigint           not null
#  family_id   :bigint           not null
#
# Indexes
#
#  index_rewards_on_category_id  (category_id)
#  index_rewards_on_family_id    (family_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (family_id => families.id)
#
FactoryBot.define do
  factory :reward do
    family
    title { Faker::Commerce.product_name }
    cost { 50 }
    icon { nil }
    category { family.categories.first || association(:category, family: family) }
  end
end

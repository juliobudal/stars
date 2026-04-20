FactoryBot.define do
  factory :reward do
    family
    title { Faker::Commerce.product_name }
    cost { 50 }
    icon { nil }
  end
end

FactoryBot.define do
  factory :reward do
    family
    title { Faker::Commerce.product_name }
    cost { 50 }
    icon { nil }
    category { family.categories.first || association(:category, family: family) }
  end
end

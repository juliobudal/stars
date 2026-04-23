FactoryBot.define do
  factory :profile do
    family
    name { Faker::Name.first_name }
    avatar { nil }
    role { :child }
    points { 0 }

    trait :parent do
      role { :parent }
      sequence(:email) { |n| "parent#{n}@example.com" }
      password { "supersecret1234" }
      confirmed_at { Time.current }
    end

    trait :child do
      role { :child }
    end
  end
end

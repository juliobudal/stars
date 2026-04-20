FactoryBot.define do
  factory :global_task do
    family
    title { Faker::Lorem.sentence }
    category { :casa }
    points { 10 }
    frequency { :daily }
    icon { "⭐" }
    description { Faker::Lorem.paragraph }
    days_of_week { [] }

    trait :daily do
      frequency { :daily }
    end

    trait :weekly do
      frequency { :weekly }
    end
  end
end

FactoryBot.define do
  factory :activity_log do
    profile
    log_type { :earn }
    title { Faker::Lorem.sentence }
    points { 10 }

    trait :earn do
      log_type { :earn }
    end

    trait :redeem do
      log_type { :redeem }
    end

    trait :task_completed do
      log_type { :earn }
    end
  end
end

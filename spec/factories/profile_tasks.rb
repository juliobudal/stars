FactoryBot.define do
  factory :profile_task do
    profile
    global_task
    status { :pending }
    completed_at { nil }
    assigned_date { Date.current }

    trait :pending do
      status { :pending }
    end

    trait :awaiting_approval do
      status { :awaiting_approval }
    end

    trait :approved do
      status { :approved }
    end

    trait :rejected do
      status { :rejected }
    end
  end
end

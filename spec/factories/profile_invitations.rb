FactoryBot.define do
  factory :profile_invitation do
    family
    association :invited_by, factory: [:profile, :parent]
    sequence(:email) { |n| "invitee#{n}@example.com" }
    expires_at { 7.days.from_now }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :accepted do
      accepted_at { 1.hour.ago }
    end
  end
end

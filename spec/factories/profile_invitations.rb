# == Schema Information
#
# Table name: profile_invitations
#
#  id            :bigint           not null, primary key
#  accepted_at   :datetime
#  email         :string           not null
#  expires_at    :datetime         not null
#  token         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  family_id     :bigint           not null
#  invited_by_id :bigint
#
# Indexes
#
#  index_profile_invitations_on_family_id  (family_id)
#  index_profile_invitations_on_token      (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id) ON DELETE => cascade
#  fk_rails_...  (invited_by_id => profiles.id) ON DELETE => nullify
#
FactoryBot.define do
  factory :profile_invitation do
    family
    association :invited_by, factory: [ :profile, :parent ]
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

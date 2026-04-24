# == Schema Information
#
# Table name: activity_logs
#
#  id         :bigint           not null, primary key
#  decayed_at :datetime
#  log_type   :integer
#  points     :integer
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  profile_id :bigint           not null
#
# Indexes
#
#  index_activity_logs_on_profile_id                 (profile_id)
#  index_activity_logs_on_profile_id_and_created_at  (profile_id,created_at)
#  index_activity_logs_undecayed_earns               (decayed_at) WHERE ((decayed_at IS NULL) AND (log_type = 0))
#
# Foreign Keys
#
#  fk_rails_...  (profile_id => profiles.id)
#
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

# == Schema Information
#
# Table name: profile_tasks
#
#  id             :bigint           not null, primary key
#  assigned_date  :date
#  completed_at   :datetime
#  status         :integer          default("pending")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  global_task_id :bigint           not null
#  profile_id     :bigint           not null
#
# Indexes
#
#  index_profile_tasks_on_global_task_id                (global_task_id)
#  index_profile_tasks_on_profile_id                    (profile_id)
#  index_profile_tasks_on_profile_id_and_assigned_date  (profile_id,assigned_date)
#  index_profile_tasks_on_profile_id_and_status         (profile_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (global_task_id => global_tasks.id)
#  fk_rails_...  (profile_id => profiles.id)
#
FactoryBot.define do
  factory :profile_task do
    profile
    global_task
    status { :pending }
    completed_at { nil }
    assigned_date { Date.current }
    source { :catalog }

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

    trait :custom do
      global_task { nil }
      source { :custom }
      custom_title { "Arrumei a estante" }
      custom_description { "Tirei o pó e organizei os livros" }
      custom_points { 25 }
      custom_category { association(:category) }
      status { :awaiting_approval }
      completed_at { Time.current }
    end
  end
end

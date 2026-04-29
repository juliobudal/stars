# == Schema Information
#
# Table name: global_tasks
#
#  id           :bigint           not null, primary key
#  active       :boolean          default(TRUE), not null
#  category     :integer
#  day_of_month :integer
#  days_of_week :string           default([]), is an Array
#  description  :text
#  frequency    :integer
#  icon         :string
#  points       :integer
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  family_id    :bigint           not null
#
# Indexes
#
#  index_global_tasks_on_family_id  (family_id)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#
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
    max_completions_per_period { 1 }

    trait :repeatable do
      max_completions_per_period { 3 }
    end

    trait :daily do
      frequency { :daily }
    end

    trait :weekly do
      frequency { :weekly }
    end
  end
end

# == Schema Information
#
# Table name: families
#
#  id                     :bigint           not null, primary key
#  allow_negative         :boolean          default(FALSE)
#  auto_approve_threshold :integer
#  decay_enabled          :boolean          default(FALSE)
#  email                  :citext
#  locale                 :string           default("pt-BR")
#  max_debt               :integer          default(100), not null
#  name                   :string
#  password_digest        :string
#  require_photo          :boolean          default(FALSE)
#  timezone               :string           default("America/Sao_Paulo")
#  week_start             :integer          default(1)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
FactoryBot.define do
  factory :family do
    name { Faker::Name.last_name }
    sequence(:email) { |n| "family#{n}@example.com" }
    password { "supersecret1234" }
  end
end

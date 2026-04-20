class Family < ApplicationRecord
  has_many :profiles, dependent: :destroy
  has_many :global_tasks, dependent: :destroy
  has_many :rewards, dependent: :destroy
  has_many :profile_tasks, through: :profiles
end

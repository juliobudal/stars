# week_start: integer column — 0 = Sunday, 1 = Monday (matches Ruby Date#wday convention).
# Default is 1 (Monday). Used to determine the start of the week for stats and day grouping.
class Family < ApplicationRecord
  has_many :profiles, dependent: :destroy
  has_many :global_tasks, dependent: :destroy
  has_many :rewards, dependent: :destroy
  has_many :profile_tasks, through: :profiles
end

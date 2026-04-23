class GlobalTask < ApplicationRecord
  belongs_to :family
  has_many :profile_tasks, dependent: :destroy
  has_many :global_task_assignments, dependent: :destroy
  has_many :assigned_profiles, through: :global_task_assignments, source: :profile

  enum :category, { escola: 0, casa: 1, rotina: 2, saude: 3, outro: 4 }
  enum :frequency, { daily: 0, weekly: 1, monthly: 2, once: 3 }

  validates :title, presence: true
  validates :points, numericality: { greater_than: 0 }
  validates :day_of_month, presence: true, if: :monthly?
  validates :day_of_month, numericality: { only_integer: true, in: 1..31 }, allow_nil: true, if: :monthly?
end

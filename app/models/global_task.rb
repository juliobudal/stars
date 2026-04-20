class GlobalTask < ApplicationRecord
  belongs_to :family
  has_many :profile_tasks, dependent: :destroy

  enum :category, { escola: 0, casa: 1, rotina: 2, outro: 3 }
  enum :frequency, {daily: 0, weekly: 1}

  validates :title, presence: true
  validates :points, numericality: {greater_than: 0}
end

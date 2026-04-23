class Reward < ApplicationRecord
  belongs_to :family

  validates :title, presence: true
  validates :cost, numericality: { greater_than: 0 }
end

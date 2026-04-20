class Redemption < ApplicationRecord
  belongs_to :profile
  belongs_to :reward

  enum :status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates :points, presence: true

  # Delegate title for easier display
  delegate :title, to: :reward

  scope :awaiting_approval, -> { pending }
end

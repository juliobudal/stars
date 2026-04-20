class ActivityLog < ApplicationRecord
  belongs_to :profile

  enum :log_type, {earn: 0, redeem: 1, adjust: 2}

  scope :recent, -> { order(created_at: :desc).limit(10) }
end

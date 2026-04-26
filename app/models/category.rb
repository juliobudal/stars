class Category < ApplicationRecord
  belongs_to :family
  has_many :rewards, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :family_id, case_sensitive: false }
  validates :icon, presence: true
  validates :color, presence: true

  scope :ordered, -> { order(:position, :created_at) }
end

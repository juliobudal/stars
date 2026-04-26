class Reward < ApplicationRecord
  belongs_to :family
  belongs_to :category

  validates :title, presence: true
  validates :cost, numericality: { greater_than: 0 }

  validate :category_belongs_to_same_family

  private

  def category_belongs_to_same_family
    return if category.nil? || family_id.nil?
    errors.add(:category, "must belong to the same family") if category.family_id != family_id
  end
end

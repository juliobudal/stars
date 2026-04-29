# == Schema Information
#
# Table name: rewards
#
#  id          :bigint           not null, primary key
#  cost        :integer
#  icon        :string
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category_id :bigint           not null
#  family_id   :bigint           not null
#
# Indexes
#
#  index_rewards_on_category_id  (category_id)
#  index_rewards_on_family_id    (family_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (family_id => families.id)
#
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

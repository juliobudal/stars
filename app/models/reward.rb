# == Schema Information
#
# Table name: rewards
#
#  id          :bigint           not null, primary key
#  collective  :boolean          default(FALSE), not null
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
#  index_rewards_on_collective   (collective)
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

  # Redemptions are an append-only ledger entry: a redeemed reward must not be
  # silently destroyed (it would orphan the kid's history and hit the DB FK
  # constraint with a 500). Block the delete and surface a friendly error.
  has_many :redemptions, dependent: :restrict_with_error

  validates :title, presence: true
  validates :cost, numericality: { greater_than: 0 }

  validate :category_belongs_to_same_family

  scope :collective, -> { where(collective: true) }
  scope :individual, -> { where(collective: false) }

  FAMILY_PREFIX_RE = /\A\s*\[\s*fam[íi]lia\s*\]\s*/i

  def display_title
    title.to_s.sub(FAMILY_PREFIX_RE, "").strip
  end

  private

  def category_belongs_to_same_family
    return if category.nil? || family_id.nil?
    errors.add(:category, "must belong to the same family") if category.family_id != family_id
  end
end

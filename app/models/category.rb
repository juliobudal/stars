# == Schema Information
#
# Table name: categories
#
#  id         :bigint           not null, primary key
#  color      :string           not null
#  icon       :string           not null
#  name       :string           not null
#  position   :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  family_id  :bigint           not null
#
# Indexes
#
#  index_categories_on_family_id               (family_id)
#  index_categories_on_family_id_and_name      (family_id,name) UNIQUE
#  index_categories_on_family_id_and_position  (family_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#
class Category < ApplicationRecord
  belongs_to :family
  has_many :rewards, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :family_id, case_sensitive: false }
  validates :icon, presence: true
  validates :color, presence: true

  scope :ordered, -> { order(:position, :created_at) }
end

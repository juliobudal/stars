# == Schema Information
#
# Table name: rewards
#
#  id         :bigint           not null, primary key
#  category   :integer          default("outro"), not null
#  cost       :integer
#  icon       :string
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  family_id  :bigint           not null
#
# Indexes
#
#  index_rewards_on_family_id  (family_id)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#
class Reward < ApplicationRecord
  belongs_to :family

  enum :category, { tela: 0, doce: 1, passeio: 2, brinquedo: 3, experiencia: 4, outro: 5 }, default: :outro

  validates :title, presence: true
  validates :cost, numericality: { greater_than: 0 }
end

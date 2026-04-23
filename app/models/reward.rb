class Reward < ApplicationRecord
  belongs_to :family

  enum :category, { tela: 0, doce: 1, passeio: 2, brinquedo: 3, experiencia: 4, outro: 5 }, default: :outro

  validates :title, presence: true
  validates :cost, numericality: { greater_than: 0 }
end

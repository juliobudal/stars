# frozen_string_literal: true

module Rewards
  # Curated starter rewards parents can add in one click from the reward
  # library (/parent/rewards/library). Pure data — Parent::RewardsController
  # #add_from_template builds Rewards from the selected keys, defaulting the
  # category to the family's first category.
  module TemplateLibrary
    TEMPLATES = [
      { key: "tempo_tela",     title: "30 min de tela extra",        icon: "phone",    cost: 20 },
      { key: "sorvete",        title: "Um sorvete",                  icon: "iceCream", cost: 15 },
      { key: "escolher_jantar", title: "Escolher o jantar",          icon: "dish",     cost: 25 },
      { key: "videogame",      title: "1 hora de videogame",         icon: "gamepad",  cost: 30 },
      { key: "dormir_tarde",   title: "Dormir 30 min mais tarde",    icon: "moon",     cost: 25 },
      { key: "passeio_parque", title: "Passeio no parque",           icon: "ferris",   cost: 40 },
      { key: "noite_pizza",    title: "Noite da pizza",              icon: "pizza",    cost: 50 },
      { key: "cinema",         title: "Ida ao cinema",               icon: "film",     cost: 60 },
      { key: "brinquedo",      title: "Brinquedo pequeno",           icon: "blocks",   cost: 80 },
      { key: "sobremesa",      title: "Sobremesa especial",          icon: "iceCream", cost: 15 }
    ].freeze

    extend CuratedTemplates
  end
end

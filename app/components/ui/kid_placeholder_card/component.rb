class Ui::KidPlaceholderCard::Component < ApplicationComponent
  def initialize(href:, label: "Adicionar criança")
    @href = href
    @label = label
  end
end

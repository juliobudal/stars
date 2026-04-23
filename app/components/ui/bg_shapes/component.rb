class Ui::BgShapes::Component < ApplicationComponent
  PALETTES = {
    blue: ["#c7ddff", "#ffd6e6", "#c2f0dd"],
    warm: ["#ffe0b3", "#ffcad4", "#e0ccff"],
    cool: ["#c2e7ff", "#dccfff", "#c2f0dd"]
  }.freeze

  def initialize(variant: "blue", **options)
    @variant = variant.to_sym
    @options = options
  end

  def call
    "".html_safe
  end
end

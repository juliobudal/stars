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
    colors = PALETTES[@variant] || PALETTES[:blue]

    content_tag :div, class: "bg-shapes-wrapper", style: "position: absolute; inset: 0; overflow: hidden; pointer-events: none; z-index: 0;" do
      concat content_tag(:div, nil, class: "bg-shape", style: "top: -8%; right: -10%; width: 45%; height: 45%; background: #{colors[0]};")
      concat content_tag(:div, nil, class: "bg-shape", style: "bottom: -12%; left: -8%; width: 50%; height: 50%; background: #{colors[1]};")
      concat content_tag(:div, nil, class: "bg-shape", style: "top: 30%; left: 50%; width: 30%; height: 30%; background: #{colors[2]}; opacity: 0.35;")
    end
  end
end

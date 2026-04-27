class Ui::BgShapes::Component < ApplicationComponent
  PALETTE_CLASSES = {
    "blue" => "bg-shapes--blue",
    "warm" => "bg-shapes--warm",
    "cool" => "bg-shapes--cool"
  }.freeze

  def initialize(variant: "blue", **options)
    @variant = variant.to_s
    @options = options
  end

  def palette_class
    PALETTE_CLASSES.fetch(@variant, PALETTE_CLASSES["blue"])
  end

  def call
    content_tag :div, class: "bg-shapes-wrapper #{palette_class}", style: "position: absolute; inset: 0; overflow: hidden; pointer-events: none; z-index: 0;" do
      concat content_tag(:div, nil, class: "bg-shape bg-shape--1", style: "top: -8%; right: -10%; width: 45%; height: 45%;")
      concat content_tag(:div, nil, class: "bg-shape bg-shape--2", style: "bottom: -12%; left: -8%; width: 50%; height: 50%;")
      concat content_tag(:div, nil, class: "bg-shape bg-shape--3", style: "top: 30%; left: 50%; width: 30%; height: 30%; opacity: 0.35;")
    end
  end
end

class Ui::Celebration::Component < ApplicationComponent
  def initialize(**options)
    @options = options
  end

  def call
    content_tag :div, nil, class: "confetti-layer", style: "display: none;", data: { celebration_target: "layer" }
  end
end

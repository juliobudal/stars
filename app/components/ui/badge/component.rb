class Ui::Badge::Component < ApplicationComponent
  VARIANTS = %w[star peach rose mint sky lilac coral primary outline].freeze

  def initialize(variant: "primary", size: "md", icon: nil, **options)
    @variant = variant
    @size = size
    @icon = icon
    @options = options
  end

  def call
    content_tag :div, class: classes, **@options do
      concat render Ui::Icon::Component.new(@icon, size: icon_size) if @icon
      concat content
    end
  end

  private

  def classes
    class_names(
      "chip",
      "chip-#{@variant}",
      @options.delete(:class),
      "chip-sm": @size == "sm"
    )
  end

  def icon_size
    @size == "sm" ? 12 : 14
  end
end

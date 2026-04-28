class Ui::Card::Component < ApplicationComponent
  PADDINGS = {
    "none" => "p-0",
    "sm"   => "p-4.5",
    "md"   => "p-6",
    "lg"   => "p-7"
  }.freeze

  def initialize(variant: "default", padding: "lg", **options)
    @variant = variant
    @padding = padding
    @options = options
  end

  def call
    content_tag(:div, content, class: classes, **@options)
  end

  private

  def classes
    base_classes = "bg-surface rounded-card shadow-card relative border-2 border-hairline"

    padding_class = PADDINGS[@padding.to_s] || @padding.to_s

    variant_classes = case @variant
    when "primary"
        "bg-primary text-white shadow-btn-primary"
    when "flat"
        "shadow-none"
    else
        ""
    end

    class_names(
      base_classes,
      padding_class,
      variant_classes,
      @options.delete(:class)
    )
  end
end

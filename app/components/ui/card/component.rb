class Ui::Card::Component < ApplicationComponent
  def initialize(variant: "default", **options)
    @variant = variant
    @options = options
  end

  def call
    content_tag(:div, content, class: classes, **@options)
  end

  private

  def classes
    base_classes = "bg-surface rounded-card p-7 shadow-card relative border-none"
    
    variant_classes = case @variant
      when "primary"
        "bg-primary text-white shadow-[0_2px_0_rgba(44,42,58,0.04),_0_6px_16px_rgba(44,42,58,0.05)]"
      when "flat"
        "shadow-none"
      else
        ""
      end

    class_names(
      base_classes,
      variant_classes,
      @options.delete(:class)
    )
  end
end

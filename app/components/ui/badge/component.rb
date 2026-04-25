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
    base_classes = "inline-flex items-center gap-[6px] rounded-full font-display font-semibold"

    size_classes = @size == "sm" ? "text-[11px] px-[10px] py-[4px] tracking-[0.08em] font-extrabold" : "px-[10px] py-[4px] text-[11px] tracking-[0.08em]"

    variant_classes = case @variant
    when "star" then "bg-warning-soft text-warning-depth"
    when "peach" then "bg-peach-soft text-peach-depth"
    when "rose" then "bg-rose-soft text-rose-depth"
    when "mint" then "bg-mint-soft text-mint-dark"
    when "sky" then "bg-sky-soft text-sky-dark"
    when "lilac" then "bg-lilac-soft text-lilac-dark"
    when "coral" then "bg-coral-soft text-coral-depth"
    when "primary" then "bg-primary-soft text-primary-2"
    when "outline" then "bg-white text-foreground border-2 border-hairline"
    else ""
    end

    class_names(
      base_classes,
      size_classes,
      variant_classes,
      @options.delete(:class)
    )
  end

  def icon_size
    @size == "sm" ? 12 : 14
  end
end

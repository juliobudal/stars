class Ui::Chip::Component < ApplicationComponent
  VARIANTS = %w[star peach rose mint sky lilac primary outline neutral].freeze
  SIZES    = %w[sm md].freeze

  def initialize(variant: "neutral", size: "md", uppercase: false, **options)
    @variant = variant
    @size = size
    @uppercase = uppercase
    @options = options
  end

  def call
    tag.span(content, class: classes, **@options)
  end

  private

  def classes
    base = "inline-flex items-center gap-1.5 rounded-full font-display text-[11px] tracking-[0.08em]"

    size_classes = @size == "sm" ? "px-[10px] py-[4px] font-extrabold" : "px-3 py-1 font-semibold"

    variant_classes = case @variant
      when "star"    then "bg-star-soft text-foreground"
      when "peach"   then "bg-peach-soft text-peach-depth"
      when "rose"    then "bg-rose-soft text-rose-depth"
      when "mint"    then "bg-mint-soft text-mint-depth"
      when "sky"     then "bg-sky-soft text-sky-depth"
      when "lilac"   then "bg-lilac-soft text-lilac-depth"
      when "primary" then "bg-primary-soft text-primary-depth"
      when "outline" then "bg-white text-foreground border-2 border-[rgba(26,42,74,0.1)]"
      else                "bg-surface-2 text-muted-foreground"
      end

    class_names(
      base,
      size_classes,
      variant_classes,
      { "uppercase": @uppercase },
      @options.delete(:class)
    )
  end
end

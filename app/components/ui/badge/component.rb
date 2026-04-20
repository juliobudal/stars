class Ui::Badge::Component < ApplicationComponent
  VARIANTS = %i[default info error success warning]
  DEFAULT_VARIANT = :default
  SIZES = %i[xs sm md lg]
  DEFAULT_SIZE = :sm

  def initialize(variant: DEFAULT_VARIANT, size: DEFAULT_SIZE, rounded: false, **options)
    @variant = VARIANTS.include?(variant) ? variant : DEFAULT_VARIANT
    @size = SIZES.include?(size) ? size : DEFAULT_SIZE
    @rounded = rounded
    @options = options
  end

  def call
    content_tag :span, content, class: classes, **@options
  end

  def classes
    class_names(
      "font-semibold inline-flex items-center w-fit whitespace-nowrap",
      @options.delete(:class),
      variant_classes,
      "px-1.5 py-0.5 text-[10px] rounded-btn-xs": @size == :xs,
      "px-2 py-1 text-[11px] rounded-btn-sm": @size == :sm,
      "px-3 py-1.5 text-xs rounded-btn-md": @size == :md,
      "px-4 py-2 text-[13px] rounded-btn-lg": @size == :lg,
      "rounded-full": @rounded
    )
  end

  def variant_classes
    {
      default: "bg-muted border-2 border-border text-foreground uppercase tracking-wider",
      info: "bg-info-soft border-2 border-info-border text-brand-blue font-bold uppercase tracking-wider",
      error: "bg-destructive-soft border-2 border-destructive-border text-brand-red font-bold uppercase tracking-wider",
      success: "bg-success-soft border-2 border-success-border text-brand-green font-bold uppercase tracking-wider",
      warning: "bg-warning-soft border-2 border-warning-border text-brand-orange font-bold uppercase tracking-wider"
    }[@variant]
  end
end

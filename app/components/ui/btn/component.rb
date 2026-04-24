class Ui::Btn::Component < ApplicationComponent
  VARIANTS = %w[primary secondary ghost danger success star].freeze
  SIZES = %w[sm md lg icon].freeze

  def initialize(variant: "primary", size: "md", url: nil, method: nil, block: false, **options)
    @variant = variant
    @size = size
    @url = url
    @method = method
    @block = block
    @options = options
  end

  def call
    if @url && @method
      button_to @url, class: classes, method: @method, **@options do
        content
      end
    elsif @url
      link_to @url, class: classes, **@options do
        content
      end
    else
      tag.button content, type: @options.delete(:type) || "button", class: classes, **@options
    end
  end

  private

  def classes
    base_classes = "inline-flex items-center justify-center font-display font-extrabold rounded-full gap-2 transition-all duration-[80ms] ease-out select-none tracking-tight whitespace-nowrap cursor-pointer border-none"
    
    lift = "hover:-translate-y-1 active:translate-y-1"

    variant_classes = case @variant
      when "primary"
        "bg-primary text-white shadow-btn-primary hover:shadow-btn-primary-hover active:shadow-btn-primary-active #{lift}"
      when "secondary"
        "bg-white text-foreground border-2 border-[rgba(26,42,74,0.08)] shadow-btn-secondary hover:shadow-btn-secondary-hover active:shadow-btn-secondary-active #{lift}"
      when "ghost"
        "bg-transparent text-foreground border-2 border-[rgba(26,42,74,0.1)] shadow-none hover:bg-[rgba(26,42,74,0.04)] active:translate-y-0"
      when "danger"
        "bg-destructive text-white shadow-btn-destructive hover:shadow-btn-destructive-hover active:shadow-btn-destructive-active #{lift}"
      when "success"
        "bg-success text-white shadow-btn-success hover:shadow-btn-success-hover active:shadow-btn-success-active #{lift}"
      when "star"
        "bg-warning text-foreground shadow-btn-warning hover:shadow-btn-warning-hover active:shadow-btn-warning-active #{lift}"
      else
        ""
      end

    size_classes = case @size
      when "sm"
        "text-[14px] px-3.5 py-2"
      when "lg"
        "text-[18px] px-6 py-3.5"
      when "icon"
        "w-11 h-11 p-0"
      else
        "text-[16px] px-5 py-3"
      end

    disabled_classes = "disabled:opacity-40 disabled:cursor-not-allowed disabled:grayscale-[0.3] disabled:pointer-events-none"

    class_names(
      base_classes,
      variant_classes,
      size_classes,
      disabled_classes,
      { "w-full": @block },
      @options.delete(:class)
    )
  end
end

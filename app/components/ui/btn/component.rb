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
    class_names(
      "ui-btn",
      "ui-btn--#{@variant}",
      "ui-btn--#{@size}",
      "anim-press",
      { "w-full": @block },
      @options.delete(:class)
    )
  end
end

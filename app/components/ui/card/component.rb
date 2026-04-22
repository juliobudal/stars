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
    class_names(
      "card",
      "card-#{@variant}",
      @options.delete(:class)
    )
  end
end

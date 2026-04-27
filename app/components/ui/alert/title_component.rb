class Ui::Alert::TitleComponent < ApplicationComponent
  def initialize(**options)
    @options = options
  end

  def call
    content_tag :strong, content, class: classes, **@options
  end

  private

  def classes
    class_names(
      "font-bold",
      @options.delete(:class)
    )
  end
end

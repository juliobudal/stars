class Ui::Empty::ActionsComponent < ApplicationComponent
  def initialize(**options)
    @options = options
  end

  def call
    render(Ui::Group::Component.new(class: classes, sticky: false, **@options)) { content }
  end

  private

  def classes
    class_names(
      "mt-6",
      @options.delete(:class)
    )
  end
end

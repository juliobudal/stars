class Ui::Modal::Component < ApplicationComponent
  def initialize(title: nil, subtitle: nil, size: "md", id: nil, **options)
    @title = title
    @subtitle = subtitle
    @size = size
    @id = id
    @options = options
  end

  def call
    content_tag :div, class: "modal-overlay", style: "display: none;", data: { controller: "ui-modal", action: "click->ui-modal#closeOnOverlay" }, id: @id do
      content_tag :div, class: class_names("modal", "w-#{@size}", @options[:class]) do
        concat header if @title || @subtitle
        concat content
      end
    end
  end

  private

  def header
    render Ui::TopBar::Component.new(title: @title, subtitle: @subtitle) do |c|
      c.with_right_slot do
        render Ui::Btn::Component.new(variant: "ghost", size: "icon", data: { action: "click->ui-modal#close" }) do
          render Ui::Icon::Component.new("close", size: 20)
        end
      end
    end
  end
end

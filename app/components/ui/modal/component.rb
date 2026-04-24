class Ui::Modal::Component < ApplicationComponent
  def initialize(title: nil, subtitle: nil, size: "md", id: nil, **options)
    @title = title
    @subtitle = subtitle
    @size = size
    @id = id
    @options = options
  end

  def call
    overlay_classes = "fixed inset-0 bg-black/40 backdrop-blur-sm z-[100] flex items-center justify-center p-4"
    modal_classes = "bg-surface rounded-card shadow-card w-full animate-pop-in overflow-hidden"
    
    size_classes = case @size
                   when "sm" then "max-w-md"
                   when "lg" then "max-w-4xl"
                   else "max-w-2xl" # md
                   end

    content_tag :div, class: overlay_classes, style: "display: none;", data: { controller: "ui-modal", action: "click->ui-modal#closeOnOverlay" }, id: @id do
      content_tag :div, class: class_names(modal_classes, size_classes, @options[:class]) do
        concat header if @title || @subtitle
        concat content_tag(:div, content, class: "p-6")
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

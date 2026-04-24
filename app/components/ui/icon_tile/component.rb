class Ui::IconTile::Component < ApplicationComponent
  def initialize(icon:, color: "primary", size: 56, **options)
    @icon = icon
    @color = color
    @size = size
    @options = options
  end

  def call
    base_classes = "flex items-center justify-center shrink-0 [&>svg]:w-[56%] [&>svg]:h-[56%]"
    
    # Map color to tailwind utility
    bg_color = "bg-#{@color}-soft"
    text_color = "text-#{@color}"
    
    # Handle size specifically via Tailwind size utilities if they match common sizes, or inline for arbitrary
    # Since size can be anything, we'll use inline but clean up the rest
    radius_class = @size >= 56 ? "rounded-[18px]" : "rounded-[12px]"

    content_tag :div, class: class_names(base_classes, bg_color, text_color, radius_class, @options.delete(:class)),
      style: "width: #{@size}px; height: #{@size}px; #{@options.delete(:style)}" do
      render Ui::Icon::Component.new(@icon, size: (@size * 0.56).round, color: "currentColor")
    end
  end

  private

  def tile_radius
    @size >= 56 ? 18 : 12
  end
end

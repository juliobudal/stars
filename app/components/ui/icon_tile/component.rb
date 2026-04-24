class Ui::IconTile::Component < ApplicationComponent
  def initialize(icon:, color: "primary", size: 56, **options)
    @icon = icon
    @color = color
    @size = size
    @options = options
  end

  def call
    content_tag :div, class: class_names("icon-tile", "bg-#{@color}-soft", "text-#{@color}", @options.delete(:class)),
      style: "width: #{@size}px; height: #{@size}px; background: var(--c-#{@color}-soft); color: var(--c-#{@color}); border-radius: #{tile_radius}px; #{@options.delete(:style)}" do
      render Ui::Icon::Component.new(@icon, size: @size * 0.56, color: "var(--c-#{@color})")
    end
  end

  private

  def tile_radius
    @size >= 56 ? 18 : 12
  end
end

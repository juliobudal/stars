class Ui::Empty::Component < ApplicationComponent
  def initialize(icon: "sparkle", title: nil, subtitle: nil, color: "primary", **options)
    @icon = icon
    @title = title
    @subtitle = subtitle
    @color = color
    @options = options
  end

  def call
    content_tag :div, class: class_names("center col", @options[:class]), style: "padding: 40px; text-align: center; gap: 14px; #{@options[:style]}" do
      concat render Ui::IconTile::Component.new(icon: @icon, color: @color, size: 80)
      concat content_tag(:h3, @title, class: "h-display", style: "font-size: 22px; margin-top: 8px;") if @title
      concat content_tag(:p, @subtitle, class: "subtitle", style: "max-width: 320px;") if @subtitle
      concat content if content.present?
    end
  end
end

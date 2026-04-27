class Ui::Empty::Component < ApplicationComponent
  def initialize(icon: "sparkle", title: nil, subtitle: nil, color: "primary", **options)
    @icon = icon
    @title = title
    @subtitle = subtitle
    @color = color
    @options = options
  end

  def call
    content_tag :div, class: class_names("flex flex-col items-center justify-center py-10 text-center gap-3.5", @options[:class]), style: @options[:style] do
      concat render Ui::IconTile::Component.new(icon: @icon, color: @color, size: 80)
      concat content_tag(:h3, @title, class: "font-display font-extrabold text-[22px] mt-2 text-foreground") if @title
      concat content_tag(:p, @subtitle, class: "text-muted-foreground font-bold text-[15px] max-w-[320px]") if @subtitle
      concat content if content.present?
    end
  end
end

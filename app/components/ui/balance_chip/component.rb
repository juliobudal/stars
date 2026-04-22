module Ui
  module BalanceChip
    class Component < ApplicationComponent
      def initialize(value:, size: "md", **options)
        @value = value
        @size = size.to_s
        @options = options
        super()
      end

      def call
        big = @size == "lg"

        chip_style = big ? "font-size: 28px; padding: 10px 20px 10px 12px; #{@options.delete(:style)}" : @options.delete(:style)
        badge_style = big ? "width: 36px; height: 36px;" : ""
        icon_size = big ? 22 : 16

        content_tag :div, id: @options.delete(:id), class: class_names("balance-chip", @options.delete(:class)),
          style: chip_style,
          data: { controller: "count-up", "count-up-current-value": @value } do
          concat content_tag(:div, class: "star-badge", style: badge_style) {
            render Ui::Icon::Component.new("star", size: icon_size, color: "#8a5a00")
          }
          concat content_tag(:span, @value, data: { "count-up-target": "display" })
        end
      end
    end
  end
end

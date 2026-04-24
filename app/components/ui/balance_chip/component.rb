module Ui
  module BalanceChip
    class Component < ApplicationComponent
      def initialize(value:, size: "md", **options)
        @value = value.to_i
        @size = size.to_s
        @options = options
        super()
      end

      def call
        big = @size == "lg"

        base_classes = "inline-flex items-center gap-2 bg-white text-foreground pl-2.5 pr-4 py-2 rounded-full font-display font-extrabold shadow-btn border-2 border-hairline"
        size_classes = big ? "text-[28px] px-5 py-2.5 pl-3" : "text-lg px-4 py-2 pl-2.5"
        
        content_tag :div, id: @options.delete(:id), class: class_names(base_classes, size_classes, @options.delete(:class)),
          style: @options.delete(:style),
          data: { controller: "count-up", "count-up-current-value": @value } do
          
          badge_classes = class_names(
            "rounded-full bg-warning flex items-center justify-center shadow-[inset_0_-2px_0_var(--color-warning-depth)]",
            big ? "w-9 h-9" : "w-7 h-7"
          )
          icon_size = big ? 22 : 16

          concat content_tag(:div, class: badge_classes) {
            render Ui::Icon::Component.new("star", size: icon_size, color: "var(--color-amber-dark)")
          }
          concat content_tag(:span, @value, data: { "count-up-target": "display" })
        end
      end
    end
  end
end

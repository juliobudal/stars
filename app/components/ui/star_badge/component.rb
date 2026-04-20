# frozen_string_literal: true

module Ui
  module StarBadge
    class Component < ApplicationComponent
      def initialize(size: 20, filled: true, **options)
        @size = size
        @filled = filled
        @options = options
        super()
      end

      def call
        icon_class = @filled ? "ph-fill ph-star" : "ph-regular ph-star"
        content_tag :span, class: @options[:class], style: "display: inline-flex; width: #{@size}px; height: #{@size}px; #{@options[:style]}" do
          content_tag :i, "", class: icon_class, style: "font-size: #{@size}px; color: var(--star);"
        end
      end
    end
  end
end

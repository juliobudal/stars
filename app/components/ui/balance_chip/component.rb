# frozen_string_literal: true

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
        
        chip_style = big ? "font-size: 28px; padding: 10px 20px 10px 12px; #{@options[:style]}" : @options[:style]
        badge_style = big ? "width: 36px; height: 36px;" : ""
        icon_size = big ? 22 : 16
        
        content_tag :div, class: ["balance-chip", @options[:class]].select(&:present?).join(" "), style: chip_style do
          concat content_tag(:div, class: "star-badge", style: badge_style) {
            content_tag :i, "", class: "ph-fill ph-star", style: "font-size: #{icon_size}px; color: #8a5a00;"
          }
          concat content_tag(:span, @value, data: { balance_target: "value" })
        end
      end
    end
  end
end

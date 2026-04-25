# frozen_string_literal: true

module Ui
  module StatMetric
    class Component < ApplicationComponent
      def initialize(value:, label:, tint: "primary", prefix: nil)
        @value = value
        @label = label
        @prefix = prefix
        @tint = Ui::StatCard::Component::TINTS[tint.to_s] ||
                Ui::StatCard::Component::TINTS["primary"]
        super()
      end

      attr_reader :value, :label, :prefix, :tint

      def call
        content_tag :div, class: "card", style: "padding: 14px; text-align: center;" do
          concat content_tag(:div, "#{prefix}#{value}", class: "h-display text-xl", style: "color: #{tint[:fg]};")
          concat content_tag(:div, label, class: "text-xs", style: "font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.06em; margin-top: 2px;")
        end
      end
    end
  end
end

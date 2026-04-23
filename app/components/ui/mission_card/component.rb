# frozen_string_literal: true

module Ui
  module MissionCard
    class Component < ApplicationComponent
      CATEGORIES = Ui::Tokens::MISSION_CATEGORIES.transform_values { |v|
        { color: v[:tint], icon: v[:icon], label: v[:label] }
      }.freeze

      def initialize(mission:, status: "pending", variant: "bubble", index: 0, **options)
        @mission = mission
        @status = status.to_s # "pending", "waiting", "done"
        @variant = variant.to_s # "bubble", "ticket"
        @index = index
        @options = options
        super()
      end

      def category_data
        cat = @mission.respond_to?(:category) ? @mission.category : nil
        name = cat.to_s.presence || "geral"
        CATEGORIES[name] || CATEGORIES["geral"]
      end

      def points_value
        @mission.try(:points) || @mission.try(:stars) || @mission.try(:base_reward) || @mission.try(:reward_amount) || 10
      end

      def waiting?
        @status == "waiting"
      end

      def pressed_transform
        @variant == "ticket" ? "translateY(3px)" : "translateY(4px)"
      end

      def shadow_value
        color = "rgba(26,42,74,0.08)"
        color = "var(--c-#{category_data[:color]})" if @variant == "bubble"
        color = "var(--primary)" if @variant == "bubble" && category_data[:color] == "primary"

        @variant == "ticket" ? "0 4px 0 #{color}" : "0 5px 0 #{color}"
      end

      # Serializes extra options (excluding :style and :class) to an HTML-safe
      # attribute string. Nested hashes (e.g. data: { action: "...", foo: "bar" })
      # are expanded into individual data-* attributes.
      def extra_html_attrs
        attrs = []
        @options.except(:style, :class).each do |key, value|
          if value.is_a?(Hash)
            value.each do |sub_key, sub_value|
              attr_name = "#{key}-#{sub_key.to_s.tr('_', '-')}"
              attrs << "#{attr_name}=\"#{ERB::Util.html_escape(sub_value)}\""
            end
          else
            attrs << "#{key}=\"#{ERB::Util.html_escape(value)}\""
          end
        end
        attrs.join(" ").html_safe
      end
    end
  end
end

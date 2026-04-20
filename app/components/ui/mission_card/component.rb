# frozen_string_literal: true

module Ui
  module MissionCard
    class Component < ApplicationComponent
      def initialize(mission:, status: "pending", variant: "bubble", index: 0, **options)
        @mission = mission
        @status = status.to_s # "pending", "waiting", "done"
        @variant = variant.to_s # "bubble", "ticket"
        @index = index
        @options = options
        super()
      end

      def category_name
        @mission.respond_to?(:category) && @mission.category ? @mission.category.name : "Geral"
      end

      def points_value
        @mission.try(:points) || @mission.try(:base_reward) || @mission.try(:reward_amount) || 10
      end

      def category_color
        name = category_name
        cat_to_color = {
          "Saúde" => "mint",
          "Estudos" => "primary",
          "Rotina" => "peach",
          "Casa" => "rose"
        }
        theme_color = cat_to_color[name] || "primary"
        bg_var = "var(--#{theme_color == 'primary' ? 'primary-soft' : "c-#{theme_color}-soft"})"
        fg_var = "var(--#{theme_color == 'primary' ? 'primary' : "c-#{theme_color}"})"
        { bg: bg_var, fg: fg_var }
      end

      def icon_name
        case category_name
        when "Saúde" then "heartbeat"
        when "Estudos" then "book"
        when "Casa" then "house"
        else "star"
        end
      end

      def waiting?
        @status == "waiting"
      end
    end
  end
end

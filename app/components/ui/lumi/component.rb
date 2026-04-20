# frozen_string_literal: true

module Ui
  module Lumi
    class Component < ApplicationComponent
      def initialize(size: 80, mood: "happy", class_name: "", **options)
        @size = size
        @mood = mood.to_s
        @class_name = class_name
        @options = options
        super()
      end

      def call
        icon_name = mood_to_icon
        excited_class = @mood == "excited" ? "excited" : ""

        wrap_style = "width: #{@size}px; height: #{@size}px; display: inline-flex; align-items: center; justify-content: center; position: relative; #{@options[:style]}"
        star_style = "position: absolute; inset: 0; font-size: #{@size}px; color: #ffc41a; display: flex; align-items: center; justify-content: center; filter: drop-shadow(0 4px 0 rgba(255,160,30,0.35));"
        face_style = "position: relative; font-size: #{@size * 0.5}px; color: #7a4f00; z-index: 1;"

        content_tag :div, class: ["lumi-wrap", excited_class, @class_name].select(&:present?).join(" "), style: wrap_style do
          concat content_tag(:i, "", class: "ph-fill ph-star-four", style: star_style)
          concat content_tag(:i, "", class: "ph-fill ph-#{icon_name}", style: face_style)
        end
      end

      private

      def mood_to_icon
        case @mood
        when "excited" then "smiley-wink"
        when "thinking" then "smiley-meh"
        when "sad" then "smiley-sad"
        when "wow" then "smiley-sticker"
        else "smiley"
        end
      end
    end
  end
end

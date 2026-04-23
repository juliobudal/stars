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
        excited_class = @mood == "excited" ? "excited" : ""
        wrap_style = "width: #{@size}px; height: #{@size}px; display: inline-flex; align-items: center; justify-content: center; #{@options[:style]}"

        content_tag :div, class: ["lumi-wrap", excited_class, @class_name].select(&:present?).join(" "), style: wrap_style do
          image_tag "lumi.png", alt: "Lumi", style: "width: 100%; height: 100%; object-fit: contain;"
        end
      end
    end
  end
end

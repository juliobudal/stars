# frozen_string_literal: true

module Ui
  module StarValue
    class Component < ApplicationComponent
      SIZES = {
        xs: { icon: 12, text: "text-[12px]" },
        sm: { icon: 14, text: "text-[13px]" },
        md: { icon: 16, text: "text-[15px]" },
        lg: { icon: 20, text: "text-[20px]" },
        xl: { icon: 28, text: "text-[28px]" }
      }.freeze

      def initialize(value:, size: :md, prefix: nil, color: :amber, animate: false,
                     class: nil, value_id: nil, value_data: {}, value_class: nil, **options)
        @value = value
        @size = SIZES.key?(size) ? size : :md
        @prefix = prefix
        @color = color
        @animate = animate
        @class = binding.local_variable_get(:class)
        @value_id = value_id
        @value_data = value_data
        @value_class = value_class
        @options = options
        super()
      end

      attr_reader :value, :prefix, :animate, :value_id, :value_data, :value_class

      def icon_size
        SIZES[@size][:icon]
      end

      def text_class
        SIZES[@size][:text]
      end

      def gradient?
        @color == :gold
      end

      def number_color_class
        case @color
        when :white   then "text-white"
        when :current then "text-current"
        when :gold    then "text-amber-dark"
        else               "text-amber-dark"
        end
      end

      def stop_colors
        case @color
        when :white   then [ "#FFFFFF", "#F4F4F5" ]
        when :current then [ "currentColor", "currentColor" ]
        else               [ "#FFD24C", "#E69400" ] # gold gradient
        end
      end

      def gradient_id
        @gradient_id ||= "star-grad-#{SecureRandom.hex(4)}"
      end

      def container_class
        class_names(
          "inline-flex items-center font-display font-extrabold leading-none",
          text_class,
          number_color_class,
          { "animate-pop": animate == :pop, "animate-star-pulse": animate == :pulse },
          @class
        )
      end
    end
  end
end

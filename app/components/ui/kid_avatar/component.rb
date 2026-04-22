module Ui
  module KidAvatar
    class Component < ApplicationComponent
      def initialize(kid:, size: 64, **options)
        @kid = kid
        @size = size
        @options = options
        super()
      end

      def call
        color = @kid.try(:color).presence || "primary"
        icon = @kid.try(:avatar).presence || @kid.try(:icon).presence || "faceKid"

        bg_var = "var(--c-#{color}-soft)"
        bg_var = "var(--primary-soft)" if color == "primary"
        fg_var = "var(--c-#{color})"
        fg_var = "var(--primary)" if color == "primary"

        style = "width: #{@size}px; height: #{@size}px; border-radius: 50%; background: #{bg_var}; border: 3px solid #{fg_var}; overflow: hidden; flex-shrink: 0; display: flex; align-items: center; justify-content: center; #{@options.delete(:style)}"

        content_tag :div, class: @options.delete(:class), style: style do
          render Ui::Icon::Component.new(icon, size: @size - 4, color: fg_var)
        end
      end
    end
  end
end

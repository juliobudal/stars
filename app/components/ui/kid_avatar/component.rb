# frozen_string_literal: true

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
        color_name = @kid.try(:color) || "primary"
        color_name = "primary" unless %w[primary peach lilac mint rose coral].include?(color_name)
        
        bg_var = "var(--#{color_name == 'primary' ? 'primary-soft' : "c-#{color_name}-soft"})"
        fg_var = "var(--#{color_name == 'primary' ? 'primary' : "c-#{color_name}"})"
        
        wrap_style = "width: #{@size}px; height: #{@size}px; border-radius: 50%; background: #{bg_var}; border: 3px solid #{fg_var}; overflow: hidden; flex-shrink: 0; display: flex; align-items: center; justify-content: center; #{@options[:style]}"
        
        avatar_val = @kid.try(:avatar).presence || "👦"
        
        content_tag :div, class: @options[:class], style: wrap_style do
          # Check if avatar_val is a phosphor icon name or an emoji
          if avatar_val.match?(/^[a-z\-]+$/)
            content_tag :i, "", class: "ph-fill ph-#{avatar_val}", style: "font-size: #{@size - 4}px; color: #{fg_var};"
          else
            content_tag :span, avatar_val, style: "font-size: #{@size * 0.6}px;"
          end
        end
      end
    end
  end
end

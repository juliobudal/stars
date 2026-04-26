# frozen_string_literal: true

module Ui
  module Toast
    class Component < ApplicationComponent
      VARIANTS = %i[default success error info].freeze

      def initialize(message:, variant: :default, dismiss_after: 3000, **options)
        @message = message
        @variant = VARIANTS.include?(variant.to_sym) ? variant.to_sym : :default
        @dismiss_after = dismiss_after.to_i
        @options = options
        super()
      end

      attr_reader :message, :variant, :dismiss_after

      def variant_classes
        case variant
        when :success then 'bg-emerald-500 text-white'
        when :error   then 'bg-rose-500 text-white'
        when :info    then 'bg-sky-500 text-white'
        else 'bg-foreground text-background'
        end
      end
    end
  end
end

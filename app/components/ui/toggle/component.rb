# frozen_string_literal: true

module Ui
  module Toggle
    class Component < ApplicationComponent
      def initialize(checked: false, size: :md, name: nil, form: nil, value: "1", aria_label: nil, **options)
        @checked = ActiveModel::Type::Boolean.new.cast(checked) || false
        @size = size.to_sym
        @name = name
        @form = form
        @value = value
        @aria_label = aria_label
        @options = options
        super()
      end

      attr_reader :checked, :size, :name, :form, :value, :aria_label

      def form_bound?
        name.present?
      end

      def track_style
        "box-shadow: inset 0 -3px 0 rgba(0,0,0,0.15);"
      end

      def track_classes
        class_names(
          "rounded-full bg-hairline transition-colors duration-200 relative",
          size == :sm ? "w-[34px] h-[20px]" : "w-[52px] h-[30px]",
          { "bg-primary": checked && !form_bound? }
        )
      end

      def thumb_classes
        class_names(
          "rounded-full bg-white absolute top-[3px] left-[3px] transition-transform duration-200",
          size == :sm ? "w-[14px] h-[14px]" : "w-[24px] h-[24px]",
          { (size == :sm ? "translate-x-[14px]" : "translate-x-[22px]") => checked && !form_bound? }
        )
      end

      def thumb_style
        "box-shadow: 0 2px 0 rgba(0,0,0,0.15);"
      end

      def peer_track_classes
        class_names(
          "rounded-full bg-hairline transition-colors duration-200 relative peer-checked:bg-primary",
          size == :sm ? "w-[34px] h-[20px]" : "w-[52px] h-[30px]"
        )
      end

      def peer_thumb_classes
        class_names(
          "rounded-full bg-white absolute top-[3px] left-[3px] transition-transform duration-200",
          size == :sm ? "w-[14px] h-[14px] group-has-[:checked]:translate-x-[14px]" : "w-[24px] h-[24px] group-has-[:checked]:translate-x-[22px]"
        )
      end
    end
  end
end

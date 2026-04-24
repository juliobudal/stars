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

      def track_classes
        class_names(
          "rounded-full bg-hairline transition-colors duration-200 relative",
          size == :sm ? "w-[34px] h-[20px]" : "w-11 h-6",
          { "bg-primary": checked && !form_bound? }
        )
      end

      def thumb_classes
        class_names(
          "rounded-full bg-white absolute top-[2px] left-[2px] transition-transform duration-200 shadow-sm",
          size == :sm ? "w-[16px] h-[16px]" : "w-[20px] h-[20px]",
          { (size == :sm ? "translate-x-[16px]" : "translate-x-[22px]") => checked && !form_bound? }
        )
      end

      def peer_track_classes
        class_names(
          "rounded-full bg-hairline transition-colors duration-200 relative peer-checked:bg-primary",
          size == :sm ? "w-[34px] h-[20px]" : "w-11 h-6"
        )
      end

      def peer_thumb_classes
        class_names(
          "rounded-full bg-white absolute top-[2px] left-[2px] transition-transform duration-200 shadow-sm",
          size == :sm ? "w-[16px] h-[16px] peer-checked:translate-x-[14px]" : "w-[20px] h-[20px] peer-checked:translate-x-[18px]"
        )
      end
    end
  end
end

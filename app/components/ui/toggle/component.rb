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

      def root_class
        classes = [ "toggle" ]
        classes << "toggle-sm" if size == :sm
        classes << "is-checked" if checked && !form_bound?
        classes.join(" ")
      end
    end
  end
end

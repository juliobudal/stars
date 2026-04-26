# frozen_string_literal: true

module Ui
  module Select
    class Component < ApplicationComponent
      SIZES = {
        sm: "text-[13px] py-1.5 px-3 rounded-lg",
        md: "text-[15px] py-2.5 px-4 rounded-xl",
        lg: "text-[17px] py-4 px-5 rounded-2xl"
      }.freeze

      def initialize(name:, options:, selected: nil, placeholder: nil, id: nil,
                     size: :md, class: nil, native_data: {}, data: {}, **html_options)
        @name = name
        @option_list = options
        @selected = selected.to_s if selected
        @placeholder = placeholder
        @id = id || name.to_s.gsub(/[\[\]]+/, "_").chomp("_")
        @size = SIZES.key?(size) ? size : :md
        @class = binding.local_variable_get(:class)
        @native_data = native_data
        @data_attrs = data
        @html_options = html_options
        super()
      end

      attr_reader :name, :placeholder, :native_data, :data_attrs

      def option_list
        @option_list
      end

      def selected_value
        return @selected if @selected
        first_value = option_list.first
        first_value.is_a?(Array) ? first_value.last.to_s : first_value.to_s
      end

      def selected_label
        match = option_list.find { |o| option_value(o).to_s == selected_value.to_s }
        match ? option_label(match) : (placeholder || selected_value)
      end

      def option_value(opt)
        opt.is_a?(Array) ? opt.last : opt
      end

      def option_label(opt)
        opt.is_a?(Array) ? opt.first : opt
      end

      def trigger_id
        "#{@id}_trigger"
      end

      def native_id
        "#{@id}_native"
      end

      def trigger_class
        class_names(
          "ui-select__trigger inline-flex items-center justify-between gap-3 w-full",
          "bg-white border-2 border-hairline font-semibold text-foreground",
          "transition-all shadow-sm cursor-pointer",
          "hover:border-primary/40 focus:border-primary focus:outline-none",
          SIZES[@size],
          @class
        )
      end

      def panel_class
        "ui-select__panel absolute left-0 right-0 mt-1.5 z-50 bg-white border border-hairline rounded-xl shadow-card overflow-hidden hidden"
      end

      def option_class(value)
        active = value.to_s == selected_value.to_s
        class_names(
          "flex items-center justify-between gap-2 w-full px-4 py-2.5 cursor-pointer text-left",
          "font-semibold text-[14px] transition-colors",
          active ? "bg-primary-soft text-primary" : "text-foreground hover:bg-muted"
        )
      end
    end
  end
end

# frozen_string_literal: true

module Ui
  module ColorSwatchPicker
    class Component < ApplicationComponent
      def initialize(field_name:, value: nil, id: nil)
        @field_name = field_name
        @value = (value.presence || Ui::Tokens::CATEGORY_COLOR_PALETTE.keys.first).to_s
        @id = id || "color_swatch_picker_#{SecureRandom.hex(4)}"
        super()
      end

      attr_reader :field_name, :value, :id

      def palette
        Ui::Tokens::CATEGORY_COLOR_PALETTE
      end
    end
  end
end

# frozen_string_literal: true

module Ui
  module CategoryRow
    class Component < ApplicationComponent
      def initialize(category:, reward_count:)
        @category = category
        @reward_count = reward_count.to_i
        super()
      end

      attr_reader :category, :reward_count

      def palette
        Ui::Tokens.color_palette_entry(category.color)
      end
    end
  end
end

# frozen_string_literal: true

module Ui
  module KidInitialChip
    class Component < ApplicationComponent
      def initialize(profile:, size: 24)
        @profile = profile
        @size = size
        super()
      end

      attr_reader :profile, :size

      def palette
        Ui::SmileyAvatar::Component.palette_vars(profile&.color)
      end

      def initial
        profile&.name.to_s.strip[0]&.upcase || "?"
      end
    end
  end
end

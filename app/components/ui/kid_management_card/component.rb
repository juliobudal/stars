# frozen_string_literal: true

module Ui
  module KidManagementCard
    class Component < ApplicationComponent
      def initialize(kid:, balance: nil, missions_count: nil)
        @kid = kid
        @balance = balance || kid.points
        @missions_count = missions_count
        super()
      end

      attr_reader :kid, :balance, :missions_count

      def color
        kid.color.presence || "primary"
      end

      def fg_var
        color == "primary" ? "var(--primary)" : "var(--c-#{color})"
      end

      def bg_soft
        color == "primary" ? "var(--primary-soft)" : "var(--c-#{color}-soft)"
      end

      def level
        [ (kid.points.to_i / 100) + 1, 1 ].max
      end
    end
  end
end

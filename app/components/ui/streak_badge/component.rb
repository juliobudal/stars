module Ui
  module StreakBadge
    class Component < ApplicationComponent
      def initialize(streak:, size: :md)
        @streak = streak
        @size = size
      end

      attr_reader :streak, :size
    end
  end
end

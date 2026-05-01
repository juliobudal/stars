# frozen_string_literal: true

module Ui
  module WishlistGoal
    class Component < ApplicationComponent
      def initialize(profile:)
        @profile = profile
        @reward = profile.wishlist_reward
        super()
      end

      attr_reader :profile, :reward

      def pinned? = @reward.present?

      def progress_pct
        return 0 unless pinned?
        return 100 if @reward.cost.to_i <= 0
        [ (@profile.points.to_f / @reward.cost * 100).round, 100 ].min
      end

      def stars_remaining
        return 0 unless pinned?
        [ @reward.cost.to_i - @profile.points.to_i, 0 ].max
      end

      def funded? = pinned? && @profile.points.to_i >= @reward.cost.to_i
    end
  end
end

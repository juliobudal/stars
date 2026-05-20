# frozen_string_literal: true

module Ui
  module KidProgressCard
    class Component < ApplicationComponent
      def initialize(kid:, awaiting_count: 0, missions_count: 0, manage: false)
        @kid = kid
        @awaiting_count = awaiting_count.to_i
        @missions_count = missions_count.to_i
        @manage = manage
        super()
      end

      attr_reader :kid, :awaiting_count, :missions_count, :manage

      def palette
        @palette ||= Ui::SmileyAvatar::Component.palette_vars(kid&.color)
      end

      def streak
        kid.respond_to?(:streak) ? kid.streak.to_i : 0
      end

      def points
        kid.respond_to?(:points) ? kid.points.to_i : 0
      end

      def level
        kid.respond_to?(:level) ? kid.level : [ (points / Profile::LEVEL_SIZE) + 1, 1 ].max
      end

      def xp_progress
        pct = points % Profile::LEVEL_SIZE
        (pct.to_f / Profile::LEVEL_SIZE * 100).round
      end

      def stars_to_next
        kid.respond_to?(:stars_to_next) ? kid.stars_to_next : (Profile::LEVEL_SIZE - (points % Profile::LEVEL_SIZE))
      end

      def wishlist_reward
        kid.respond_to?(:wishlist_reward) ? kid.wishlist_reward : nil
      end
    end
  end
end

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
        @palette ||= Ui::SmileyAvatar::Component::COLOR_MAP[kid&.color.to_s] ||
                     Ui::SmileyAvatar::Component::COLOR_MAP["primary"]
      end

      def streak
        kid.respond_to?(:streak) ? kid.streak.to_i : 0
      end

      def points
        kid.respond_to?(:points) ? kid.points.to_i : 0
      end

      def level
        [ (points / 100) + 1, 1 ].max
      end

      def xp_progress
        points % 100
      end

      def stars_to_next
        100 - xp_progress
      end
    end
  end
end

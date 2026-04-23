# frozen_string_literal: true

module Ui
  module KidProgressCard
    class Component < ApplicationComponent
      def initialize(kid:, awaiting_count: 0, missions_count: 0)
        @kid = kid
        @awaiting_count = awaiting_count.to_i
        @missions_count = missions_count.to_i
        super()
      end

      attr_reader :kid, :awaiting_count, :missions_count

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
    end
  end
end

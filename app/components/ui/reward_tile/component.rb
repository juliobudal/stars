# frozen_string_literal: true

module Ui
  module RewardTile
    class Component < ApplicationComponent
      def initialize(reward:, balance:, tint: "var(--c-lilac-soft)", index: 0, popular: false, modal_id: nil)
        @reward = reward
        @balance = balance.to_i
        @tint = tint
        @index = index.to_i
        @popular = popular
        @modal_id = modal_id
        super()
      end

      attr_reader :reward, :balance, :tint, :index, :popular, :modal_id

      def reward_icon
        reward.respond_to?(:icon) ? reward.icon.presence : nil
      end

      def can_afford?
        balance >= reward.cost
      end

      def shortfall
        reward.cost - balance
      end

      def animation_delay
        format("%.2f", index * 0.04)
      end
    end
  end
end

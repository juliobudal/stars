# frozen_string_literal: true

module Ui
  module FeaturedRewardCard
    class Component < ApplicationComponent
      def initialize(reward:, balance:, modal_id: nil)
        @reward = reward
        @balance = balance.to_i
        @modal_id = modal_id
        super()
      end

      attr_reader :reward, :balance, :modal_id

      def reward_icon
        reward.respond_to?(:icon) ? reward.icon.presence : nil
      end

      def can_afford?
        balance >= reward.cost
      end

      def shortfall
        reward.cost - balance
      end

      def palette
        Ui::Tokens.color_palette_entry(reward.category&.color || "lilac")
      end

      def tint_soft
        palette[:soft_var]
      end

      def tint_fg
        palette[:fg_var]
      end
    end
  end
end

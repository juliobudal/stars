# frozen_string_literal: true

module Ui
  module RewardCatalogCard
    class Component < ApplicationComponent
      def initialize(reward:)
        @reward = reward
        super()
      end

      attr_reader :reward

      def category_meta
        Ui::Tokens.reward_category_for(reward.category)
      end
    end
  end
end

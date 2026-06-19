module Rewards
  # Read model for the kid rewards screen: the family's rewards split into
  # affordable vs locked by the profile's current balance, plus the profile's
  # redemption history. Shared by Kid::RewardsController#index and #redeem so
  # the affordability partitioning lives in one place instead of being rebuilt
  # in both actions.
  class CatalogQuery
    Result = Data.define(:rewards, :affordable, :locked, :redeemed, :balance)

    def initialize(profile)
      @profile = profile
    end

    def call
      balance = @profile.points
      rewards = Reward.where(family_id: @profile.family_id).includes(:category).order(:cost)
      affordable, locked = rewards.partition { |r| r.cost <= balance }

      Result.new(
        rewards: rewards,
        affordable: affordable,
        locked: locked,
        redeemed: @profile.redemptions.includes(:reward).order(created_at: :desc),
        balance: balance
      )
    end
  end
end

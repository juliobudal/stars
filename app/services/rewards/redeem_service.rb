module Rewards
  class RedeemService
    def initialize(profile:, reward:)
      @profile = profile
      @reward = reward
    end

    def call
      return false if @profile.points < @reward.cost

      ActiveRecord::Base.transaction do
        @profile.lock!
        
        if @profile.points >= @reward.cost
          @profile.decrement!(:points, @reward.cost)
          
          # Create a pending redemption
          @profile.redemptions.create!(
            reward: @reward,
            points: @reward.cost,
            status: :pending
          )

          @profile.activity_logs.create!(
            log_type: :reward_redeemed,
            title: "Solicitado: #{@reward.title}",
            points: -@reward.cost
          )
          true
        else
          false
        end
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      false
    end
  end
end

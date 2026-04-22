module Rewards
  class RedeemService < ApplicationService
    def initialize(profile:, reward:)
      @profile = profile
      @reward = reward
    end

    def call
      Rails.logger.info(
        "[Rewards::RedeemService] start profile_id=#{@profile.id} reward_id=#{@reward.id} cost=#{@reward.cost}"
      )

      error = nil
      redemption = nil

      ActiveRecord::Base.transaction do
        @profile.lock!

        if @profile.points < @reward.cost
          error = "Saldo insuficiente"
          raise ActiveRecord::Rollback
        end

        @profile.decrement!(:points, @reward.cost)

        redemption = Redemption.create!(
          profile: @profile,
          reward: @reward,
          points: @reward.cost,
          status: :pending
        )

        ActivityLog.create!(
          profile: @profile,
          log_type: :redeem,
          title: "Solicitado: #{@reward.title}",
          points: -@reward.cost
        )
      end

      if error
        Rails.logger.info("[Rewards::RedeemService] failure profile_id=#{@profile.id} error=#{error}")
        fail_with(error)
      else
        Rails.logger.info("[Rewards::RedeemService] success profile_id=#{@profile.id}")
        ok(redemption)
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Rewards::RedeemService] exception profile_id=#{@profile.id} error=#{e.message}")
      fail_with(e.message)
    end
  end
end

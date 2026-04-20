require "ostruct"

module Rewards
  class RedeemService
    def initialize(profile:, reward:)
      @profile = profile
      @reward = reward
    end

    def call
      Rails.logger.info(
        "[Rewards::RedeemService] start profile_id=#{@profile.id} reward_id=#{@reward.id} cost=#{@reward.cost}"
      )

      error = nil

      ActiveRecord::Base.transaction do
        @profile.lock!

        if @profile.points < @reward.cost
          error = "Saldo insuficiente"
          raise ActiveRecord::Rollback
        end

        @profile.decrement!(:points, @reward.cost)

        @profile.redemptions.create!(
          reward: @reward,
          points: @reward.cost,
          status: :pending
        )

        @profile.activity_logs.create!(
          log_type: :redeem,
          title: "Solicitado: #{@reward.title}",
          points: -@reward.cost
        )
      end

      if error
        Rails.logger.info("[Rewards::RedeemService] failure profile_id=#{@profile.id} error=#{error}")
        OpenStruct.new(success?: false, error: error)
      else
        Rails.logger.info("[Rewards::RedeemService] success profile_id=#{@profile.id}")
        OpenStruct.new(success?: true, error: nil)
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Rewards::RedeemService] exception profile_id=#{@profile.id} error=#{e.message}")
      OpenStruct.new(success?: false, error: e.message)
    end
  end
end

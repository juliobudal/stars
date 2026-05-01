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

        family = @profile.family
        resulting_balance = @profile.points - @reward.cost

        insufficient = if family.allow_negative?
          resulting_balance < -family.max_debt
        else
          @profile.points < @reward.cost
        end

        if insufficient
          error = "Saldo insuficiente"
          raise ActiveRecord::Rollback
        end

        @profile.decrement!(:points, @reward.cost)

        # Auto-clear wishlist if redeeming the pinned reward (must stay inside the transaction).
        if @profile.wishlist_reward_id == @reward.id
          @profile.update!(wishlist_reward_id: nil)
        end

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
        broadcast_celebration(redemption)
        ok(redemption)
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Rewards::RedeemService] exception profile_id=#{@profile.id} error=#{e.message}")
      fail_with(e.message)
    end

    private

    def broadcast_celebration(redemption)
      tier = Ui::Celebration.tier_for(:redeemed)
      payload = {
        points: -@reward.cost,
        message: "Resgate solicitado!",
        reward_title: @reward.title,
        palette: "gold"
      }

      Turbo::StreamsChannel.broadcast_append_to(
        "kid_#{@profile.id}",
        target: "fx_stage",
        partial: "kid/shared/celebration",
        locals: { tier: tier, payload: payload }
      )
    rescue StandardError => e
      Rails.logger.warn("[Rewards::RedeemService] broadcast failed reward_id=#{@reward.id} error=#{e.message}")
    end
  end
end

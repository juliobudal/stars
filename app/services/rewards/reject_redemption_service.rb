module Rewards
  class RejectRedemptionService < ApplicationService
    def initialize(redemption)
      @redemption = redemption
      @profile = redemption.profile
    end

    def call
      Rails.logger.info("[Rewards::RejectRedemptionService] start redemption_id=#{@redemption.id}")

      unless @redemption.pending?
        return fail_with("Resgate não está pendente")
      end

      ActiveRecord::Base.transaction do
        @redemption.update!(status: :rejected)
        @profile.increment!(:points, @redemption.points)
        ActivityLog.create!(
          profile: @profile,
          log_type: :adjust,
          title: "Resgate Recusado (Reembolso): #{@redemption.title}",
          points: @redemption.points
        )
      end

      Rails.logger.info("[Rewards::RejectRedemptionService] success id=#{@redemption.id}")
      ok(@redemption)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Rewards::RejectRedemptionService] exception id=#{@redemption.id} error=#{e.message}")
      fail_with(e.message)
    end
  end
end

module Rewards
  class ApproveRedemptionService < ApplicationService
    def initialize(redemption)
      @redemption = redemption
    end

    def call
      Rails.logger.info("[Rewards::ApproveRedemptionService] start redemption_id=#{@redemption.id}")

      unless @redemption.pending?
        return fail_with("Resgate não está pendente")
      end

      @redemption.update!(status: :approved)
      Rails.logger.info("[Rewards::ApproveRedemptionService] success id=#{@redemption.id}")
      ok(@redemption)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Rewards::ApproveRedemptionService] exception id=#{@redemption.id} error=#{e.message}")
      fail_with(e.message)
    end
  end
end

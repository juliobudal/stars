module Rewards
  class ApproveRedemptionService < ApplicationService
    def initialize(redemption)
      @redemption = redemption
    end

    def call
      Rails.logger.info("[Rewards::ApproveRedemptionService] start redemption_id=#{@redemption.id}")

      result = ActiveRecord::Base.transaction do
        @redemption.lock!

        next fail_with("Resgate não está pendente") unless @redemption.pending?

        @redemption.update!(status: :approved)
        ok(@redemption)
      end

      Rails.logger.info("[Rewards::ApproveRedemptionService] success id=#{@redemption.id}") if result.success?
      result
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Rewards::ApproveRedemptionService] exception id=#{@redemption.id} error=#{e.message}")
      fail_with(e.message)
    end
  end
end

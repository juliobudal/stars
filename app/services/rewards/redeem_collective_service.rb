module Rewards
  # Resgate de recompensa coletiva. Não decrementa pontos individuais.
  # Cria Redemption{collective: true} anexada ao parent que solicitou.
  # Log na ActivityLog do parent (audit trail) com points = 0.
  class RedeemCollectiveService < ApplicationService
    def initialize(family:, reward:, requested_by:)
      @family = family
      @reward = reward
      @requested_by = requested_by
    end

    def call
      Rails.logger.info(
        "[Rewards::RedeemCollectiveService] start family_id=#{@family.id} reward_id=#{@reward.id} by=#{@requested_by.id}"
      )

      return fail_with("Recompensa não é coletiva") unless @reward.collective?
      return fail_with("Recompensa não pertence à família") unless @reward.family_id == @family.id
      return fail_with("Apenas pais podem resgatar metas coletivas") unless @requested_by.parent?

      goal = Rewards::WeeklyFamilyGoalService.call(family: @family)
      return fail_with("Falha ao calcular meta") unless goal.success?
      return fail_with("Meta semanal ainda não atingida") if goal.data[:earned] < @reward.cost

      redemption = ActiveRecord::Base.transaction do
        Redemption.create!(
          profile: @requested_by,
          reward: @reward,
          points: @reward.cost,
          status: :pending,
          collective: true
        ).tap do
          ActivityLog.create!(
            profile: @requested_by,
            log_type: :redeem,
            title: "Meta coletiva: #{@reward.title}",
            points: 0
          )
        end
      end

      Rails.logger.info("[Rewards::RedeemCollectiveService] success redemption_id=#{redemption.id}")
      ok(redemption)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[Rewards::RedeemCollectiveService] error=#{e.message}")
      fail_with(e.message)
    end
  end
end

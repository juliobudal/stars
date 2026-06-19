class Kid::RewardsController < Kid::BaseController
  def index
    catalog = Rewards::CatalogQuery.new(current_profile).call
    @rewards            = catalog.rewards
    @affordable_rewards = catalog.affordable
    @locked_rewards     = catalog.locked
    @redeemed_rewards   = catalog.redeemed
    @categories_with_rewards = Category
      .where(family_id: current_profile.family_id)
      .joins(:rewards)
      .distinct
      .ordered
    @reward_counts = @rewards.group_by(&:category_id).transform_values(&:size)
  end

  def redeem
    @reward = Reward.where(family_id: current_profile.family_id).find(params[:id])

    result = Rewards::RedeemService.new(profile: current_profile, reward: @reward).call
    if result.success?
      current_profile.reload
      catalog = Rewards::CatalogQuery.new(current_profile).call
      @rewards            = catalog.rewards
      @affordable_rewards = catalog.affordable
      @locked_rewards     = catalog.locked
      @redeemed_rewards   = catalog.redeemed
      @balance            = catalog.balance

      respond_to do |format|
        format.html { redirect_to kid_rewards_path, notice: "Resgate solicitado! Aguarde a aprovação." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to kid_rewards_path, alert: "Você não tem estrelas suficientes para este prêmio." }
        format.turbo_stream {
          render turbo_stream: turbo_stream.update(:flash, "Saldo insuficiente.")
        }
      end
    end
  end
end

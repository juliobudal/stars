class Kid::RewardsController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout "kid"

  def index
    family_id = current_profile.family_id
    balance = current_profile.points
    @rewards = Reward.where(family_id: family_id).includes(:category).order(:cost)
    @affordable_rewards = @rewards.select { |r| r.cost <= balance }
    @locked_rewards     = @rewards.reject { |r| r.cost <= balance }
    @redeemed_rewards = current_profile.redemptions.includes(:reward).order(created_at: :desc)
    @categories_with_rewards = Category
      .where(family_id: family_id)
      .joins(:rewards)
      .distinct
      .ordered
    @reward_counts = @rewards.group_by(&:category_id).transform_values(&:size)
  end

  def redeem
    @reward = Reward.where(family_id: current_profile.family_id).find(params[:id])

    result = Rewards::RedeemService.new(profile: current_profile, reward: @reward).call
    if result.success?
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

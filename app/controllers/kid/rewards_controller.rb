class Kid::RewardsController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout 'kid'

  def index
    @rewards = current_profile.family.rewards
  end

  def redeem
    @reward = current_profile.family.rewards.find(params[:id])
    
    if Rewards::RedeemService.new(profile: current_profile, reward: @reward).call
      respond_to do |format|
        format.html { redirect_to kid_rewards_path, notice: "Resgate solicitado! Aguarde a aprovação. 🎁" }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to kid_rewards_path, alert: "Você não tem estrelas suficientes para este prêmio. 😿" }
        format.turbo_stream {
          render turbo_stream: turbo_stream.update(:flash, "Saldo insuficiente.")
        }
      end
    end
  end
end

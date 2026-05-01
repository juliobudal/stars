class Kid::WishlistController < ApplicationController
  include Authenticatable
  before_action :require_child!
  layout "kid"

  def create
    reward = Reward.where(family_id: current_profile.family_id).find(params[:reward_id])
    result = Profiles::SetWishlistService.call(profile: current_profile, reward: reward)

    if result.success?
      respond_to do |fmt|
        fmt.html { redirect_to kid_rewards_path, notice: "Meta atualizada!" }
        fmt.turbo_stream { head :ok } # broadcast already pushed via Profile callback
      end
    else
      redirect_to kid_rewards_path, alert: result.error
    end
  end

  def destroy
    result = Profiles::SetWishlistService.call(profile: current_profile, reward: nil)

    if result.success?
      respond_to do |fmt|
        fmt.html { redirect_to kid_rewards_path, notice: "Meta removida." }
        fmt.turbo_stream { head :ok }
      end
    else
      redirect_to kid_rewards_path, alert: result.error
    end
  end
end

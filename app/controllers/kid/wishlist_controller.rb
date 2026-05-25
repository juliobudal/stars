class Kid::WishlistController < Kid::BaseController
  def create
    reward = Reward.where(family_id: current_profile.family_id).find(params[:reward_id])
    previous_reward = current_profile.wishlist_reward
    current_profile.update!(wishlist_reward: reward)

    respond_to do |fmt|
      fmt.html { redirect_to kid_rewards_path, notice: "Meta atualizada!" }
      fmt.turbo_stream { render_pin_swap(active: reward, previous: previous_reward) }
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    redirect_to kid_rewards_path, alert: e.message
  end

  def destroy
    previous_reward = current_profile.wishlist_reward
    current_profile.update!(wishlist_reward: nil)

    respond_to do |fmt|
      fmt.html { redirect_to kid_rewards_path, notice: "Meta removida." }
      fmt.turbo_stream { render_pin_swap(active: nil, previous: previous_reward) }
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    redirect_to kid_rewards_path, alert: e.message
  end

  private

  def render_pin_swap(active:, previous:)
    streams = []
    streams << pin_stream(active, pinned: true) if active
    streams << pin_stream(previous, pinned: false) if previous && previous.id != active&.id
    render turbo_stream: streams
  end

  def pin_stream(reward, pinned:)
    turbo_stream.replace(
      ActionView::RecordIdentifier.dom_id(reward, :pin),
      partial: "kid/rewards/pin_button",
      locals: { reward: reward, pinned: pinned }
    )
  end
end

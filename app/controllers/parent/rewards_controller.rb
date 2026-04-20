class Parent::RewardsController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  before_action :set_reward, only: [:destroy]

  layout 'parent'

  def index
    @rewards = current_profile.family.rewards.order(cost: :asc)
  end

  def new
    @reward = current_profile.family.rewards.build
  end

  def create
    @reward = current_profile.family.rewards.build(reward_params)
    if @reward.save
      redirect_to parent_rewards_path, notice: "Recompensa criada com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @reward.destroy
    redirect_to parent_rewards_path, notice: "Recompensa removida."
  end

  private

  def set_reward
    @reward = current_profile.family.rewards.find(params[:id])
  end

  def reward_params
    params.require(:reward).permit(:title, :cost, :icon)
  end
end

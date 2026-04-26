class Parent::RewardsController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  before_action :set_categories, only: [ :index, :new, :create, :edit, :update ]
  before_action :set_reward, only: [ :edit, :update, :destroy ]

  layout "parent"

  def index
    @rewards = Reward.where(family_id: current_profile.family_id).includes(:category).order(cost: :asc)
  end

  def new
    @reward = Reward.new(family_id: current_profile.family_id)
  end

  def create
    @reward = Reward.new(reward_params.merge(family_id: current_profile.family_id))
    if @reward.save
      redirect_to parent_rewards_path, notice: "Recompensa criada com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @reward.update(reward_params)
      redirect_to parent_rewards_path, notice: "Recompensa atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @reward.destroy
    redirect_to parent_rewards_path, notice: "Recompensa removida."
  end

  private

  def set_categories
    @categories = Category.where(family_id: current_profile.family_id).ordered
  end

  def set_reward
    @reward = Reward.where(family_id: current_profile.family_id).find(params[:id])
  end

  def reward_params
    params.require(:reward).permit(:title, :cost, :icon, :category_id)
  end
end

class Parent::RewardsController < ApplicationController
  include Authenticatable
  include Duplicatable
  include TemplateAddable
  before_action :require_parent!
  before_action :set_categories, only: [ :index, :new, :create, :edit, :update, :library ]
  before_action :set_reward, only: [ :edit, :update, :destroy, :redeem_collective, :duplicate ]

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
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @reward.update(reward_params)
      redirect_to parent_rewards_path, notice: "Recompensa atualizada."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @reward.destroy
      redirect_to parent_rewards_path, notice: "Recompensa removida."
    else
      redirect_to parent_rewards_path,
                  alert: "Não dá para excluir um prêmio que já foi resgatado — o histórico precisa dele. Edite-o se quiser ajustar."
    end
  end

  # Clones a reward so parents don't rebuild similar ones; lands on edit.
  def duplicate
    duplicate_record(@reward,
                     success_path: ->(copy) { edit_parent_reward_path(copy) },
                     failure_path: parent_rewards_path,
                     success_notice: "Prêmio duplicado. Ajuste o que quiser.") do |copy|
      # A duplicate defaults to an individual reward: cloning the `collective`
      # flag would silently spawn a second family goal that can hijack the kid
      # dashboard's family-goal widget (limit: 1). Parent can re-flag on edit.
      copy.collective = false
      copy.save!
    end
  end

  # ── Reward library (curated quick-add) ──────────────────────────────────
  def library
    @templates = Rewards::TemplateLibrary.all
    @existing_titles = Reward.where(family_id: current_profile.family_id).pluck(:title)
    @default_category = @categories.first
  end

  def add_from_template
    category = Category.where(family_id: current_profile.family_id).ordered.first
    if category.nil?
      redirect_to parent_categories_path, alert: "Crie uma categoria antes de adicionar prêmios."
      return
    end

    # Curated, spec-guarded templates → create! surfaces a broken template
    # loudly. Unknown/blank keys are dropped (find returns nil).
    add_from_templates(
      success_path: parent_rewards_path,
      library_path: library_parent_rewards_path,
      notice: ->(n) { "#{n} #{n == 1 ? 'prêmio adicionado' : 'prêmios adicionados'} ao catálogo." },
      empty_alert: "Nenhum prêmio selecionado."
    ) do |key|
      tpl = Rewards::TemplateLibrary.find(key)
      Reward.create!(family_id: current_profile.family_id, category_id: category.id,
                     title: tpl[:title], icon: tpl[:icon], cost: tpl[:cost]) if tpl
    end
  end

  def redeem_collective
    result = Rewards::RedeemCollectiveService.call(
      family: current_profile.family,
      reward: @reward,
      requested_by: current_profile
    )

    if result.success?
      redirect_to parent_root_path, notice: "Meta coletiva resgatada! 🎉"
    else
      redirect_to parent_root_path, alert: result.error
    end
  end

  private

  def set_categories
    @categories = Category.where(family_id: current_profile.family_id).ordered
  end

  def set_reward
    @reward = Reward.where(family_id: current_profile.family_id).find(params[:id])
  end

  def reward_params
    params.require(:reward).permit(:title, :cost, :icon, :category_id, :collective)
  end
end

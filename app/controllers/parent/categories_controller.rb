class Parent::CategoriesController < ApplicationController
  include Authenticatable
  before_action :require_parent!
  before_action :set_category, only: [ :edit, :update, :destroy ]

  layout "parent"

  def index
    @categories = scope.ordered
  end

  def new
    @category = scope.new
  end

  def create
    @category = scope.new(category_params)
    if @category.save
      redirect_to parent_categories_path, notice: "Categoria criada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to parent_categories_path, notice: "Categoria atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.destroy
      redirect_to parent_categories_path, notice: "Categoria removida."
    else
      redirect_to parent_categories_path,
                  alert: "Reatribua os prêmios antes de excluir esta categoria."
    end
  end

  private

  def scope
    Category.where(family_id: current_profile.family_id)
  end

  def set_category
    @category = scope.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :icon, :color)
  end
end

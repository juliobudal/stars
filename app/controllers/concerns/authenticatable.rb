module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :require_login
  end

  private

  def require_login
    unless current_profile
      redirect_to root_path, alert: "Por favor, selecione um perfil primeiro."
    end
  end

  def require_parent!
    unless current_profile&.parent?
      redirect_to root_path, alert: "Acesso restrito para pais."
    end
  end

  def require_child!
    unless current_profile&.child?
      redirect_to root_path, alert: "Acesso restrito para filhos."
    end
  end
end

module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :require_login
    helper_method :current_family
  end

  private

  def current_family
    current_profile&.family
  end

  # Raises ActiveRecord::RecordNotFound (→ 404) if record does not belong to
  # the current profile's family. Use as a defense-in-depth guard when a
  # record is loaded outside of a family-scoped association.
  def authorize_family!(record)
    return if record.nil?

    family_id =
      if record.respond_to?(:family_id) && record.family_id
        record.family_id
      elsif record.respond_to?(:profile) && record.profile
        record.profile.family_id
      end

    unless family_id && current_profile && family_id == current_profile.family_id
      raise ActiveRecord::RecordNotFound, "Record not in current family"
    end
  end

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

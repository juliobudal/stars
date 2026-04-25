module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :require_family!
    before_action :require_profile!
    helper_method :current_family, :current_profile
  end

  private

  def current_family
    return @current_family if defined?(@current_family)
    @current_family = Family.find_by(id: cookies.signed[:family_id])
  end

  def current_profile
    return @current_profile if defined?(@current_profile)
    @current_profile =
      if session[:profile_id] && current_family
        current_family.profiles.find_by(id: session[:profile_id])
      end
  end

  def require_family!
    return if current_family
    redirect_to new_family_session_path, alert: "Faça login na família."
  end

  def require_profile!
    return unless current_family
    return if current_profile
    redirect_to new_profile_session_path, alert: "Selecione um perfil."
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
end

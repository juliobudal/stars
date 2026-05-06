class ProfileSessionsController < ApplicationController
  PIN_MAX_ATTEMPTS = 5
  PIN_LOCKOUT_DURATION = 15.minutes

  skip_before_action :verify_authenticity_token, only: [ :create, :destroy ], raise: false

  before_action :require_family!

  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }

  def new
    @profiles = current_family.profiles.order(:created_at)
    @selected_profile = @profiles.find_by(id: params[:profile_id]) if params[:profile_id]
  end

  def create
    profile = current_family.profiles.find(params[:profile_id])

    if pin_locked?(profile)
      flash.now[:alert] = "Muitas tentativas. Tente novamente em alguns minutos."
      @profiles = current_family.profiles.order(:created_at)
      @selected_profile = profile
      return render :new, status: :too_many_requests
    end

    if profile.authenticate_pin(params[:pin])
      reset_pin_attempts(profile)
      family_id = cookies.signed[:family_id]
      reset_session
      cookies.signed.permanent[:family_id] = { value: family_id, httponly: true, same_site: :lax }
      session[:profile_id] = profile.id
      redirect_to profile.parent? ? parent_root_path : kid_root_path
    else
      record_pin_failure(profile)
      flash.now[:alert] = "PIN incorreto."
      @profiles = current_family.profiles.order(:created_at)
      @selected_profile = profile
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:profile_id)
    redirect_to new_profile_session_path, notice: "Perfil desconectado."
  end

  private

  def current_family
    @current_family ||= Family.find_by(id: cookies.signed[:family_id])
  end
  helper_method :current_family

  def require_family!
    redirect_to new_family_session_path, alert: "Faça login na família." unless current_family
  end

  def pin_locked?(profile)
    locked_until = Rails.cache.read(pin_lockout_key(profile))
    locked_until.present? && locked_until > Time.current
  end

  def record_pin_failure(profile)
    key = pin_attempts_key(profile)
    attempts = (Rails.cache.read(key) || 0) + 1
    Rails.cache.write(key, attempts, expires_in: PIN_LOCKOUT_DURATION)

    if attempts >= PIN_MAX_ATTEMPTS
      Rails.cache.write(pin_lockout_key(profile), PIN_LOCKOUT_DURATION.from_now, expires_in: PIN_LOCKOUT_DURATION)
    end
  end

  def reset_pin_attempts(profile)
    Rails.cache.delete(pin_attempts_key(profile))
    Rails.cache.delete(pin_lockout_key(profile))
  end

  def pin_attempts_key(profile)
    "pin:attempts:profile:#{profile.id}"
  end

  def pin_lockout_key(profile)
    "pin:lockout:profile:#{profile.id}"
  end
end

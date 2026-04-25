class InvitationsController < ApplicationController
  rate_limit to: 5, within: 15.minutes, only: :accept

  def show
    @invitation = ProfileInvitation.find_by(token: params[:token])
    if @invitation.nil? || @invitation.expires_at < Time.current || @invitation.accepted_at.present?
      render plain: "Convite expirado ou inválido.", status: :not_found
    end
  end

  def accept
    result = Auth::AcceptInvitation.call(token: params[:token])
    if result.success?
      cookies.signed.permanent[:family_id] = { value: result.family.id, httponly: true, same_site: :lax }
      redirect_to new_parent_profile_path(onboarding: true, invited: true)
    else
      render plain: result.error, status: :not_found
    end
  end
end

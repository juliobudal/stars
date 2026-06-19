class InvitationsController < ApplicationController
  rate_limit to: 5, within: 15.minutes, only: :accept

  def show
    @invitation = ProfileInvitation.find_by_token(params[:token])
    if @invitation.nil? || @invitation.expires_at < Time.current || @invitation.accepted_at.present?
      render :invalid, status: :not_found
    end
  end

  def accept
    result = Auth::AcceptInvitation.call(token: params[:token])
    if result.success?
      cookies.signed.permanent[:family_id] = { value: result.data[:family].id, httponly: true, same_site: :lax }
      redirect_to new_parent_profile_path(onboarding: true, invited: true)
    else
      @error_message = result.error
      render :invalid, status: :not_found
    end
  end
end

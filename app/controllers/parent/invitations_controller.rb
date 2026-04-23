class Parent::InvitationsController < ApplicationController
  include Authenticatable
  before_action :require_parent!

  layout "parent"

  def new
    @invitation = ProfileInvitation.new
  end

  def create
    @invitation = ProfileInvitation.new(
      family: current_profile.family,
      invited_by: current_profile,
      email: invitation_params[:email]
    )

    if @invitation.save
      InvitationMailer.invite(@invitation).deliver_later
      redirect_to parent_settings_path, notice: "Convite enviado"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def invitation_params
    params.require(:profile_invitation).permit(:email)
  end
end

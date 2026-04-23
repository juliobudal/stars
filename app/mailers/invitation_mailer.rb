class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @url = invitation_acceptance_url(token: invitation.token)
    mail(
      to: invitation.email,
      subject: "Junte-se à família #{invitation.family.name}"
    )
  end
end

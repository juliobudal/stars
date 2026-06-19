class InvitationMailer < ApplicationMailer
  # raw_token is passed explicitly (not read off the record) because the token
  # is no longer stored — only its digest is — and deliver_later reloads the
  # invitation from the DB, where raw_token would be gone.
  def invite(invitation, raw_token)
    @invitation = invitation
    @url = invitation_acceptance_url(token: raw_token)
    mail(
      to: invitation.email,
      subject: "Junte-se à família #{invitation.family.name}"
    )
  end
end

module Auth
  class AcceptInvitation < ApplicationService
    def initialize(token:)
      @token = token
    end

    def call
      invitation = ProfileInvitation.find_by(token: @token)
      return fail_with("Convite inválido.") if invitation.nil?
      return fail_with("Convite expirado.") if invitation.expires_at < Time.current
      return fail_with("Convite já aceito.") if invitation.accepted_at.present?

      invitation.update!(accepted_at: Time.current)
      ok(family: invitation.family, invitation: invitation)
    end
  end
end

require "ostruct"

module Auth
  class AcceptInvitation
    def initialize(token:)
      @token = token
    end

    def call
      invitation = ProfileInvitation.find_by(token: @token)
      return failure("Convite inválido.") if invitation.nil?
      return failure("Convite expirado.") if invitation.expires_at < Time.current
      return failure("Convite já aceito.") if invitation.accepted_at.present?

      invitation.update!(accepted_at: Time.current)
      OpenStruct.new(success?: true, family: invitation.family, invitation: invitation, error: nil)
    end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    private

    def failure(msg)
      OpenStruct.new(success?: false, family: nil, invitation: nil, error: msg)
    end
  end
end

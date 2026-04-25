require "ostruct"

module Auth
  class ResetPin
    def initialize(profile:, new_pin:, actor:)
      @profile = profile
      @new_pin = new_pin
      @actor = actor
    end

    def call
      return failure("Apenas pais podem redefinir PIN.") unless @actor&.parent?
      return failure("Perfil não pertence à mesma família.") unless @actor.family_id == @profile.family_id

      @profile.pin = @new_pin
      if @profile.save
        OpenStruct.new(success?: true, profile: @profile, error: nil)
      else
        failure(@profile.errors.full_messages.to_sentence)
      end
    end

    def self.call(**kwargs)
      new(**kwargs).call
    end

    private

    def failure(msg)
      OpenStruct.new(success?: false, profile: @profile, error: msg)
    end
  end
end

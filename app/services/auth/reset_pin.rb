module Auth
  class ResetPin < ApplicationService
    def initialize(profile:, new_pin:, actor:)
      @profile = profile
      @new_pin = new_pin
      @actor = actor
    end

    def call
      return fail_with("Apenas pais podem redefinir PIN.", data: @profile) unless @actor&.parent?
      return fail_with("Perfil não pertence à mesma família.", data: @profile) unless @actor.family_id == @profile.family_id

      @profile.pin = @new_pin
      if @profile.save
        ok(@profile)
      else
        fail_with(@profile.errors.full_messages.to_sentence, data: @profile)
      end
    end
  end
end

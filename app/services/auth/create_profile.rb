module Auth
  class CreateProfile < ApplicationService
    def initialize(family:, params:, pin:)
      @family = family
      @params = params
      @pin = pin
    end

    def call
      profile = @family.profiles.new(@params.merge(pin: @pin))
      if profile.save
        ok(profile)
      else
        fail_with(profile.errors.full_messages.to_sentence, data: profile)
      end
    end
  end
end

require "ostruct"

module Auth
  class CreateProfile
    def initialize(family:, params:, pin:)
      @family = family
      @params = params
      @pin = pin
    end

    def call
      profile = @family.profiles.new(@params.merge(pin: @pin))
      if profile.save
        OpenStruct.new(success?: true, profile: profile, error: nil)
      else
        OpenStruct.new(success?: false, profile: profile, error: profile.errors.full_messages.to_sentence)
      end
    end

    def self.call(**kwargs)
      new(**kwargs).call
    end
  end
end

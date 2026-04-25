require "ostruct"

module Auth
  class CreateFamily
    def initialize(params)
      @params = params
    end

    def call
      family = Family.new(@params)
      if family.save
        OpenStruct.new(success?: true, family: family, error: nil)
      else
        OpenStruct.new(success?: false, family: family, error: family.errors.full_messages.to_sentence)
      end
    end

    def self.call(params)
      new(params).call
    end
  end
end

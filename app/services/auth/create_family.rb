module Auth
  class CreateFamily < ApplicationService
    def initialize(params)
      @params = params
    end

    def call
      family = Family.new(@params)
      if family.save
        ok(family)
      else
        fail_with(family.errors.full_messages.to_sentence, data: family)
      end
    end
  end
end

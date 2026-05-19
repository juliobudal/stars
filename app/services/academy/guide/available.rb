# frozen_string_literal: true

module Academy
  module Guide
    # Predicate: is the Guide chat feature available right now?
    # Inert when `OPENROUTER_API_KEY` is missing — kid button hidden,
    # parent dashboard renders stub, controllers redirect.
    class Available < ApplicationService
      def call
        return fail_with(:no_llm_key) unless Academy.configured?
        ok(true)
      end

      def self.available?
        call.success?
      end
    end
  end
end

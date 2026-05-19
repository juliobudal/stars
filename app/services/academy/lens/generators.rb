# frozen_string_literal: true

module Academy
  module Lens
    module Generators
      # Returns the generator class for a given lens type symbol.
      # Raises ArgumentError on unknown types so the call path fails fast
      # rather than mis-routing to an unrelated subclass.
      def self.for(type)
        klass_name = type.to_s.camelize
        const_get(klass_name)
      rescue NameError
        raise ArgumentError, "Unknown lens type generator: #{type.inspect}"
      end
    end
  end
end

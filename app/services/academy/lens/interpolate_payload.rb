# frozen_string_literal: true

module Academy
  module Lens
    # Deep-walks a curated lens payload and substitutes the personalization
    # tokens that authors are instructed to preserve VERBATIM:
    #
    #   {{learner_name}}      → learner.display_name
    #   {{sibling_or_friend}} → "um amigo" (Academy doesn't reach into Family —
    #                          host-level coupling forbidden by module contract)
    #
    # The cached payload is shared across learners, so this never mutates the
    # input — it returns a new structure for render-time use only.
    class InterpolatePayload < ApplicationService
      # Accepts both the legacy `{{token}}` syntax (old cached payloads) and
      # the new `[[token]]` syntax (added to avoid colliding with Mustache /
      # Handlebars-style strings the LLM might emit naturally). Removing the
      # legacy form would invalidate every cached lens — not worth it.
      TOKEN_REGEX = /\{\{\s*(learner_name|sibling_or_friend)\s*\}\}|\[\[\s*(learner_name|sibling_or_friend)\s*\]\]/

      def initialize(payload:, learner:)
        @payload = payload
        @learner = learner
      end

      def call
        ok(walk(@payload))
      end

      # Convenience for views — returns the structure directly, never raises.
      def self.render(payload:, learner:)
        return payload if payload.nil?

        new(payload: payload, learner: learner).call.data
      end

      private

      def walk(node)
        case node
        when Hash
          node.transform_values { |v| walk(v) }
        when Array
          node.map { |v| walk(v) }
        when String
          interpolate(node)
        else
          node
        end
      end

      def interpolate(str)
        str.gsub(TOKEN_REGEX) do
          token = ::Regexp.last_match(1) || ::Regexp.last_match(2)
          case token
          when "learner_name"      then @learner&.display_name.presence || "você"
          when "sibling_or_friend" then "um amigo"
          end
        end
      end
    end
  end
end

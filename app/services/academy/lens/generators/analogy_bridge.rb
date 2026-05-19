# frozen_string_literal: true

module Academy
  module Lens
    module Generators
      # Adds a cross-reference check that the schema (draft-07) can't express:
      # every `mapping[].from` must be a literal item of `source_domain.elements`,
      # and every `mapping[].to` must be a literal item of `target_domain.elements`.
      # The prompt asks for this, but LLMs occasionally drift the wording between
      # the two sections — the kid then sees "Origem" / "Destino" lists that
      # don't line up with the bridges. Treating mismatches as SchemaInvalid
      # reuses Base's single retry with a message naming the exact offender.
      class AnalogyBridge < Base
        self.lens_type = :analogy_bridge

        private

        def validate!(payload)
          super
          enforce_mapping_cross_references!(payload)
        end

        def enforce_mapping_cross_references!(payload)
          source_elements = Array(payload.dig("source_domain", "elements"))
          target_elements = Array(payload.dig("target_domain", "elements"))
          mapping = Array(payload["mapping"])

          errors = mapping.each_with_index.flat_map do |pair, i|
            from = pair["from"]
            to = pair["to"]
            list = []
            unless source_elements.include?(from)
              list << "mapping[#{i}].from (#{from.inspect}) não bate com nenhum item de source_domain.elements (#{source_elements.inspect}). Corrija um dos dois pra ficarem idênticos."
            end
            unless target_elements.include?(to)
              list << "mapping[#{i}].to (#{to.inspect}) não bate com nenhum item de target_domain.elements (#{target_elements.inspect}). Corrija um dos dois pra ficarem idênticos."
            end
            list
          end

          raise SchemaInvalid.new(errors) if errors.any?
        end
      end
    end
  end
end

# frozen_string_literal: true

module Academy
  module Lens
    # Positive gate for lens openers — complements `FORBIDDEN_TONE_PATTERNS`.
    # After Plan J (2026-05-20), the wonder-hook ("Você sabia que…") is
    # rehabilitated. This module names the OK patterns so the curator
    # tooling (and the LLM judge, when reactivated) can recognize them.
    #
    # An opener is considered acceptable when EITHER:
    #   * The first sentence matches a known wonder-hook pattern, OR
    #   * The first sentence is concrete-short (≤ 12 words, ends with .!?).
    #
    # Empty fluff still trips `FORBIDDEN_TONE_PATTERNS`, so this gate is
    # additive — it doesn't relax the existing ban list.
    module OpenerCheck
      WONDER_OPENERS_OK = [
        /\bvocê sabia que\b/i,
        /\brepara (isso|nisso)\b/i,
        /\bolha (só|isso|essa|esse)\b/i,
        /\bespera\b/i,
        /\btem uma coisa estranha\b/i,
        /\bse alguém te perguntar\b/i,
        /\bagora (presta|olha|repara)\b/i
      ].freeze

      module_function

      def has_hook?(text)
        first = first_sentence(text)
        return false if first.blank?

        WONDER_OPENERS_OK.any? { |re| first.match?(re) } ||
          first.split.size <= 12
      end

      def first_sentence(text)
        text.to_s.strip.split(/(?<=[.!?…])\s/).first.to_s.strip
      end
    end
  end
end

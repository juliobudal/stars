# frozen_string_literal: true

module Academy
  module Lens
    # Picks ONE judge-approved lens payload to use as the few-shot example
    # inside a prompt ERB. The prompt's hardcoded example stays as a
    # fallback for cold-pool cases (new lens types, fresh DB) — see the
    # `<% if curated_example_json %>` branches in the templates.
    #
    # Selection rules (cheap, single SELECT):
    #   * same lens_type (form must match)
    #   * different concept from the target (avoid leaking the target's
    #     "essence" sentence verbatim)
    #   * different concept.category when possible (more pedagogical variety)
    #   * judge_verdict = "PASS" AND judge_overall_score >= EXAMPLE_FLOOR
    #   * not quality_flagged
    #   * RANDOM among matches → variety across generations
    #
    # Why we don't include the example in the cache key:
    # cache continues to be keyed by (concept, lens_type, age_band, locale,
    # template_version, mastery_tier, prompt_digest). The first kid to land
    # on a cold bucket fixes the example for that bucket. This matches the
    # existing contract — "one good curation benefits every kid in the
    # bucket" — and keeps hit rates intact. The variety effect is
    # ACROSS buckets (different concepts/types), not within one.
    class ExamplePicker < ApplicationService
      # Minimum judge score for a payload to be reused as a few-shot.
      # Judge v4 emits 0..100 (factual/concept/safety). 85 is intentionally
      # strict — we'd rather fall back to the hardcoded example than train
      # the model on a mediocre one. As a side effect, the cutoff also
      # filters out v3-era cache rows (max 12 on the old scale), so the
      # rubric shift cleans the few-shot pool automatically.
      EXAMPLE_FLOOR = 85

      def initialize(concept:, lens_type:, age_band: "kid", locale: "pt-BR")
        @concept = concept
        @lens_type = lens_type.to_s
        @age_band = age_band
        @locale = locale
      end

      def call
        return ok(payload: nil) unless enabled?

        row = candidate_relation.order(Arel.sql("RANDOM()")).limit(1).first
        return ok(payload: nil) unless row

        ok(payload: row.payload, source: { lens_cache_id: row.id, concept_id: row.concept_id })
      rescue => e
        Rails.logger.warn(
          "[Academy::Lens::ExamplePicker] picker failed " \
          "concept=#{@concept.id} lens=#{@lens_type}: #{e.class}: #{e.message}"
        )
        ok(payload: nil)
      end

      private

      def enabled?
        return false unless defined?(::Academy::LensCache)
        ::Academy::Lens::Catalog.types.include?(@lens_type.to_sym)
      end

      def candidate_relation
        rel = ::Academy::LensCache
          .servable
          .where(lens_type: @lens_type, age_band: @age_band, locale: @locale)
          .where(judge_verdict: "PASS")
          .where("judge_overall_score >= ?", EXAMPLE_FLOOR)
          .where.not(concept_id: @concept.id)

        same_category = ::Academy::Concept
          .where(category: @concept.category)
          .where.not(id: @concept.id)
          .pluck(:id)

        # Prefer different-category examples for pedagogical variety.
        # If that pool is empty, allow same-category (still excluding the
        # target concept itself, which is enforced above).
        cross = rel.where.not(concept_id: same_category)
        cross.exists? ? cross : rel
      end
    end
  end
end

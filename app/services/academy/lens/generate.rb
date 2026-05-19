# frozen_string_literal: true

module Academy
  module Lens
    # Cache-aware entry point for lens content.
    #
    #   REQ-LGEN-003 — cache keyed by (concept_id, lens_type, age_band, locale,
    #                  template_version, mastery_tier, prompt_digest)
    #   REQ-LGEN-004 — schema + tone validation before caching (Generators::Base)
    #   REQ-LGEN-005 — failed generations are NEVER cached
    #   REQ-LGEN-007 — concurrent misses serialize via unique-index upsert
    #   REQ-LGEN-008 — flagged rows are NOT servable
    #
    # `mastery_tier` keeps the cache shareable across learners in the same
    # bucket (novato vs avançado). `prompt_digest` auto-invalidates when
    # the prompt file is edited — no manual template_version bumps needed.
    class Generate < ApplicationService
      def initialize(concept:, lens_type:, age_band: "kid", locale: "pt-BR",
                     generator: nil, force_refresh: false, learner_id: nil)
        @concept = concept
        @lens_type = lens_type.to_sym
        @age_band = age_band
        @locale = locale
        @generator = generator
        @force_refresh = force_refresh
        @learner_context = LearnerContext.build(learner_id: learner_id, concept: concept)
      end

      def call
        # Curated-first (academy-curated-static-pivot.md): if a human-authored
        # payload exists for this (concept, lens_type, age_band, locale), serve
        # it. Curated rows are pinned to `prompt_digest = "curated"` so they
        # don't get invalidated by prompt template edits. force_refresh skips
        # cache entirely (curated AND llm) and re-drafts via LLM.
        unless @force_refresh
          curated = lookup_curated
          return ok(curated) if curated
        end

        entry = Catalog.fetch(@lens_type)
        template_version = entry.template_version

        # Compute digest from the on-disk prompt source. We instantiate a
        # generator just for its `prompt_digest` because that's where
        # template_source caching lives — avoids reading the file twice.
        klass = @generator || Generators.for(@lens_type)
        probe = klass.new(concept: @concept, age_band: @age_band, locale: @locale,
                          learner_context: @learner_context)
        prompt_digest = probe.prompt_digest

        unless @force_refresh
          existing = lookup_cache(template_version, prompt_digest)
          return ok(existing) if existing
        end

        gen_result = probe.call
        return gen_result unless gen_result.success?

        row = upsert_cache!(template_version, prompt_digest, gen_result.data)
        ok(row)
      end

      private

      def lookup_curated
        LensCache.servable.curated
          .where(concept_id: @concept.id, lens_type: @lens_type.to_s,
                 age_band: @age_band, locale: @locale)
          .order(updated_at: :desc).first
      end

      # Prefers an exact tier match; falls back to "any" so prewarm-generated
      # content is still servable to logged-in learners on cold paths.
      def lookup_cache(template_version, prompt_digest)
        scope = LensCache.servable.for_key(
          concept_id: @concept.id, lens_type: @lens_type,
          age_band: @age_band, locale: @locale, template_version: template_version
        ).where(prompt_digest: prompt_digest)

        scope.where(mastery_tier: @learner_context.mastery_tier).first ||
          scope.where(mastery_tier: "any").first
      end

      def upsert_cache!(template_version, prompt_digest, gen_data)
        attrs = {
          concept_id: @concept.id,
          lens_type: @lens_type.to_s,
          age_band: @age_band,
          locale: @locale,
          template_version: template_version,
          mastery_tier: gen_data[:mastery_tier] || @learner_context.mastery_tier,
          prompt_digest: prompt_digest,
          payload: gen_data[:payload],
          model_id: gen_data[:model_id],
          tokens_in: gen_data[:tokens_in],
          tokens_out: gen_data[:tokens_out],
          generated_at: Time.current,
          quality_flagged: false,
          judge_verdict: gen_data[:judge_verdict],
          judge_overall_score: gen_data[:judge_overall_score],
          judge_revision_cycles: gen_data[:judge_revision_cycles] || 0,
          judge_critique: gen_data[:judge_critique],
          created_at: Time.current,
          updated_at: Time.current
        }

        inserted = LensCache.insert(attrs, unique_by: :idx_academy_lens_cache_unique)
        if inserted.any?
          LensCache.find(inserted.first["id"])
        else
          lookup_cache(template_version, prompt_digest) ||
            raise("Concurrent insert lost but row not found — schema mismatch?")
        end
      end
    end
  end
end

# frozen_string_literal: true

module Academy
  module Lens
    # Curated-only entry point for lens content.
    #
    # Returns the curated `LensCache` row for (concept, lens_type, age_band,
    # locale). Curated rows are seeded from `db/seeds/academy_lens_payloads/`
    # by the seeder in `db/seeds/academy_lens_payloads.rb`.
    #
    # Fails with `:no_curated_payload` when no curated row exists — callers
    # (Missions::Begin / Missions::AdvanceLens) handle this by falling back
    # to a different lens type for the same concept.
    #
    # Historical context: this service used to orchestrate an LLM-backed
    # generation path (Generators::*, prompts/*.md.erb, an LLM judge, and a
    # mastery-tiered cache). That pipeline was retired in favor of fully
    # curated content. See `.planning/designs/academy-curated-static-pivot.md`.
    # The `generator:` / `force_refresh:` / `learner_id:` kwargs are kept
    # as no-ops so existing callsites don't have to change.
    class Generate < ApplicationService
      def initialize(concept:, lens_type:, age_band: "kid", locale: "pt-BR",
                     generator: nil, force_refresh: false, learner_id: nil, learner: nil)
        @concept = concept
        @lens_type = lens_type.to_sym
        @age_band = age_band
        @locale = locale
        @learner = learner
        # generator/force_refresh/learner_id intentionally ignored — kept
        # for caller-compatibility with the retired LLM pipeline.
      end

      def call
        ResolveCuratedPayload.call(
          concept: @concept, lens_type: @lens_type,
          age_band: @age_band, locale: @locale, learner: @learner
        )
      end
    end
  end
end

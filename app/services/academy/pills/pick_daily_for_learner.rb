# frozen_string_literal: true

module Academy
  module Pills
    # Picks the "Pílula do Dia" for a learner. Idempotent intra-day — once
    # served, the same pill is returned for the rest of the day.
    #
    # Result data shape:
    #   { lens_cache: <Academy::LensCache>, pill_view: <Academy::PillView> }
    #
    # Selection heuristic (in priority order):
    #   1. Idempotent: if a pill_view exists for today, return it.
    #   2. Prefer concepts from curiosity-of-the-world categories
    #      (mundo_natural, linguagem, historia, matematica, cientifico).
    #      The Academy v3 mandate is "more discovery, less meta-skill".
    #   3. Exclude lens_caches the learner has already received as a pill.
    #   4. When the interest variant exists for the learner's top interest,
    #      pick it (via Lens::ResolveCuratedPayload).
    #   5. Tie-break randomly inside the candidate set so two siblings
    #      see different things on the same day.
    #
    # Fails (:no_pill_available) when no candidate exists — should be rare;
    # callers render a graceful empty card.
    class PickDailyForLearner < ApplicationService
      PREFERRED_CATEGORIES  = %w[mundo_natural linguagem historia matematica cientifico saude].freeze
      PREFERRED_LENS_TYPES  = %w[scientific narrative analogy_bridge first_person historical].freeze

      def initialize(learner:)
        @learner = learner
      end

      def call
        return fail_with(:no_learner) unless @learner

        existing = ::Academy::PillView.for_learner(@learner.id).today.recent.first
        if existing
          return ok(lens_cache: existing.lens_cache, pill_view: existing)
        end

        cache = pick_candidate
        return fail_with(:no_pill_available) unless cache

        pill_view = ::Academy::PillView.create!(
          learner_id: @learner.id, lens_cache_id: cache.id, status: "served"
        )
        ok(lens_cache: cache, pill_view: pill_view)
      end

      private

      def pick_candidate
        already_served_ids = ::Academy::PillView.for_learner(@learner.id).pluck(:lens_cache_id)

        base = ::Academy::LensCache.curated.servable
                 .joins(:concept)
                 .where(age_band: "kid", locale: "pt-BR")
                 .where(academy_concepts: { active: true })
                 .where(lens_type: PREFERRED_LENS_TYPES)
                 .where.not(id: already_served_ids)

        preferred = base.where(academy_concepts: { category: PREFERRED_CATEGORIES })
        scope = preferred.exists? ? preferred : base

        # Optional: bias toward the learner's top interest. We don't *require*
        # the variant to exist — the default interest_key=NULL row is fine.
        # When a variant matches the top interest, give it priority.
        top_interest = @learner.respond_to?(:top_interest_key) ? @learner.top_interest_key : nil
        if top_interest.present?
          variant = scope.where(interest_key: top_interest).order("RANDOM()").first
          return variant if variant
        end

        scope.where(interest_key: nil).order("RANDOM()").first ||
          scope.order("RANDOM()").first
      end
    end
  end
end

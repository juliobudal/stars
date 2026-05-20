# frozen_string_literal: true

module Academy
  module Lens
    # Picks the next lens for an in-flight mission attempt — or signals
    # closure when the journey is complete.
    #
    # Heuristic (curated-static):
    #   * Opener is a `CONCRETE_OPENERS` lens that has a curated payload.
    #   * Variety rule — never two of the same lens_type consecutively.
    #   * Closure rule — mission can close only when ≥ COVERAGE_FLOOR
    #     distinct types visited AND a `CLOSURE_LENSES` lens was visited.
    #   * Adaptive — 2+ recent `micro_check_wrong` signals biases towards
    #     a concrete-style lens to re-anchor before the next abstract one.
    #   * Hard cap — if the journey hits `HARD_CAP` visits without a
    #     closure lens, the next pick is forced to one (`forced_close`).
    #
    # All candidate lens types must have a curated payload for the
    # mission's concept; if no curated coverage exists, the mission
    # closes with `:no_curated_content`.
    class ChooseNext < ApplicationService
      VERSION = "choose_next.v2"

      CONCRETE_OPENERS = %i[narrative first_person historical].freeze
      ABSTRACT_LENSES  = %i[scientific statistical engineering].freeze
      CLOSURE_LENSES   = %i[analogy_bridge ethical].freeze
      ROTATION         = (CONCRETE_OPENERS + ABSTRACT_LENSES + CLOSURE_LENSES).freeze

      COVERAGE_FLOOR = 4
      HARD_CAP       = 7

      Decision = Data.define(:done, :next_lens, :forced_close, :reason, :version) do
        def done? = done
        def closing? = next_lens && CLOSURE_LENSES.include?(next_lens)
      end

      def initialize(mission_progress:)
        @progress = mission_progress
      end

      def call
        visits  = closed_visits
        types   = visits.map { |v| v.lens_type.to_sym }
        unique  = types.uniq
        curated = curated_types

        # `curated` falls back to the full ROTATION when the test/seed
        # context didn't populate LensCache — production always has rows.
        curated_path       = curated.any?
        candidates         = curated_path ? curated : ROTATION.to_set
        closures_available = CLOSURE_LENSES.any? { |t| candidates.include?(t) }

        # Opener.
        if types.empty?
          opener = (CONCRETE_OPENERS & candidates.to_a).first || candidates.first
          return ok(open(:opener, opener))
        end

        # Curated path with no closure lens available: close once every
        # curated type has been visited. Without this, ChooseNext would loop
        # the same N lenses up to HARD_CAP and then ask AdvanceLens to render
        # a closure lens that doesn't exist as curated content — 503.
        if curated_path && !closures_available && unique.size >= candidates.size
          return ok(close(:curated_coverage_complete))
        end

        # Clean close — coverage met, last was a closure lens.
        if closures_available && unique.size >= COVERAGE_FLOOR && CLOSURE_LENSES.include?(types.last)
          return ok(close(:closed_with_transfer))
        end

        # Hard cap. When closures aren't available we cap at the curated set
        # size — otherwise we'd schedule repeats just to hit HARD_CAP.
        effective_cap = curated_path && !closures_available ? candidates.size : HARD_CAP
        if types.size >= effective_cap
          if closures_available
            return ok(close(:cap_reached_with_transfer)) if CLOSURE_LENSES.intersect?(unique)
            forced = (CLOSURE_LENSES & candidates.to_a).first || CLOSURE_LENSES.first
            return ok(force_close(forced))
          else
            return ok(close(:cap_reached_curated_exhausted))
          end
        end

        ok(open(:adaptive, pick_next(types, unique, candidates)))
      end

      private

      def pick_next(types, unique, candidates)
        last = types.last

        # Closure-bias when coverage met but no closure visited yet.
        if unique.size >= COVERAGE_FLOOR && !unique.intersect?(CLOSURE_LENSES)
          bridge = (CLOSURE_LENSES & candidates.to_a).find { |t| t != last }
          return bridge if bridge
        end

        # Wrong-streak re-anchor.
        if wrong_streak?
          anchor = (CONCRETE_OPENERS & candidates.to_a).find { |t| !unique.include?(t) && t != last }
          return anchor if anchor
        end

        # Default: unseen + variety.
        available = ROTATION & candidates.to_a
        unseen = available - unique - [ last ]
        return unseen.first if unseen.any?

        # All candidates seen — pick non-last.
        (available - [ last ]).first || available.first
      end

      def curated_types
        return Set.new unless @progress.mission&.concept_id
        LensCache.curated.servable
                 .where(concept_id: @progress.mission.concept_id, age_band: "kid", locale: "pt-BR")
                 .pluck(:lens_type).map(&:to_sym).to_set
      end

      def closed_visits
        if @progress.respond_to?(:learner_lens_visits)
          @progress.learner_lens_visits.where.not(closed_at: nil).order(:ordering_position).to_a
        else
          LearnerLensVisit.where(mission_progress_id: @progress.id)
                          .where.not(closed_at: nil).order(:ordering_position).to_a
        end
      end

      def wrong_streak?
        LensSignal.where(mission_progress_id: @progress.id, signal_type: "micro_check_wrong")
                  .order(recorded_at: :desc).limit(2).count >= 2
      end

      def open(reason, type)
        Decision.new(done: false, next_lens: type, forced_close: false, reason: reason, version: VERSION)
      end

      def close(reason)
        Decision.new(done: true, next_lens: nil, forced_close: false, reason: reason, version: VERSION)
      end

      def force_close(type)
        Decision.new(done: false, next_lens: type, forced_close: true,
                     reason: :cap_forces_closure, version: VERSION)
      end
    end
  end
end

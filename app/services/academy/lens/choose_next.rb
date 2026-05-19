# frozen_string_literal: true

module Academy
  module Lens
    # The heart of v5: picks the next lens (or signals mission closure)
    # given an in-flight mission attempt's history of visits + signals.
    #
    # Heuristic-first (REQ-LMSN-003/004/005, design.md §4):
    #
    #   * Concrete-first opener — first lens chosen from CONCRETE_OPENERS.
    #   * Variety rule — never two of the same lens_type consecutively.
    #   * Closure rule — mission can close only when ≥ COVERAGE_FLOOR
    #     distinct types visited AND at least one closure-type lens was
    #     completed; if not closed by HARD_CAP, force closure (analogy_bridge).
    #   * Adaptive — recent micro_check_wrong streak biases towards a
    #     concrete-style lens to re-anchor before the next abstract one.
    #
    # Signature: returns a struct with `done:` boolean. If not done, returns
    # `next_lens:` symbol. If forced, sets `forced_close: true`.
    class ChooseNext < ApplicationService
      VERSION = "choose_next.v1"

      # Order matters — first 3 are openers; last two are closures.
      CONCRETE_OPENERS    = %i[narrative first_person historical].freeze
      ABSTRACT_LENSES     = %i[scientific statistical engineering].freeze
      CLOSURE_LENSES      = %i[analogy_bridge ethical].freeze

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
        visits = closed_visits
        visited_types = visits.map { |v| v.lens_type.to_sym }
        unique_types = visited_types.uniq

        # Curated coverage gate: when the mission's concept has any curated
        # payloads, restrict the journey to those lens types. Outside of the
        # curated set, runtime would fall through to LLM — which contradicts
        # the curated-static pivot. If the concept has zero curated rows,
        # @curated_types stays nil and rotation falls back to all 8 types
        # (legacy LLM-fallback path, preserved for un-curated missions).
        @curated_types = curated_types_for(@progress.mission&.concept_id)

        # Opening visit — pick from concrete openers ∩ curated (if any).
        if visits.empty?
          opener = first_available(CONCRETE_OPENERS)
          return ok(open_decision(:no_visits, opener)) if opener
          return ok(close_decision(:no_curated_content)) if @curated_types && @curated_types.empty?
          return ok(open_decision(:no_visits, CONCRETE_OPENERS.first))
        end

        if eligible_to_close?(unique_types) && visited_types.last && CLOSURE_LENSES.include?(visited_types.last.to_sym)
          return ok(close_decision(:closed_with_transfer))
        end

        if visited_types.size >= HARD_CAP
          # Cap reached — close.
          if CLOSURE_LENSES.intersect?(unique_types)
            return ok(close_decision(:cap_reached_with_transfer))
          else
            return ok(force_close_decision)
          end
        end

        next_lens = pick_next(visited_types, unique_types)
        ok(open_decision(:adaptive_pick, next_lens))
      end

      private

      # Returns the set of lens types with curated coverage for the given
      # concept, or nil if no curated rows exist at all for that concept
      # (legacy LLM-fallback path preserved). Returning [] is meaningful: it
      # means "concept has curated rows but for other locales/age_bands" — we
      # treat that as exhausted coverage and let the caller close.
      def curated_types_for(concept_id)
        return nil unless concept_id
        rows = LensCache.curated.servable
                        .where(concept_id: concept_id, age_band: "kid", locale: "pt-BR")
                        .pluck(:lens_type)
        return nil if rows.empty?
        rows.map(&:to_sym).uniq.to_set
      end

      # Picks the first lens from `preferences` that is curated-available.
      # Falls back to nil if none match and we're in curated-only mode.
      # In legacy (no curated rows) mode, returns preferences.first.
      def first_available(preferences)
        return preferences.first if @curated_types.nil?
        preferences.find { |t| @curated_types.include?(t) }
      end

      def closed_visits
        @progress.respond_to?(:learner_lens_visits) ? @progress.learner_lens_visits.where.not(closed_at: nil).order(:ordering_position).to_a : LearnerLensVisit.where(mission_progress_id: @progress.id).where.not(closed_at: nil).order(:ordering_position).to_a
      end

      def eligible_to_close?(unique_types)
        unique_types.size >= COVERAGE_FLOOR &&
          unique_types.intersect?(CLOSURE_LENSES)
      end

      def pick_next(visited_types, unique_types)
        last = visited_types.last&.to_sym

        # In curated-only mode, every candidate must also live in @curated_types.
        # In legacy mode (@curated_types nil), this passes through unchanged.
        curated_filter = ->(t) { @curated_types.nil? || @curated_types.include?(t) }

        # Closure-bias: coverage floor met but no closure visited yet.
        if unique_types.size >= COVERAGE_FLOOR && !unique_types.intersect?(CLOSURE_LENSES)
          choice = CLOSURE_LENSES.find { |t| t != last && curated_filter.call(t) }
          return choice if choice
        end

        # Adaptive: recent wrong streak → re-anchor with a concrete lens.
        if recent_wrong_streak?(@progress)
          concrete = CONCRETE_OPENERS.find { |t| !unique_types.include?(t) && t != last && curated_filter.call(t) }
          return concrete if concrete
        end

        rotation = (CONCRETE_OPENERS + ABSTRACT_LENSES + CLOSURE_LENSES).uniq

        # Prefer unseen + curated.
        unseen = rotation.reject { |t| unique_types.include?(t) || t == last || !curated_filter.call(t) }
        return unseen.first if unseen.any?

        # All curated types already visited — pick any curated ≠ last, allowing repeat.
        any_curated = rotation.find { |t| t != last && curated_filter.call(t) }
        return any_curated if any_curated

        # Legacy fallback (no curated content at all): old behavior.
        rotation.find { |t| t != last } || (CONCRETE_OPENERS - [ last ]).first
      end

      def recent_wrong_streak?(progress)
        wrong_count_recent = LensSignal
                               .where(mission_progress_id: progress.id, signal_type: "micro_check_wrong")
                               .order(recorded_at: :desc)
                               .limit(2)
                               .count
        wrong_count_recent >= 2
      end

      def open_decision(reason, lens_type)
        Decision.new(done: false, next_lens: lens_type, forced_close: false, reason: reason, version: VERSION)
      end

      def close_decision(reason)
        Decision.new(done: true, next_lens: nil, forced_close: false, reason: reason, version: VERSION)
      end

      def force_close_decision
        # We hit the cap without a closure lens being visited yet — force a
        # final closure lens as the very next visit so the mission ends with
        # a transfer attempt rather than as `closed_without_transfer`.
        # Curated-aware: pick a closure that is actually curated for this
        # mission. Falls back to CLOSURE_LENSES.first only in legacy mode.
        closure = CLOSURE_LENSES.find { |t| @curated_types.nil? || @curated_types.include?(t) } ||
                  CLOSURE_LENSES.first
        Decision.new(done: false, next_lens: closure, forced_close: true,
                     reason: :cap_forces_closure, version: VERSION)
      end
    end
  end
end

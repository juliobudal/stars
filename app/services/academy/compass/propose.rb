# frozen_string_literal: true

module Academy
  module Compass
    # v4 substitute for Adapt::NextMissionFor. Instead of one suggested
    # mission, returns three candidates with a `reason` legible to the kid:
    #
    #   - :hot_trail        — next mission on the trail with highest affinity
    #   - :new_territory    — opener mission of the least-explored subject
    #   - :revisit          — mission revisiting a partially-known concept
    #
    # If any slot can't be filled (sparse data, new account), it falls back
    # to the legacy Adapt::NextMissionFor pick as a single candidate.
    class Propose < ApplicationService
      Card = Data.define(:slot, :mission, :reason)
      Plan = Data.define(:cards) do
        def hot_trail     = cards.find { |c| c.slot == :hot_trail }
        def new_territory = cards.find { |c| c.slot == :new_territory }
        def revisit       = cards.find { |c| c.slot == :revisit }
      end

      def initialize(learner_id:)
        @learner_id = learner_id
      end

      def call
        cards = [
          hot_trail_card,
          new_territory_card,
          revisit_card
        ].compact

        cards = fallback_cards if cards.empty?

        ok(Plan.new(cards: cards))
      end

      private

      # ── Slot 1: hot trail ─────────────────────────────────────────────
      def hot_trail_card
        top_affinity_subject = LearnerSignal
                                 .for_learner(@learner_id)
                                 .order(affinity_score: :desc)
                                 .limit(1)
                                 .pick(:subject_id)
        return nil unless top_affinity_subject

        mission = next_untouched_mission_in_subject(top_affinity_subject)
        return nil unless mission

        Card.new(
          slot: :hot_trail,
          mission: mission,
          reason: %(Você tá quente em "#{mission.subject.name}" — esse é o próximo padrão.)
        )
      end

      # ── Slot 2: new territory ─────────────────────────────────────────
      def new_territory_card
        touched_ids = LearnerSignal.for_learner(@learner_id).pluck(:subject_id).to_set
        cold_subject = Subject.active.find { |s| !touched_ids.include?(s.id) }
        return nil unless cold_subject

        mission = next_untouched_mission_in_subject(cold_subject.id)
        return nil unless mission

        Card.new(
          slot: :new_territory,
          mission: mission,
          reason: %(Território novo: "#{cold_subject.name}" — você nunca explorou.)
        )
      end

      # ── Slot 3: revisit ───────────────────────────────────────────────
      def revisit_card
        learner_concepts = LearnerConcept
                             .for_learner(@learner_id)
                             .where(level: 1..2)
                             .where("last_seen_at < ?", 7.days.ago)
                             .order(:last_seen_at)
                             .limit(5)
                             .includes(:concept)
        return nil if learner_concepts.empty?

        # Find an untouched mission tagging one of these concepts in a NEW
        # subject (transfer-friendly).
        concept_ids = learner_concepts.map(&:concept_id)
        done_mission_ids = MissionProgress.where(learner_id: @learner_id).pluck(:mission_id)
        mission = Mission
                    .where(active: true, concept_id: concept_ids)
                    .where.not(id: done_mission_ids)
                    .includes(:subject)
                    .first
        return nil unless mission

        Card.new(
          slot: :revisit,
          mission: mission,
          reason: %(Aquele padrão que vc viu antes voltou — em outro lugar.)
        )
      end

      # ── Fallback ──────────────────────────────────────────────────────
      def fallback_cards
        legacy = Adapt::NextMissionFor.call(learner_id: @learner_id).data
        return [] unless legacy

        [ Card.new(slot: :hot_trail, mission: legacy, reason: "Próxima descoberta sugerida.") ]
      end

      # ── Helpers ───────────────────────────────────────────────────────
      def next_untouched_mission_in_subject(subject_id)
        done_mission_ids = MissionProgress.where(learner_id: @learner_id).pluck(:mission_id)

        Mission
          .where(active: true, subject_id: subject_id)
          .where.not(trail_id: nil)
          .where.not(id: done_mission_ids)
          .includes(:subject)
          .order(:position_in_trail, :order_in_subject, :id)
          .first
      end
    end
  end
end

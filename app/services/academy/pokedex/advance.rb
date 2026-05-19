# frozen_string_literal: true

module Academy
  module Pokedex
    # v5 Pokédex ladder. Idempotent + monotonic (REQ-PKD-002/003).
    #
    # Levels:
    #   3 mastered    — ≥ 2 completed missions on this concept across ≥ 2 subjects
    #   2 recognized  — ≥ 1 completed mission on this concept
    #   1 spotted     — ≥ 1 LearnerLensVisit on this concept (open or closed)
    #   0 silhouette  — none of the above
    #
    # Triggers (callers):
    #   :lens_opened       — fired by Missions::Begin/AdvanceLens when a new
    #                        LearnerLensVisit is created (pulls L0 → L1).
    #   :mission_completed — fired by Missions::Finalize (L1/L2 → L2/L3).
    #   :transfer_detected — legacy Transfer::Detect path; bumps to L3
    #                        directly on a cross-area transfer event.
    #
    # On any successful level increase, emits a `concept_evolved` signal
    # so affinity tracking and Turbo Stream broadcasts pick it up.
    class Advance < ApplicationService
      VALID_TRIGGERS = %i[lens_opened mission_completed transfer_detected].freeze

      def initialize(learner_id:, concept:, mission: nil, trigger:)
        @learner_id = learner_id
        @concept = concept
        @mission = mission
        @trigger = trigger.to_sym
      end

      def call
        return fail_with("Trigger inválido: #{@trigger}") unless VALID_TRIGGERS.include?(@trigger)
        return fail_with("Conceito ausente") unless @concept&.id

        prev_level = nil

        ActiveRecord::Base.transaction do
          @record = LearnerConcept.find_or_initialize_by(
            learner_id: @learner_id, concept_id: @concept.id
          )
          prev_level = @record.level.to_i
          @record.first_seen_at ||= Time.current

          new_level = compute_level
          @record.seen_in_subjects_count = subject_count
          @record.last_seen_at = Time.current

          if @trigger == :transfer_detected
            @record.transfer_count = @record.transfer_count.to_i + 1
            new_level = [ new_level, 3 ].max
          end

          apply_monotonic_transition!(@record, new_level)
          @record.save!
        end

        emit_evolution_signal! if @record.level > prev_level
        ok(@record)
      end

      private

      def compute_level
        completions = completed_mission_count
        subjects    = subject_count
        visits      = visit_count

        return 3 if completions >= 2 && subjects >= 2
        return 2 if completions >= 1
        return 1 if visits >= 1

        0
      end

      def completed_mission_count
        completed_scope.count
      end

      def subject_count
        completed_scope.distinct.count("academy_missions.subject_id")
      end

      def completed_scope
        MissionProgress
          .joins(:mission)
          .where(academy_missions: { concept_id: @concept.id })
          .where(learner_id: @learner_id)
          .where(status: %i[completed mastered])
      end

      def visit_count
        LearnerLensVisit
          .where(learner_id: @learner_id, concept_id: @concept.id)
          .count
      end

      def apply_monotonic_transition!(record, new_level)
        return if new_level <= record.level

        prev = record.level
        record.level = new_level
        record.evolved_to_2_at ||= Time.current if prev < 2 && new_level >= 2
        record.evolved_to_3_at ||= Time.current if prev < 3 && new_level >= 3
      end

      def emit_evolution_signal!
        return unless @mission

        Signals::Record.call(
          learner_id: @learner_id,
          mission: @mission,
          event: :concept_evolved
        )
      end
    end
  end
end

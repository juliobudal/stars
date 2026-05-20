# frozen_string_literal: true

module Academy
  module Signals
    # Records a single signal event for a (learner, mission) pair into the
    # learner_signals table. Idempotency is not strictly enforced — each
    # call increments counters, so callers must guard against double-firing
    # on retries. We accept that risk because the signals are advisory, not
    # canonical.
    #
    # Events:
    #   :mission_completed   → affinity +5, completion_count +1, last_session_at touch
    #   :checkpoint_correct  → affinity +1, correct_checkpoints +1
    #   :checkpoint_wrong    → wrong_checkpoints +1 (no affinity bump)
    #   :concept_evolved     → affinity +2 (Pokedex level up — fired by Pokedex::Advance)
    #   :wager_settled       → affinity +3 (kid reported a PracticeWager — fired by Settle)
    #   :session_started     → last_session_at touch only
    class Record < ApplicationService
      VALID_EVENTS = %i[
        mission_completed checkpoint_correct checkpoint_wrong
        concept_evolved wager_settled
        session_started
      ].freeze

      def initialize(learner_id:, mission:, event:)
        @learner_id = learner_id
        @mission = mission
        @event = event.to_sym
      end

      def call
        return fail_with("Evento inválido: #{@event}") unless VALID_EVENTS.include?(@event)
        return fail_with("Missão sem area") unless @mission&.subject_id

        record = LearnerSignal.find_or_initialize_by(
          learner_id: @learner_id,
          subject_id: @mission.subject_id
        )
        record.assign_attributes(default_attrs) if record.new_record?

        apply_event!(record)
        record.last_session_at = Time.current
        record.save!
        ok(record)
      rescue ActiveRecord::RecordInvalid => e
        fail_with("Não foi possível registrar sinal: #{e.message}")
      end

      private

      def default_attrs
        { affinity_score: 0, completion_count: 0, correct_checkpoints: 0, wrong_checkpoints: 0 }
      end

      def apply_event!(record)
        case @event
        when :mission_completed
          record.affinity_score += 5
          record.completion_count += 1
        when :checkpoint_correct
          record.affinity_score += 1
          record.correct_checkpoints += 1
        when :checkpoint_wrong
          record.wrong_checkpoints += 1
        when :concept_evolved
          record.affinity_score += 2
        when :wager_settled
          record.affinity_score += 3
        when :session_started
          # only touches last_session_at
        end
      end
    end
  end
end

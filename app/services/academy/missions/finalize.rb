# frozen_string_literal: true

module Academy
  module Missions
    # Mission finalize chain (replaces v4 AdvanceTurn#finalize_mission!).
    # Fixed order:
    #
    #   1. mark progress completed
    #   2. Cards::MintAfterMission       — discovery card minted
    #   3. Pokedex::Advance              — concept level transition
    #   4. Signals::Record               — affinity update + event log
    #   5. Secrets::EvaluateForLearner   — segredos desbloqueáveis (last,
    #                                      reads the state left by 2-4)
    #
    # Idempotent at the service level via the receivers' own idempotency.
    class Finalize < ApplicationService
      def initialize(progress:)
        @progress = progress
      end

      def call
        return fail_with("Missão já finalizada.") if @progress.completed? || @progress.mastered?

        ApplicationRecord.transaction do
          @progress.update!(status: :completed, completed_at: Time.current)

          run_card_mint!
          run_pokedex_advance!
          run_signals_record!
          run_secrets_evaluate!
        end

        ok(@progress)
      end

      private

      def run_card_mint!
        ::Academy::Cards::MintAfterMission.call(progress: @progress)
      end

      def run_pokedex_advance!
        concept = @progress.mission&.concept
        return unless concept

        ::Academy::Pokedex::Advance.call(
          learner_id: @progress.learner_id,
          concept: concept,
          mission: @progress.mission,
          trigger: :mission_completed
        )
      end

      def run_signals_record!
        ::Academy::Signals::Record.call(
          learner_id: @progress.learner_id,
          mission: @progress.mission,
          event: :mission_completed
        )
      end

      def run_secrets_evaluate!
        return unless defined?(::Academy::Secrets::EvaluateForLearner)

        ::Academy::Secrets::EvaluateForLearner.call(learner_id: @progress.learner_id)
      end
    end
  end
end

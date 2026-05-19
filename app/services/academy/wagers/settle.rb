# frozen_string_literal: true

module Academy
  module Wagers
    # Records the learner's reported actual count for an open wager and
    # fires a :wager_settled signal. The Guide reads the delta on the
    # next mission's opening turn.
    class Settle < ApplicationService
      def initialize(wager:, actual_count:, note: nil)
        @wager = wager
        @actual_count = actual_count.to_i
        @note = note
      end

      def call
        return fail_with("Aposta já reportada") if @wager.reported?
        return fail_with("Quantidade inválida") if @actual_count.negative?

        @wager.update!(
          learner_actual_count: @actual_count,
          learner_note: @note.to_s.presence,
          reported_at: Time.current
        )

        Signals::Record.call(
          learner_id: @wager.learner_id,
          mission: @wager.mission,
          event: :wager_settled
        )

        ok(@wager)
      end
    end
  end
end

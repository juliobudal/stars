# frozen_string_literal: true

module Academy
  module Recall
    # Updates a review after the kid answers "lembrei | mais ou menos | esqueci".
    # SM-2 lite ladder — intervals tuned for kids (gentler than classic Anki).
    #
    # Outcomes:
    #   :got_it   — streak +1, advance interval
    #   :partial  — streak unchanged, half-step interval
    #   :forgot   — streak reset to 0, interval back to 1 day
    class Reschedule < ApplicationService
      INTERVALS = [ 1, 3, 7, 21, 60, 180 ].freeze # days
      VALID_OUTCOMES = %i[got_it partial forgot].freeze

      def initialize(review:, outcome:)
        @review = review
        @outcome = outcome.to_sym
      end

      def call
        return fail_with("Outcome inválido: #{@outcome}") unless VALID_OUTCOMES.include?(@outcome)

        case @outcome
        when :got_it
          new_streak = @review.streak + 1
          interval = INTERVALS[[ new_streak, INTERVALS.size - 1 ].min]
        when :partial
          new_streak = @review.streak
          # Half-step backwards on the ladder so the kid sees the card sooner,
          # without fully resetting.
          idx = INTERVALS.index(@review.interval_days) || 0
          interval = INTERVALS[[ idx - 1, 0 ].max]
        when :forgot
          new_streak = 0
          interval = INTERVALS.first
        end

        @review.update!(
          streak: new_streak,
          interval_days: interval,
          last_reviewed_at: Time.current,
          due_at: interval.days.from_now
        )

        ok(@review)
      rescue ActiveRecord::RecordInvalid => e
        fail_with("Não foi possível reagendar: #{e.message}")
      end
    end
  end
end

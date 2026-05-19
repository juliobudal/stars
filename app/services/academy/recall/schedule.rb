# frozen_string_literal: true

module Academy
  module Recall
    # Creates an initial RecallReview for a freshly minted DiscoveryCard.
    # Default first interval is 1 day. Idempotent — re-runs return the
    # existing review.
    class Schedule < ApplicationService
      INITIAL_INTERVAL_DAYS = 1

      def initialize(card:, learner_id: nil)
        @card = card
        @learner_id = learner_id || card.learner_id
      end

      def call
        review = RecallReview.find_or_initialize_by(learner_id: @learner_id, card_id: @card.id)
        if review.new_record?
          review.assign_attributes(
            streak: 0,
            interval_days: INITIAL_INTERVAL_DAYS,
            due_at: INITIAL_INTERVAL_DAYS.days.from_now
          )
          review.save!
        end
        ok(review)
      rescue ActiveRecord::RecordInvalid => e
        fail_with("Não foi possível agendar a revisão: #{e.message}")
      end
    end
  end
end

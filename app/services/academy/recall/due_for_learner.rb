# frozen_string_literal: true

module Academy
  module Recall
    # Returns up to `limit` RecallReviews that are due for the learner,
    # earliest first. Loads card + mission + subject so the UI can render
    # without N+1.
    class DueForLearner < ApplicationService
      DEFAULT_LIMIT = 3

      def initialize(learner_id:, limit: DEFAULT_LIMIT, at: Time.current)
        @learner_id = learner_id
        @limit = limit
        @at = at
      end

      def call
        reviews = RecallReview
                    .for_learner(@learner_id)
                    .due(at: @at)
                    .includes(card: { mission: :subject })
                    .limit(@limit)
                    .to_a
        ok(reviews)
      end
    end
  end
end

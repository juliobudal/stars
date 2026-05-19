# frozen_string_literal: true

module Academy
  module Rank
    # Computes the cross-area rank for a learner from their DiscoveryCards.
    # v4: honor-system ChallengeReport thresholds are gone; PracticeWager
    # honesty and TransferDetection feed the title_slug (Compass), not the
    # numeric rank kept here for the parent dashboard.
    #
    # Thresholds:
    #   aprendiz     (default)
    #   explorador   → 5 cards spanning ≥ 2 subjects
    #   estrategista → 30 cards + 3 subjects ≥30%
    #   criador      → 50 cards
    #   mentor       → 100 cards + 5 subjects ≥50%
    class Recompute < ApplicationService
      def initialize(learner_id:)
        @learner_id = learner_id
      end

      def call
        cards = DiscoveryCard.for_learner(@learner_id).includes(mission: :subject).to_a
        subject_counts = cards.group_by { |c| c.mission.subject_id }.transform_values(&:count)
        total_cards = cards.size

        subjects_with_some = subject_counts.size
        subjects_30 = count_subjects_above_ratio(cards, 0.3)
        subjects_50 = count_subjects_above_ratio(cards, 0.5)

        rank = compute_rank(
          total_cards: total_cards,
          subjects_with_some: subjects_with_some,
          subjects_30: subjects_30,
          subjects_50: subjects_50
        )

        record = LearnerRank.find_or_initialize_by(learner_id: @learner_id)
        record.rank = rank
        record.save!
        ok(record)
      end

      private

      def compute_rank(total_cards:, subjects_with_some:, subjects_30:, subjects_50:)
        return :mentor       if total_cards >= 100 && subjects_50 >= 5
        return :criador      if total_cards >= 50
        return :estrategista if total_cards >= 30 && subjects_30 >= 3
        return :explorador   if total_cards >= 5 && subjects_with_some >= 2

        :aprendiz
      end

      # Counts subjects where the learner has minted ≥ ratio of all active
      # missions in that subject.
      def count_subjects_above_ratio(cards, ratio)
        cards_by_subject = cards.group_by { |c| c.mission.subject_id }
        cards_by_subject.count do |subject_id, subject_cards|
          total = Mission.where(subject_id: subject_id, active: true).count
          next false if total.zero?

          subject_cards.size.to_f / total >= ratio
        end
      end
    end
  end
end

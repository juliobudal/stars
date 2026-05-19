# frozen_string_literal: true

module Academy
  module Secrets
    # Walks active Secrets and unlocks any whose rule is satisfied for the
    # learner. Idempotent — re-runs don't re-unlock.
    #
    # Rule kinds (v4 — challenge_ratio removed with honor-system wipe):
    #   cards_in_subject — rule: { subject_slug, threshold } — N cards minted
    #     for missions in that subject
    #   cards_total      — rule: { threshold } — total cards across all
    class EvaluateForLearner < ApplicationService
      def initialize(learner_id:)
        @learner_id = learner_id
      end

      def call
        newly_unlocked = []
        already_unlocked_ids = SecretUnlock.for_learner(@learner_id).pluck(:secret_id).to_set

        Secret.active.each do |secret|
          next if already_unlocked_ids.include?(secret.id)
          next unless rule_satisfied?(secret)

          unlock = SecretUnlock.create!(
            learner_id: @learner_id,
            secret_id: secret.id,
            unlocked_at: Time.current,
            seen: false
          )
          newly_unlocked << unlock
        end

        ok(newly_unlocked)
      end

      private

      def rule_satisfied?(secret)
        case secret.kind.to_sym
        when :cards_in_subject
          subject_slug = secret.rule["subject_slug"]
          threshold = secret.rule["threshold"].to_i
          subject = Subject.find_by(slug: subject_slug)
          return false unless subject && threshold.positive?

          DiscoveryCard
            .for_learner(@learner_id)
            .joins(:mission)
            .where(academy_missions: { subject_id: subject.id })
            .count >= threshold
        when :cards_total
          threshold = secret.rule["threshold"].to_i
          DiscoveryCard.for_learner(@learner_id).count >= threshold
        else
          false
        end
      end
    end
  end
end

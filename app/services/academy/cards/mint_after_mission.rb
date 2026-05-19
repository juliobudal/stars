# frozen_string_literal: true

module Academy
  module Cards
    # Mints a DiscoveryCard for the learner at the end of a mission.
    #
    # Inputs:
    #   progress: Academy::MissionProgress (status must be :completed or :mastered)
    #
    # Sources for the card content (priority order):
    #   1. The last guide message's metadata["card_summary"] (LLM-emitted v2)
    #   2. mission.central_insight + mission.learning_objective (seeded v2)
    #   3. mission.sacada / mission.hook / mission.title (legacy v1 fallback)
    #
    # Idempotent: unique on (learner_id, mission_id). Re-runs are no-ops.
    class MintAfterMission < ApplicationService
      def initialize(progress:)
        @progress = progress
      end

      def call
        return fail_with("Missão não finalizada.") unless finalized?

        card = DiscoveryCard.find_or_initialize_by(
          learner_id: @progress.learner_id,
          mission_id: @progress.mission_id
        )
        return ok(card) if card.persisted?

        payload = build_payload
        card.assign_attributes(payload.merge(minted_at: Time.current))
        card.save!

        # Phase 5 — schedule a recall review for the freshly minted card.
        Recall::Schedule.call(card: card)

        ok(card)
      rescue ActiveRecord::RecordInvalid => e
        fail_with("Não foi possível cunhar a carta: #{e.message}")
      end

      private

      def finalized?
        @progress.completed? || @progress.mastered?
      end

      def build_payload
        mission = @progress.mission
        summary = last_card_summary

        {
          illustration_key: summary&.dig("illustration_hint").presence ||
                            mission.illustration_key.presence ||
                            mission.subject.icon,
          headline: (summary&.dig("headline").presence ||
                     mission.central_insight.presence ||
                     mission.sacada.presence ||
                     mission.hook.presence ||
                     mission.title)[0, 180],
          application: summary&.dig("application").presence ||
                       mission.learning_objective.to_s.presence,
          central_insight: mission.central_insight.presence ||
                           mission.sacada.presence,
          source: mission.source_label
        }
      end

      def last_card_summary
        msg = @progress.sessions
                       .order(:session_index)
                       .last
                       &.messages
                       &.where(role: :guide)
                       &.order(:created_at, :id)
                       &.reverse_each
                       &.find { |m| m.metadata["card_summary"].present? }
        msg&.metadata&.dig("card_summary")
      end
    end
  end
end

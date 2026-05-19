# frozen_string_literal: true

module Academy
  module Connections
    # "Isso conecta com…" — for a given mission, find related missions that
    # share the same concept. v5 schema is 1:1 mission↔concept, so "related"
    # collapses to: other missions tagged with the same concept_id.
    #
    # Ranking still rewards cross-subject ("o magic" cross-área) and gives
    # a small bonus when the learner already collected the discovery card.
    class ForMission < ApplicationService
      Connection = Data.define(:mission, :shared_concepts, :score, :has_card, :same_subject) do
        def shared_count = shared_concepts.size
      end

      DEFAULT_LIMIT = 3

      def initialize(mission:, learner_id: nil, limit: DEFAULT_LIMIT)
        @mission = mission
        @learner_id = learner_id
        @limit = limit
      end

      def call
        concept_id = @mission.concept_id
        return ok([]) if concept_id.nil?

        related_missions = Mission
                             .where(concept_id: concept_id, active: true)
                             .where.not(id: @mission.id)
                             .includes(:subject, :concept)
                             .to_a

        return ok([]) if related_missions.empty?

        cards_by_mission =
          if @learner_id
            DiscoveryCard.where(learner_id: @learner_id, mission_id: related_missions.map(&:id))
                         .pluck(:mission_id).to_set
          else
            Set.new
          end

        scored = related_missions.map do |mission|
          same_subject = mission.subject_id == @mission.subject_id
          # Cross-subject is the magic: weight it heavier.
          base_score = 10
          cross_bonus = same_subject ? 0 : 15
          card_bonus = cards_by_mission.include?(mission.id) ? 3 : 0

          Connection.new(
            mission: mission,
            shared_concepts: [ mission.concept ].compact,
            score: base_score + cross_bonus + card_bonus,
            has_card: cards_by_mission.include?(mission.id),
            same_subject: same_subject
          )
        end

        ok(scored.sort_by { |c| -c.score }.first(@limit))
      end
    end
  end
end

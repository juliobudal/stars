# frozen_string_literal: true

module Academy
  module Medals
    # Called when a MissionProgress finalizes. Awards:
    #   - mission_completed medal (if defined for the mission)
    #   - mission_perfect medal (if defined and progress.perfect?)
    #   - tier medals (apprentice/adept/master) based on subject mastery ratio
    # All idempotent — unique index on (learner_id, medal_id).
    class AwardForMission < ::Academy::ApplicationService
      TIER_THRESHOLDS = { subject_apprentice: 0.30, subject_adept: 0.60, subject_master: 1.00 }.freeze

      def initialize(progress:)
        @progress = progress
        @learner_id = progress.learner_id
        @mission = progress.mission
        @subject = progress.mission.subject
      end

      def call
        awarded = []
        Medal.transaction do
          awarded << give(Medal.where(mission_id: @mission.id, kind: :mission_completed).first)
          awarded << give(Medal.where(mission_id: @mission.id, kind: :mission_perfect).first) if @progress.perfect?

          ratio = @subject.mastery_ratio_for(@learner_id)
          TIER_THRESHOLDS.each do |kind, threshold|
            next if ratio < threshold

            medal = Medal.find_by(subject_id: @subject.id, kind: kind)
            awarded << give(medal)
          end
        end
        ok(awarded.compact)
      end

      private

      def give(medal)
        return nil if medal.nil?

        MedalAward.find_or_create_by!(learner_id: @learner_id, medal_id: medal.id) do |a|
          a.awarded_at = Time.current
        end
        medal
      end
    end
  end
end

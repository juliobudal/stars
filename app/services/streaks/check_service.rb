module Streaks
  # Read-only celebration detector. Returns ok(override) where override is a
  # { tier:, payload: } hash describing how to upgrade an approval celebration
  # (a crossed star threshold or a streak milestone), or ok(nil) when nothing
  # was crossed. Best-effort: it never fails the surrounding approve flow, so a
  # detection error still resolves to ok(nil).
  class CheckService < ApplicationService
    THRESHOLDS = [ 50, 100, 250 ].freeze
    STREAK_MILESTONES = [ 3, 7, 14 ].freeze

    def initialize(profile, points_before:, points_after:)
      @profile = profile
      @points_before = points_before.to_i
      @points_after = points_after.to_i
    end

    def call
      streak = detect_streak
      return ok({ tier: :streak, payload: { days: streak } }) if streak

      threshold = detect_threshold
      return ok({ tier: :threshold, payload: { threshold: threshold } }) if threshold

      ok(nil)
    rescue StandardError => e
      Rails.logger.warn("[Streaks::CheckService] error profile_id=#{@profile&.id} error=#{e.message}")
      ok(nil)
    end

    private

    def detect_threshold
      crossed = THRESHOLDS.select { |t| @points_before < t && @points_after >= t }
      crossed.max
    end

    def detect_streak
      streak = @profile.streak_days(lookback_days: 14)
      STREAK_MILESTONES.include?(streak) ? streak : nil
    end
  end
end

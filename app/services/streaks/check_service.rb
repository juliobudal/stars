module Streaks
  class CheckService
    THRESHOLDS = [ 50, 100, 250 ].freeze
    STREAK_MILESTONES = [ 3, 7, 14 ].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(profile, points_before:, points_after:)
      @profile = profile
      @points_before = points_before.to_i
      @points_after = points_after.to_i
    end

    def call
      streak = detect_streak
      threshold = detect_threshold

      return { tier: :streak, payload: { days: streak } } if streak
      return { tier: :threshold, payload: { threshold: threshold } } if threshold

      nil
    rescue StandardError => e
      Rails.logger.warn("[Streaks::CheckService] error profile_id=#{@profile&.id} error=#{e.message}")
      nil
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

module Streaks
  class CheckService
    THRESHOLDS = [50, 100, 250].freeze
    STREAK_MILESTONES = [3, 7, 14].freeze

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
      logs = @profile.activity_logs
                     .where(log_type: :earn)
                     .where('created_at >= ?', 14.days.ago.beginning_of_day)
                     .order(created_at: :desc)

      days = logs.pluck(:created_at).map { |t| t.to_date }.uniq.sort.reverse
      return nil if days.empty?

      today = Date.current
      return nil if days.first != today

      streak = 1
      days.each_cons(2) do |a, b|
        if (a - b).to_i == 1
          streak += 1
        else
          break
        end
      end

      STREAK_MILESTONES.include?(streak) ? streak : nil
    end
  end
end

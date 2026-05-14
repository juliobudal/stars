module Rewards
  # Calcula metas coletivas semanais da família.
  # Janela = semana corrente baseada em family.week_start.
  # Earned = soma de ActivityLog#earn de TODOS profiles da família na janela.
  # Retorna lista de goals — uma por reward coletiva, com progresso e elegibilidade.
  class WeeklyFamilyGoalService < ApplicationService
    def initialize(family:, now: Time.current)
      @family = family
      @now = now
    end

    def call
      window = week_window
      earned = ActivityLog
                 .joins(:profile)
                 .where(profiles: { family_id: @family.id })
                 .where(log_type: :earn)
                 .where(created_at: window)
                 .sum(:points)

      collectives = @family.rewards.collective.order(:cost)

      goals = collectives.map do |reward|
        {
          reward: reward,
          eligible: earned >= reward.cost,
          progress_pct: reward.cost.positive? ? [ (earned.to_f / reward.cost * 100).round, 100 ].min : 0
        }
      end

      ok(earned: earned, goals: goals, window: window)
    end

    private

    def week_window
      wday_start = @family.week_start.to_i
      today = @now.in_time_zone(@family.timezone || "UTC").to_date
      offset = (today.wday - wday_start) % 7
      start_date = today - offset
      start_date.beginning_of_day..(start_date + 6.days).end_of_day
    end
  end
end

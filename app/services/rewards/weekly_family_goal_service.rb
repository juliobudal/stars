module Rewards
  # Calcula meta coletiva semanal da família.
  # Janela = semana corrente baseada em family.week_start.
  # Earned = soma de ActivityLog#earn de TODOS profiles da família na janela.
  # Target = primeira reward collective cujo cost > earned (próxima meta),
  #          ou maior reward collective já atingida (eligible: true).
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
      return ok(empty_payload(earned, window)) if collectives.empty?

      eligible = collectives.where("cost <= ?", earned).reorder(cost: :desc).first
      target = eligible || collectives.first

      progress_pct = target.cost.positive? ? [ (earned.to_f / target.cost * 100).round, 100 ].min : 0

      ok(
        {
          earned: earned,
          target: target,
          eligible: !eligible.nil?,
          eligible_reward: eligible,
          progress_pct: progress_pct,
          window: window
        }
      )
    end

    private

    def week_window
      wday_start = @family.week_start.to_i
      today = @now.in_time_zone(@family.timezone || "UTC").to_date
      offset = (today.wday - wday_start) % 7
      start_date = today - offset
      start_date.beginning_of_day..(start_date + 6.days).end_of_day
    end

    def empty_payload(earned, window)
      { earned: earned, target: nil, eligible: false, eligible_reward: nil, progress_pct: 0, window: window }
    end
  end
end

module Tasks
  # Lists weekly/monthly GlobalTasks for a given child profile that will fall
  # due within the next N days (default 7). Used by the kid dashboard to show
  # an "upcoming missions" widget so kids can plan ahead.
  #
  # Excluded: daily (already in today's queue), once (one-shot, not recurring),
  # inactive tasks, and tasks not assigned to this profile when explicit
  # assignments exist.
  class UpcomingService < ApplicationService
    DEFAULT_DAYS_AHEAD = 7
    MAX_ITEMS = 6

    def initialize(profile:, now: Time.current, days_ahead: DEFAULT_DAYS_AHEAD)
      @profile = profile
      @family = profile.family
      @days_ahead = days_ahead
      @today = now.in_time_zone(@family.timezone || "UTC").to_date
    end

    def call
      ok(upcoming_entries)
    end

    private

    def upcoming_entries
      candidates = candidate_tasks
      return [] if candidates.empty?

      entries = []
      (1..@days_ahead).each do |offset|
        date = @today + offset.days
        candidates.each do |gt|
          entries << { date: date, global_task: gt } if matches?(gt, date)
        end
      end
      entries.sort_by { |e| [ e[:date], e[:global_task].title.to_s ] }.first(MAX_ITEMS)
    end

    def candidate_tasks
      @family.global_tasks
             .where(active: true)
             .where(frequency: [ GlobalTask.frequencies[:weekly], GlobalTask.frequencies[:monthly] ])
             .includes(:assigned_profiles)
             .select { |gt| assigned_to_profile?(gt) }
    end

    def assigned_to_profile?(global_task)
      assigned = global_task.assigned_profiles
      assigned.empty? || assigned.include?(@profile)
    end

    def matches?(gt, date)
      if gt.weekly?
        gt.days_of_week.present? && gt.days_of_week.map(&:to_i).include?(date.wday)
      elsif gt.monthly?
        gt.day_of_month == date.day
      end
    end
  end
end

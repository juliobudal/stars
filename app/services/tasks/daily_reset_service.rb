module Tasks
  # Materializes today's ProfileTask slots for a family.
  #
  # Idempotent: short-circuits if `family.last_reset_on` already equals "today"
  # in the family's timezone (offset by `family.day_start_hour`). Safe to call
  # from cron (hourly) AND from dashboard loads as a lazy fallback — first hit
  # of the local day does the work, every subsequent call returns 0 cheaply.
  #
  # Also sweeps stale pending slots (assigned_date < today_local, still pending)
  # into the :missed status so they stop polluting today's queue.
  class DailyResetService
    def initialize(family:, now: Time.current, date: nil)
      raise ArgumentError, "family is required" unless family
      @family = family
      @today = date || compute_today(now)
    end

    def call
      if already_run_today?
        Rails.logger.debug("[Tasks::DailyResetService] skip family_id=#{@family.id} already_run_on=#{@family.last_reset_on}")
        return 0
      end

      Rails.logger.info("[Tasks::DailyResetService] start family_id=#{@family.id} date=#{@today}")

      missed_count = sweep_stale_pendings
      created_count = materialize_today

      @family.update_column(:last_reset_on, @today)

      Rails.logger.info("[Tasks::DailyResetService] success family_id=#{@family.id} created=#{created_count} missed=#{missed_count}")
      created_count
    end

    private

    # "Today" for this family is the date in its local timezone, with the
    # rollover anchored at `day_start_hour`. If start hour = 6, then at 05:30
    # local we are still in yesterday for task purposes.
    def compute_today(now)
      local = now.in_time_zone(@family.timezone || "UTC")
      start_hour = (@family.day_start_hour || 0).to_i
      local.hour < start_hour ? (local - 1.day).to_date : local.to_date
    end

    def already_run_today?
      @family.last_reset_on.present? && @family.last_reset_on >= @today
    end

    def sweep_stale_pendings
      ProfileTask
        .joins(:profile)
        .where(profiles: { family_id: @family.id })
        .where(profile_tasks: { status: ProfileTask.statuses[:pending] })
        .where("profile_tasks.assigned_date < ?", @today)
        .update_all(status: ProfileTask.statuses[:missed], updated_at: Time.current)
    end

    def materialize_today
      created = 0

      @family.global_tasks.includes(:assigned_profiles, family: :profiles).find_each do |global_task|
        next unless global_task.active?
        next unless applicable_today?(global_task)

        target_profiles = if global_task.assigned_profiles.any?
                            global_task.assigned_profiles.select(&:child?)
        else
                            global_task.family.profiles.select(&:child?)
        end

        target_profiles.each do |child|
          next if global_task.once? && once_already_done_for?(global_task, child)

          result = Tasks::SlotRefresher.new(profile: child, global_task: global_task, date: @today).call
          created += 1 if result.success? && result.data == :slot_created
        end
      end

      created
    end

    def applicable_today?(gt)
      return true if gt.daily?
      return gt.day_of_month == @today.day if gt.monthly?
      return true if gt.once? # per-profile check happens in the loop
      return false unless gt.weekly?
      return false if gt.days_of_week.blank?

      gt.days_of_week.map(&:to_i).include?(@today.wday)
    end

    def once_already_done_for?(global_task, profile)
      ProfileTask.where(global_task: global_task, profile: profile).exists?
    end
  end
end

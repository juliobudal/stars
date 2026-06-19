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
  class DailyResetService < ApplicationService
    def initialize(family:, now: Time.current, date: nil)
      raise ArgumentError, "family is required" unless family
      @family = family
      @today = date || compute_today(now)
    end

    def call
      if already_run_today?
        Rails.logger.debug("[Tasks::DailyResetService] skip family_id=#{@family.id} already_run_on=#{@family.last_reset_on}")
        return ok(created: 0, missed: 0, skipped: true)
      end

      Rails.logger.info("[Tasks::DailyResetService] start family_id=#{@family.id} date=#{@today}")

      created_count = 0
      missed_count = 0

      ran = ActiveRecord::Base.transaction do
        @family.lock!

        next false if already_run_today?

        missed_count = sweep_stale_pendings
        created_count = materialize_today

        @family.update_column(:last_reset_on, @today)
        true
      end

      return ok(created: 0, missed: 0, skipped: true) unless ran

      Rails.logger.info("[Tasks::DailyResetService] success family_id=#{@family.id} created=#{created_count} missed=#{missed_count}")
      ok(created: created_count, missed: missed_count, skipped: false)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Tasks::DailyResetService] exception family_id=#{@family.id} error=#{e.message}")
      fail_with(e.message)
    end

    private

    def compute_today(now)
      @family.current_date(now)
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
          result = global_task.materialize_slot_for(child, @today)
          created += 1 if result&.success? && result.data == :slot_created
        end
      end

      created
    end

    def applicable_today?(gt)
      gt.applicable_on?(@today)
    end
  end
end

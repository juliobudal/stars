# frozen_string_literal: true

module Tasks
  class SlotRefresher < ApplicationService
    def initialize(profile:, global_task:, date: nil)
      @profile = profile
      @global_task = global_task
      @date = date || default_date
    end

    def call
      return ok(:not_applicable) if @global_task.nil?

      ActiveRecord::Base.transaction do
        # Lock the rows for this profile/task/period to prevent concurrent slot races.
        # PostgreSQL disallows FOR UPDATE with aggregate functions, so we lock first
        # by loading IDs, then scope subsequent queries to those IDs.
        locked_ids = ProfileTask
          .where(profile: @profile, global_task: @global_task)
          .in_period_for(@global_task, @date)
          .lock
          .pluck(:id)

        period_pts = ProfileTask.where(id: locked_ids)

        consumed = period_pts.consuming_slot.count
        max = @global_task.max_completions_per_period.to_i

        if consumed >= max
          period_pts.pending.destroy_all
          return ok(:cap_reached)
        end

        unless period_pts.pending.exists?
          ProfileTask.create!(
            profile: @profile,
            global_task: @global_task,
            assigned_date: @date,
            status: :pending
          )
        end

        ok(:slot_available)
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Tasks::SlotRefresher] error profile_id=#{@profile.id} global_task_id=#{@global_task&.id} error=#{e.message}")
      fail_with(e.message)
    end

    private

    def default_date
      Time.current.in_time_zone(@profile.family.timezone).to_date
    end
  end
end

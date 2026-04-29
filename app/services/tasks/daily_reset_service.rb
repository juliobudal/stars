module Tasks
  class DailyResetService
    def initialize(date: nil, family: nil)
      @family = family
      @date = date || (family ? Time.current.in_time_zone(family.timezone).to_date : Date.current)
      @wday = @date.wday
    end

    def call
      Rails.logger.info("[Tasks::DailyResetService] start date=#{@date} family_id=#{@family&.id || 'all'}")

      tasks_scope =
        if @family
          @family.global_tasks.includes(:assigned_profiles, family: :profiles)
        else
          GlobalTask.includes(:assigned_profiles, family: :profiles)
        end

      created_count = 0

      tasks_scope.find_each do |global_task|
        next unless global_task.active?
        next unless applicable_today?(global_task)

        target_profiles = if global_task.assigned_profiles.any?
                            global_task.assigned_profiles.select(&:child?)
        else
                            global_task.family.profiles.select(&:child?)
        end

        target_profiles.each do |child|
          result = Tasks::SlotRefresher.new(profile: child, global_task: global_task, date: @date).call
          created_count += 1 if result.success? && result.data == :slot_created
        end
      end

      Rails.logger.info("[Tasks::DailyResetService] success created=#{created_count} family_id=#{@family&.id || 'all'}")
      created_count
    end

    private

    def applicable_today?(gt)
      return true if gt.daily?
      return gt.day_of_month == @date.day if gt.monthly?
      return !ProfileTask.where(global_task: gt).exists? if gt.once?
      return false unless gt.weekly?
      return false if gt.days_of_week.blank?

      # days_of_week is a PG string array (see schema). Parse once to integers.
      gt.days_of_week.map(&:to_i).include?(@wday)
    end
  end
end

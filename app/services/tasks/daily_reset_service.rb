module Tasks
  class DailyResetService
    def initialize(date: Date.current, family: nil)
      @date = date
      @family = family
      @wday = @date.wday
    end

    def call
      Rails.logger.info("[Tasks::DailyResetService] start date=#{@date} family_id=#{@family&.id || 'all'}")

      tasks_scope =
        if @family
          @family.global_tasks.includes(family: :profiles)
        else
          GlobalTask.includes(family: :profiles)
        end

      created_count = 0

      tasks_scope.find_each do |global_task|
        next unless applicable_today?(global_task)

        global_task.family.profiles.select(&:child?).each do |child|
          pt = ProfileTask.find_or_create_by!(
            profile: child,
            global_task: global_task,
            assigned_date: @date
          )
          created_count += 1 if pt.previously_new_record?
        end
      end

      Rails.logger.info("[Tasks::DailyResetService] success created=#{created_count}")
      created_count
    end

    private

    def applicable_today?(gt)
      return true if gt.daily?
      return false unless gt.weekly?
      return false if gt.days_of_week.blank?

      # days_of_week is a PG string array (see schema). Parse once to integers.
      gt.days_of_week.map(&:to_i).include?(@wday)
    end
  end
end

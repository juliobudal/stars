module Tasks
  class DailyResetService
    def initialize(date: Date.current, family: nil)
      @date = date
      @family = family
      @wday = @date.wday
    end

    def call
      # Iterate over global tasks, optionally scoped by family
      tasks_scope = @family ? @family.global_tasks : GlobalTask.all
      
      tasks_scope.find_each do |global_task|
        next unless applicable_today?(global_task)

        # Iterate over children in the family (of the task)
        global_task.family.profiles.child.find_each do |child|
          ProfileTask.find_or_create_by!(
            profile: child,
            global_task: global_task,
            assigned_date: @date
          )
        end
      end
    end

    private

    def applicable_today?(gt)
      return true if gt.daily?
      
      # Weekly tasks check if today's wday is in the list of days_of_week
      # NOTE: ensure days_of_week is an array of integers (0-6)
      gt.weekly? && gt.days_of_week.present? && gt.days_of_week.to_a.map(&:to_i).include?(@wday)
    end
  end
end

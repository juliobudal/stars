module Tasks
  class ApproveService
    def initialize(profile_task)
      @profile_task = profile_task
      @profile = profile_task.profile
    end

    def call
      return false unless @profile_task.awaiting_approval?

      ActiveRecord::Base.transaction do
        @profile_task.update!(status: :approved, completed_at: Time.current)
        @profile.increment!(:points, @profile_task.points)
        
        @profile.activity_logs.create!(
          log_type: :task_completed,
          title: "Missão Concluída: #{@profile_task.title}",
          points: @profile_task.points
        )
      end
      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      false
    end
  end
end

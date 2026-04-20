module Tasks
  class RejectService
    def initialize(profile_task)
      @profile_task = profile_task
    end

    def call
      return false unless @profile_task.awaiting_approval?

      @profile_task.update(status: :pending)
    end
  end
end

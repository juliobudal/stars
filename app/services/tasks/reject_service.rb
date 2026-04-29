module Tasks
  class RejectService < ApplicationService
    def initialize(profile_task)
      @profile_task = profile_task
    end

    def call
      Rails.logger.info("[Tasks::RejectService] start profile_task_id=#{@profile_task.id}")

      unless @profile_task.awaiting_approval?
        Rails.logger.info("[Tasks::RejectService] failure not awaiting_approval id=#{@profile_task.id}")
        return fail_with("Tarefa não está aguardando aprovação")
      end

      ActiveRecord::Base.transaction do
        @profile_task.update!(status: :rejected)

        if @profile_task.global_task.present?
          Tasks::SlotRefresher.new(
            profile: @profile_task.profile,
            global_task: @profile_task.global_task,
            date: @profile_task.assigned_date
          ).call
        end
      end

      Rails.logger.info("[Tasks::RejectService] success id=#{@profile_task.id}")
      ok(@profile_task)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Tasks::RejectService] exception id=#{@profile_task.id} error=#{e.message}")
      fail_with(e.message)
    end
  end
end

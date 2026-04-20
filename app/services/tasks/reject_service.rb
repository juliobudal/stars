require "ostruct"

module Tasks
  class RejectService
    def initialize(profile_task)
      @profile_task = profile_task
    end

    def call
      Rails.logger.info("[Tasks::RejectService] start profile_task_id=#{@profile_task.id}")

      unless @profile_task.awaiting_approval?
        Rails.logger.info("[Tasks::RejectService] failure not awaiting_approval id=#{@profile_task.id}")
        return OpenStruct.new(success?: false, error: "Tarefa não está aguardando aprovação")
      end

      @profile_task.update!(status: :rejected)
      Rails.logger.info("[Tasks::RejectService] success id=#{@profile_task.id}")
      OpenStruct.new(success?: true, error: nil)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Tasks::RejectService] exception id=#{@profile_task.id} error=#{e.message}")
      OpenStruct.new(success?: false, error: e.message)
    end
  end
end

require "ostruct"

module Tasks
  class ApproveService
    def initialize(profile_task)
      @profile_task = profile_task
      @profile = profile_task.profile
    end

    def call
      Rails.logger.info("[Tasks::ApproveService] start profile_task_id=#{@profile_task.id}")

      unless @profile_task.awaiting_approval?
        Rails.logger.info("[Tasks::ApproveService] failure not awaiting_approval id=#{@profile_task.id}")
        return OpenStruct.new(success?: false, error: "Tarefa não está aguardando aprovação")
      end

      ActiveRecord::Base.transaction do
        @profile_task.update!(status: :approved, completed_at: Time.current)
        @profile.increment!(:points, @profile_task.points)

        @profile.activity_logs.create!(
          log_type: :earn,
          title: "Missão Concluída: #{@profile_task.title}",
          points: @profile_task.points
        )
      end

      Rails.logger.info("[Tasks::ApproveService] success id=#{@profile_task.id}")
      OpenStruct.new(success?: true, error: nil)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Tasks::ApproveService] exception id=#{@profile_task.id} error=#{e.message}")
      OpenStruct.new(success?: false, error: e.message)
    end
  end
end

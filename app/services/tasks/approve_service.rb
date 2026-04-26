module Tasks
  class ApproveService < ApplicationService
    def initialize(profile_task)
      @profile_task = profile_task
      @profile = profile_task.profile
    end

    def call
      Rails.logger.info("[Tasks::ApproveService] start profile_task_id=#{@profile_task.id}")

      unless @profile_task.awaiting_approval?
        Rails.logger.info("[Tasks::ApproveService] failure not awaiting_approval id=#{@profile_task.id}")
        return fail_with("Tarefa não está aguardando aprovação")
      end

      points_before = @profile.points
      points_after = nil

      ActiveRecord::Base.transaction do
        @profile_task.update!(status: :approved, completed_at: Time.current)
        @profile.increment!(:points, @profile_task.points)

        ActivityLog.create!(
          profile: @profile,
          log_type: :earn,
          title: "Missão Concluída: #{@profile_task.title}",
          points: @profile_task.points
        )
      end

      points_after = @profile.reload.points
      broadcast_celebration(points_before: points_before, points_after: points_after)

      Rails.logger.info("[Tasks::ApproveService] success id=#{@profile_task.id}")
      ok(@profile_task)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Tasks::ApproveService] exception id=#{@profile_task.id} error=#{e.message}")
      fail_with(e.message)
    end

    private

    def broadcast_celebration(points_before:, points_after:)
      tier = Ui::Celebration.tier_for(:approved)
      payload = { points: @profile_task.points, message: "Tarefa aprovada!" }

      override = Streaks::CheckService.call(@profile, points_before: points_before, points_after: points_after)
      if override
        tier = override[:tier]
        payload = payload.merge(override[:payload])
      end

      Turbo::StreamsChannel.broadcast_append_to(
        "kid_#{@profile.id}",
        target: "fx_stage",
        partial: "kid/shared/celebration",
        locals: { tier: tier, payload: payload }
      )
    rescue StandardError => e
      Rails.logger.warn("[Tasks::ApproveService] broadcast failed id=#{@profile_task.id} error=#{e.message}")
    end
  end
end

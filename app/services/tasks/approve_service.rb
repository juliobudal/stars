module Tasks
  class ApproveService < ApplicationService
    POINTS_RANGE = (1..1000).freeze

    def initialize(profile_task, points_override: nil)
      @profile_task = profile_task
      @profile = profile_task.profile
      @points_override = points_override
    end

    def call
      Rails.logger.info("[Tasks::ApproveService] start profile_task_id=#{@profile_task.id}")

      unless @profile_task.awaiting_approval?
        Rails.logger.info("[Tasks::ApproveService] failure not awaiting_approval id=#{@profile_task.id}")
        return fail_with("Tarefa não está aguardando aprovação")
      end

      if @points_override.present?
        unless @profile_task.custom?
          return fail_with("Apenas missões customizadas aceitam ajuste de pontos")
        end
        unless POINTS_RANGE.cover?(@points_override.to_i)
          return fail_with("Pontos inválidos")
        end
      end

      points_before = @profile.points
      race_lost = false

      committed = ActiveRecord::Base.transaction do
        @profile_task.lock!

        unless @profile_task.awaiting_approval?
          Rails.logger.info("[Tasks::ApproveService] race lost id=#{@profile_task.id} status=#{@profile_task.status}")
          race_lost = true
          next nil
        end

        if @points_override.present?
          @profile_task.update!(custom_points: @points_override.to_i)
        end
        @profile_task.update!(status: :approved, completed_at: Time.current)
        @profile.increment!(:points, @profile_task.points)

        ActivityLog.create!(
          profile: @profile,
          log_type: :earn,
          title: activity_log_title,
          points: @profile_task.points
        )

        if @profile_task.global_task.present?
          Tasks::SlotRefresher.new(
            profile: @profile,
            global_task: @profile_task.global_task,
            date: @profile_task.assigned_date
          ).call
        end

        true
      end

      if race_lost
        return fail_with("Tarefa já foi processada")
      end

      unless committed
        Rails.logger.warn("[Tasks::ApproveService] rollback id=#{@profile_task.id}")
        return fail_with("Transação interrompida")
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

    def activity_log_title
      base = "Missão Concluída: #{@profile_task.title}"
      parts = [ base ]
      parts << "[Sugerida pela criança]" if @profile_task.custom?
      parts << "💬 #{@profile_task.submission_comment}" if @profile_task.submission_comment.present?
      parts.join(" ")
    end

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

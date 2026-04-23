# frozen_string_literal: true

module Tasks
  class CompleteService < ApplicationService
    def initialize(profile_task:, proof_photo: nil)
      @profile_task = profile_task
      @proof_photo  = proof_photo
      @family       = profile_task.profile.family
    end

    def call
      Rails.logger.info("[Tasks::CompleteService] start profile_task_id=#{@profile_task.id}")

      unless @profile_task.pending?
        Rails.logger.info("[Tasks::CompleteService] failure not pending id=#{@profile_task.id}")
        return fail_with("Tarefa não está pendente")
      end

      if @family.require_photo? && @proof_photo.blank? && !@profile_task.proof_photo.attached?
        Rails.logger.info("[Tasks::CompleteService] failure photo required id=#{@profile_task.id}")
        return fail_with("Esta família exige uma foto como comprovante para concluir a missão")
      end

      ActiveRecord::Base.transaction do
        @profile_task.proof_photo.attach(@proof_photo) if @proof_photo.present?
        @profile_task.update!(status: :awaiting_approval)
        # Status must be :awaiting_approval before ApproveService runs —
        # ApproveService guards on awaiting_approval? so the flip above must
        # happen first. Both run inside the same transaction (Rails re-entrant).
        #
        # Auto-approve fires when:
        #   - auto_approve_threshold is set (nil = feature disabled)
        #   - task points <= threshold (threshold: 0 approves every free task)
        #   - family does NOT require_photo (photos always need human review)
        if @family.auto_approve_threshold.present? &&
           @profile_task.global_task.points <= @family.auto_approve_threshold &&
           !@family.require_photo?
          Tasks::ApproveService.new(@profile_task).call
          @profile_task.reload
        end
      end

      Rails.logger.info("[Tasks::CompleteService] success id=#{@profile_task.id}")
      ok(@profile_task)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Tasks::CompleteService] exception id=#{@profile_task.id} error=#{e.message}")
      fail_with(e.message)
    end
  end
end

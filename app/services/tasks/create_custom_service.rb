# frozen_string_literal: true

module Tasks
  class CreateCustomService < ApplicationService
    PERMITTED_KEYS = %i[custom_title custom_description custom_points custom_category_id submission_comment proof_photo].freeze

    def initialize(profile:, params:)
      @profile = profile
      @params  = params.to_h.symbolize_keys.slice(*PERMITTED_KEYS)
    end

    def call
      Rails.logger.info("[Tasks::CreateCustomService] start profile_id=#{@profile.id}")

      proof_photo = @params.delete(:proof_photo)

      profile_task = @profile.profile_tasks.build(
        @params.merge(
          source: :custom,
          status: :awaiting_approval,
          assigned_date: Date.current,
          completed_at: Time.current
        )
      )

      profile_task.proof_photo.attach(proof_photo) if proof_photo.present?

      if profile_task.save
        Rails.logger.info("[Tasks::CreateCustomService] success id=#{profile_task.id}")
        ok(profile_task)
      else
        Rails.logger.info("[Tasks::CreateCustomService] failure errors=#{profile_task.errors.full_messages}")
        fail_with(profile_task.errors.full_messages.to_sentence)
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Rails.logger.error("[Tasks::CreateCustomService] exception error=#{e.message}")
      fail_with(e.message)
    end
  end
end

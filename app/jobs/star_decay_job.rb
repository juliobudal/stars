class StarDecayJob < ApplicationJob
  queue_as :default

  def perform
    Family.where(decay_enabled: true).find_each do |family|
      profile_ids = family.profiles.pluck(:id)

      ActivityLog
        .where(log_type: :earn, decayed_at: nil, profile_id: profile_ids)
        .where("created_at < ?", 30.days.ago)
        .find_each do |earn_log|
          decay_earn_log(earn_log)
        end
    end
  end

  private

  def decay_earn_log(earn_log)
    ActiveRecord::Base.transaction do
      # Idempotence: re-check inside transaction with lock
      earn_log.lock!
      return if earn_log.decayed_at.present?

      earn_log.update!(decayed_at: Time.current)

      profile = earn_log.profile
      profile.with_lock do
        new_balance = profile.points - earn_log.points
        new_balance = 0 unless profile.family.allow_negative? || new_balance >= 0
        profile.update!(points: new_balance)
      end

      ActivityLog.create!(
        profile: earn_log.profile,
        log_type: :decay,
        points: -earn_log.points,
        title: "Expirou: #{earn_log.title}"
      )
    end
  rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordNotFound => e
    Rails.logger.warn("[StarDecayJob] Skipping earn_log id=#{earn_log.id}: #{e.message}")
  end
end

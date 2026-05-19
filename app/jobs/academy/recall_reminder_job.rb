# frozen_string_literal: true

module Academy
  # Recurring scaffolding for "you have N recall cards due" reminders.
  # Runs daily, scans `academy_recall_reviews` for cards past `due_at`,
  # groups by learner, and emits a structured log line per learner with
  # pending count.
  #
  # The actual delivery channel (web-push, email, in-app banner) is
  # deliberately out of scope: web-push requires VAPID keys, a service
  # worker, a permission flow, and subscription persistence — those are
  # tracked separately. By logging here we already get the visibility
  # the parent dashboard needs and a hook future delivery code can wrap
  # without changing the scan logic.
  class RecallReminderJob < ApplicationJob
    queue_as :default

    def perform
      counts = ::Academy::RecallReview
                 .where("due_at <= ?", Time.current)
                 .group(:learner_id)
                 .count

      counts.each do |learner_id, count|
        Rails.logger.info(
          "[Academy::RecallReminderJob] learner_id=#{learner_id} pending_recalls=#{count}"
        )
      end

      counts
    end
  end
end

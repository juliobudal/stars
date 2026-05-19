# frozen_string_literal: true

module Academy
  module Lens
    # Reactive quality gate. When learners consistently get a lens's
    # micro_check wrong, we treat the lens itself as suspect and flag the
    # backing LensCache row so future learners get a freshly generated
    # variant. The threshold is intentionally low — false positives are
    # cheap (we just regenerate) but a confusing lens compounds harm.
    #
    # Called from `LearnerLensVisit.after_update_commit` when a visit closes
    # with `micro_check_correct: false`.
    class FlagLowQuality < ApplicationService
      WINDOW           = 7.days
      WRONG_THRESHOLD  = 3

      def initialize(visit:)
        @visit = visit
      end

      def call
        return ok(false) unless @visit.lens_cache_id
        return ok(false) unless concerning_signal?

        wrong_count = ::Academy::LensSignal
                        .joins("INNER JOIN academy_learner_lens_visits v ON v.id = academy_lens_signals.lens_visit_id")
                        .where(signal_type: "micro_check_wrong")
                        .where("v.lens_cache_id = ?", @visit.lens_cache_id)
                        .where(recorded_at: WINDOW.ago..)
                        .count

        return ok(false) if wrong_count < WRONG_THRESHOLD

        ::Academy::LensCache.where(id: @visit.lens_cache_id, quality_flagged: false)
                            .update_all(quality_flagged: true, updated_at: Time.current)
        Rails.logger.warn(
          "[Academy::Lens::FlagLowQuality] flagged lens_cache_id=#{@visit.lens_cache_id} " \
          "after #{wrong_count} wrong signals in #{WINDOW.inspect}"
        )
        ok(true)
      end

      private

      def concerning_signal?
        payload = @visit.signal_payload || {}
        raw = payload["micro_check_correct"]
        return false if raw.nil? || raw.to_s.empty?

        ActiveModel::Type::Boolean.new.cast(raw) == false
      end
    end
  end
end

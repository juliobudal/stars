# frozen_string_literal: true

module Academy
  module Lens
    # On lens visit close, writes the canonical signals to `academy_lens_signals`
    # so the adaptive ordering service (ChooseNext) can read them.
    #
    # Always emits at least one signal (`time_on_lens`). Optionally emits
    # `micro_check_correct|micro_check_wrong`, `abandoned`, `self_report_*`
    # based on the visit's `signal_payload`.
    class ScoreVisit < ApplicationService
      ABANDONMENT_THRESHOLD = 5.minutes

      def initialize(visit:)
        @visit = visit
      end

      def call
        return fail_with(:visit_still_open) unless @visit.closed?

        ApplicationRecord.transaction do
          record_signal!(:time_on_lens, numeric_value: time_on_lens_seconds)

          payload = @visit.signal_payload || {}

          record_micro_check!(payload)
          record_abandonment!(payload)
          record_self_report!(payload)
        end

        ok(@visit)
      end

      private

      # The JS layer sends string "true"/"false" via the hidden field
      # (lens_stage_controller.js); naive truthiness would treat "false" as
      # truthy and score every wrong answer as correct.
      def record_micro_check!(payload)
        raw = payload["micro_check_correct"]
        return if raw.nil? || raw.to_s.empty?

        correct = ActiveModel::Type::Boolean.new.cast(raw)
        type = correct ? "micro_check_correct" : "micro_check_wrong"
        record_signal!(type, numeric_value: 1)
      end

      def record_abandonment!(payload)
        return unless payload["outcome"].to_s == "abandoned" || @visit.outcome == "abandoned"

        record_signal!(:abandoned, numeric_value: 1)
      end

      def record_self_report!(payload)
        tap = payload["affective_tap"]
        return unless tap.present?

        if tap.to_s == "easy"
          record_signal!(:self_report_easy, numeric_value: 1)
        elsif tap.to_s == "hard"
          record_signal!(:self_report_hard, numeric_value: 1)
        end
      end

      def record_signal!(signal_type, numeric_value:)
        LensSignal.create!(
          mission_progress_id: @visit.mission_progress_id,
          lens_visit_id: @visit.id,
          learner_id: @visit.learner_id,
          concept_id: @visit.concept_id,
          lens_type: @visit.lens_type,
          signal_type: signal_type.to_s,
          numeric_value: numeric_value,
          recorded_at: Time.current
        )
      end

      def time_on_lens_seconds
        return 0 unless @visit.opened_at && @visit.closed_at

        (@visit.closed_at - @visit.opened_at).to_f
      end
    end
  end
end

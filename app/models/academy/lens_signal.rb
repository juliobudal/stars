# frozen_string_literal: true

module Academy
  # Append-only signal stream consumed by Lens::ChooseNext (adaptive ordering).
  # One signal per closed visit at minimum; many signals possible per visit
  # == Schema Information
  #
  # Table name: academy_lens_signals
  #
  #  id                                                                                                                                    :bigint           not null, primary key
  #  lens_type                                                                                                                             :string           not null
  #  numeric_value(Seconds, scores, etc; nullable)                                                                                         :decimal(12, 4)
  #  recorded_at                                                                                                                           :datetime         not null
  #  signal_type(time_on_lens | micro_check_correct | micro_check_wrong | abandoned | self_report_easy | self_report_hard | transfer_hint) :string           not null
  #  created_at                                                                                                                            :datetime         not null
  #  updated_at                                                                                                                            :datetime         not null
  #  concept_id                                                                                                                            :bigint           not null
  #  learner_id                                                                                                                            :bigint           not null
  #  lens_visit_id                                                                                                                         :bigint
  #  mission_progress_id                                                                                                                   :bigint           not null
  #
  # Indexes
  #
  #  idx_academy_lens_signals_learner_concept_lens_time  (learner_id,concept_id,lens_type,recorded_at)
  #  idx_academy_lens_signals_learner_type_time          (learner_id,signal_type,recorded_at)
  #  idx_academy_lens_signals_progress_time              (mission_progress_id,recorded_at)
  #
  # Foreign Keys
  #
  #  fk_rails_...  (lens_visit_id => academy_learner_lens_visits.id)
  #  fk_rails_...  (mission_progress_id => academy_mission_progresses.id)
  #
  # (e.g. micro_check_correct + time_on_lens).
  class LensSignal < ApplicationRecord
    self.table_name = "academy_lens_signals"

    belongs_to :mission_progress, class_name: "Academy::MissionProgress"
    belongs_to :lens_visit, class_name: "Academy::LearnerLensVisit", optional: true

    SIGNAL_TYPES = %w[
      time_on_lens
      micro_check_correct
      micro_check_wrong
      abandoned
      self_report_easy
      self_report_hard
      transfer_hint
      curated_gap_hit
    ].freeze

    validates :learner_id, :concept_id, :lens_type, :signal_type, :recorded_at, presence: true
    validates :signal_type, inclusion: { in: SIGNAL_TYPES }

    scope :for_learner, ->(id) { where(learner_id: id) }
    scope :recent_for_attempt, ->(progress_id) {
      where(mission_progress_id: progress_id).order(:recorded_at)
    }
  end
end

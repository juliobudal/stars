# frozen_string_literal: true

module Academy
  # Per-attempt visit ledger. One row per lens served to a learner inside
  # == Schema Information
  #
  # Table name: academy_learner_lens_visits
  #
  #  id                                                            :bigint           not null, primary key
  #  chooser_version(Which version of ChooseNext picked this lens) :string
  #  closed_at                                                     :datetime
  #  legacy                                                        :boolean          default(FALSE), not null
  #  lens_type                                                     :string           not null
  #  opened_at                                                     :datetime         not null
  #  ordering_position(1-based position within mission attempt)    :integer          not null
  #  outcome(completed | abandoned | skipped_by_system)            :string
  #  signal_payload                                                :jsonb            not null
  #  created_at                                                    :datetime         not null
  #  updated_at                                                    :datetime         not null
  #  concept_id                                                    :bigint           not null
  #  learner_id                                                    :bigint           not null
  #  lens_cache_id                                                 :bigint
  #  mission_progress_id                                           :bigint           not null
  #
  # Indexes
  #
  #  idx_academy_lens_visits_learner_concept_lens  (learner_id,concept_id,lens_type)
  #  idx_academy_lens_visits_learner_opened        (learner_id,opened_at)
  #  idx_academy_lens_visits_position              (mission_progress_id,ordering_position) UNIQUE
  #
  # Foreign Keys
  #
  #  fk_rails_...  (concept_id => academy_concepts.id)
  #  fk_rails_...  (lens_cache_id => academy_lens_cache.id)
  #  fk_rails_...  (mission_progress_id => academy_mission_progresses.id)
  #
  # a mission attempt. See `lens-mission` REQ-LMSN-006.
  class LearnerLensVisit < ApplicationRecord
    self.table_name = "academy_learner_lens_visits"

    belongs_to :mission_progress, class_name: "Academy::MissionProgress"
    belongs_to :concept, class_name: "Academy::Concept"
    belongs_to :lens_cache, class_name: "Academy::LensCache", optional: true

    OUTCOMES = %w[completed abandoned skipped_by_system].freeze

    validates :lens_type, :ordering_position, :opened_at, presence: true
    validates :outcome, inclusion: { in: OUTCOMES }, allow_nil: true
    validates :ordering_position, uniqueness: { scope: :mission_progress_id }

    scope :for_learner, ->(id) { where(learner_id: id) }
    scope :open_visits, -> { where(closed_at: nil) }
    scope :closed_visits, -> { where.not(closed_at: nil) }
    scope :completed, -> { where(outcome: "completed") }

    def closed? = closed_at.present?
    def completed? = outcome == "completed"
  end
end

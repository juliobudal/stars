# frozen_string_literal: true

module Academy
  # Per-(learner, subject) affinity counter consumed by Compass::Propose.
# == Schema Information
#
# Table name: academy_learner_signals
#
#  id                                                                                              :bigint           not null, primary key
#  affinity_score(Cumulative weighted signal: completions + correct checkpoints + done challenges) :integer          default(0), not null
#  completion_count                                                                                :integer          default(0), not null
#  correct_checkpoints                                                                             :integer          default(0), not null
#  last_session_at                                                                                 :datetime
#  wrong_checkpoints                                                                               :integer          default(0), not null
#  created_at                                                                                      :datetime         not null
#  updated_at                                                                                      :datetime         not null
#  learner_id                                                                                      :bigint           not null
#  subject_id                                                                                      :bigint           not null
#
# Indexes
#
#  idx_academy_signals_learner_subject          (learner_id,subject_id) UNIQUE
#  index_academy_learner_signals_on_subject_id  (subject_id)
#
# Foreign Keys
#
#  fk_rails_...  (subject_id => academy_subjects.id)
#
  # Updated by Signals::Record after every mission turn / completion.
  class LearnerSignal < ApplicationRecord
    self.table_name = "academy_learner_signals"

    belongs_to :subject, class_name: "Academy::Subject"

    validates :learner_id, presence: true
    validates :learner_id, uniqueness: { scope: :subject_id }

    scope :for_learner, ->(learner_id) { where(learner_id: learner_id) }
  end
end

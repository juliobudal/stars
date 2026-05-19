# frozen_string_literal: true

# == Schema Information
#
# Table name: academy_mission_progresses
#
#  id                                                                                                               :bigint           not null, primary key
#  completed_at                                                                                                     :datetime
#  correct_checkpoints                                                                                              :integer          default(0), not null
#  current_session_index                                                                                            :integer          default(0), not null
#  skills_awarded_at(Set the first time Skills::Award(:completed) runs for this progress; further calls are no-ops) :datetime
#  started_at                                                                                                       :datetime
#  status                                                                                                           :integer          default("not_started"), not null
#  total_checkpoints                                                                                                :integer          default(0), not null
#  created_at                                                                                                       :datetime         not null
#  updated_at                                                                                                       :datetime         not null
#  learner_id                                                                                                       :bigint           not null
#  mission_id                                                                                                       :bigint           not null
#
# Indexes
#
#  idx_academy_progress_learner_mission            (learner_id,mission_id) UNIQUE
#  idx_academy_progress_learner_status             (learner_id,status)
#  index_academy_mission_progresses_on_mission_id  (mission_id)
#
# Foreign Keys
#
#  fk_rails_...  (mission_id => academy_missions.id)
#
module Academy
  class MissionProgress < ApplicationRecord
    self.table_name = "academy_mission_progresses"

    belongs_to :mission, class_name: "Academy::Mission"
    has_many :sessions, -> { order(:session_index) },
             class_name: "Academy::Session",
             foreign_key: :mission_progress_id,
             dependent: :destroy,
             inverse_of: :mission_progress

    enum :status, { not_started: 0, in_progress: 1, completed: 2, mastered: 3 }, default: :not_started

    validates :learner_id, presence: true, uniqueness: { scope: :mission_id }

    def current_session
      sessions.find_by(session_index: current_session_index)
    end

    def accuracy
      return 0.0 if total_checkpoints.zero?

      correct_checkpoints.to_f / total_checkpoints
    end

    # "Perfect" if every checkpoint was answered correctly.
    def perfect? = total_checkpoints.positive? && correct_checkpoints == total_checkpoints
  end
end

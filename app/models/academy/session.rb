# frozen_string_literal: true

# == Schema Information
#
# Table name: academy_sessions
#
#  id                  :bigint           not null, primary key
#  checkpoint_result   :jsonb            not null
#  completed_at        :datetime
#  session_index       :integer          not null
#  started_at          :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  mission_progress_id :bigint           not null
#
# Indexes
#
#  idx_academy_sessions_progress    (mission_progress_id)
#  idx_academy_sessions_unique_idx  (mission_progress_id,session_index) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (mission_progress_id => academy_mission_progresses.id)
#
module Academy
  class Session < ApplicationRecord
    self.table_name = "academy_sessions"

    belongs_to :mission_progress, class_name: "Academy::MissionProgress", inverse_of: :sessions
    has_many :messages, -> { order(:created_at, :id) },
             class_name: "Academy::Message",
             foreign_key: :session_id,
             dependent: :destroy,
             inverse_of: :session

    validates :session_index, presence: true,
              uniqueness: { scope: :mission_progress_id }

    delegate :mission, to: :mission_progress

    def completed? = completed_at.present?
  end
end

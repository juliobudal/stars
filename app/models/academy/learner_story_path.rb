# frozen_string_literal: true

module Academy
  # Per-(learner, story_choice mission) trajectory of scene/choice decisions.
  # Used to resume mid-mission and to compute anonymized choice distributions
# == Schema Information
#
# Table name: academy_learner_story_paths
#
#  id                                                        :bigint           not null, primary key
#  completed_at                                              :datetime
#  scene_sequence(Ordered: [{scene_id, choice_label, at}])   :jsonb            not null
#  created_at                                                :datetime         not null
#  updated_at                                                :datetime         not null
#  learner_id(Learner value-object id (no FK))               :bigint           not null
#  mission_id                                                :bigint           not null
#  terminal_scene_id(Final scene reached, when mission ends) :string
#
# Indexes
#
#  idx_academy_learner_story_paths_learner_mission  (learner_id,mission_id)
#  idx_academy_learner_story_paths_terminal         (terminal_scene_id)
#  index_academy_learner_story_paths_on_mission_id  (mission_id)
#
# Foreign Keys
#
#  fk_rails_...  (mission_id => academy_missions.id)
#
  # at the closing scene.
  class LearnerStoryPath < ApplicationRecord
    self.table_name = "academy_learner_story_paths"

    belongs_to :mission, class_name: "Academy::Mission"

    validates :learner_id, presence: true

    scope :for_learner, ->(id) { where(learner_id: id) }
    scope :completed,   -> { where.not(completed_at: nil) }

    def completed? = completed_at.present?

    def choice_at(scene_id)
      Array(scene_sequence).find { |step| step["scene_id"].to_s == scene_id.to_s }
    end

    def push_choice!(scene_id:, choice_label:)
      self.scene_sequence = Array(scene_sequence) + [
        { "scene_id" => scene_id.to_s, "choice_label" => choice_label, "at" => Time.current.iso8601 }
      ]
    end
  end
end

class DropSkillsAwardedAtFromAcademyMissionProgresses < ActiveRecord::Migration[8.1]
  def change
    remove_column :academy_mission_progresses, :skills_awarded_at, :datetime
  end
end

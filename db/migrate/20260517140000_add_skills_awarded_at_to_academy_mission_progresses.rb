# frozen_string_literal: true

# Idempotency guard for Skills::Award on mission completion events.
# Today, AdvanceTurn refuses to re-finalize a completed mission, so
# Skills::Award(:completed) is implicitly once-per-mission. This column
# is the explicit version of that contract — Skills::Award checks &
# sets it so a future refactor (e.g. allowing mission retries) can't
# accidentally double the radar.
class AddSkillsAwardedAtToAcademyMissionProgresses < ActiveRecord::Migration[8.1]
  def change
    add_column :academy_mission_progresses, :skills_awarded_at, :datetime,
               comment: "Set the first time Skills::Award(:completed) runs for this progress; further calls are no-ops"
  end
end

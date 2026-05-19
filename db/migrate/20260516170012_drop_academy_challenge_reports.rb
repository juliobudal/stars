# frozen_string_literal: true

# Academy v4 — Drops the honor-system challenge_reports table.
# Replaced by academy_practice_wagers (numeric wagers, no fake/done dichotomy).
class DropAcademyChallengeReports < ActiveRecord::Migration[8.1]
  def up
    drop_table :academy_challenge_reports
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Academy v4 removed challenge_reports; restore via academy_practice_wagers."
  end
end

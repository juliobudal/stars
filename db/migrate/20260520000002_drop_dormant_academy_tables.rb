# frozen_string_literal: true

# Drops 9 Academy tables that supported features which never reached the
# kid or parent UI in production. Evidence from dev DB:
#
#   - academy_learner_skills (score > 0):  0 rows
#   - academy_practice_wagers:             0 rows (kept — UI block live)
#   - academy_virtue_sightings:            0 rows (write-never)
#   - academy_learner_ranks:               0 rows
#   - academy_parent_digests:              0 rows (weekly job ran, nothing read it)
#   - academy_recall_reviews:              ~1 seed row, kid never saw recall UI
#   - academy_medal_awards:                0 rows (89 catalogued medals, 0 awards)
#
# Companion code (services, jobs, cron entries, models, factories, specs,
# seeders, view blocks) deleted in the same change.
#
# Irreversible — the dropped data had no business value.
class DropDormantAcademyTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :academy_medal_awards if table_exists?(:academy_medal_awards)
    drop_table :academy_medals if table_exists?(:academy_medals)
    drop_table :academy_aula_skills if table_exists?(:academy_aula_skills)
    drop_table :academy_learner_skills if table_exists?(:academy_learner_skills)
    drop_table :academy_skills if table_exists?(:academy_skills)
    drop_table :academy_learner_ranks if table_exists?(:academy_learner_ranks)
    drop_table :academy_parent_digests if table_exists?(:academy_parent_digests)
    drop_table :academy_virtue_sightings if table_exists?(:academy_virtue_sightings)
    drop_table :academy_recall_reviews if table_exists?(:academy_recall_reviews)

    if column_exists?(:academy_mission_progresses, :skills_awarded_at)
      remove_column :academy_mission_progresses, :skills_awarded_at
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Dropped Academy tables had zero rows of real data — reversal would only " \
          "recreate empty shells. Restore from git history if a feature gets revived."
  end
end

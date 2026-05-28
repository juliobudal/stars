# frozen_string_literal: true

# Academy redesign (spec 001): the v2/v4 module (25 tables — pokédex, concept
# graph, lenses, signals, secrets, wagers, lightning, missions/subjects) is
# replaced by a minimal trail → lesson → progress model. No production users,
# so historical Academy data is discarded rather than migrated.
#
# Drops every academy_* table (CASCADE removes dependent FKs/indexes). The new
# schema is created fresh in the following migration.
class DropLegacyAcademyTables < ActiveRecord::Migration[8.1]
  LEGACY_TABLES = %w[
    academy_concept_edges
    academy_discovery_cards
    academy_guide_messages
    academy_guide_conversations
    academy_learner_concepts
    academy_learner_lens_visits
    academy_learner_signals
    academy_learner_story_paths
    academy_lens_signals
    academy_lens_cache
    academy_lightning_round_runs
    academy_messages
    academy_pill_views
    academy_practice_wagers
    academy_secret_unlocks
    academy_sessions
    academy_mission_progresses
    academy_missions
    academy_secrets
    academy_trails
    academy_subjects
    academy_concepts
  ].freeze

  def up
    LEGACY_TABLES.each do |table|
      execute("DROP TABLE IF EXISTS #{quote_table_name(table)} CASCADE")
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Legacy Academy schema was discarded; restore from a pre-redesign backup if needed."
  end
end

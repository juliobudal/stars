# frozen_string_literal: true

class BackfillMissionConceptId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # SQL-only — independent of the Academy::AulaConcept model, which has
    # already been deleted by the v5 dead-code wipe. The aula_concepts
    # table still exists at this point (drop happens in a later migration).
    return unless ActiveRecord::Base.connection.table_exists?("academy_aula_concepts")

    sql = <<~SQL
      UPDATE academy_missions m
      SET concept_id = ac.concept_id
      FROM (
        SELECT DISTINCT ON (mission_id) mission_id, concept_id
        FROM   academy_aula_concepts
        ORDER  BY mission_id,
                  is_primary DESC NULLS LAST,
                  created_at ASC,
                  id ASC
      ) ac
      WHERE m.id = ac.mission_id
        AND m.concept_id IS NULL
    SQL

    updated = ActiveRecord::Base.connection.execute(sql).cmd_tuples
    say "Backfilled concept_id from aula_concepts for #{updated} mission(s).", true

    # Pass 2: missions that never had an aula_concept (v4 stories, late seeds).
    # Fallback: borrow any concept already in use within the same subject
    # (lowest-id wins). The semantic 1:1 mapping is curator's responsibility
    # post-v5 — this just keeps the schema invariant satisfiable.
    fallback_sql = <<~SQL
      UPDATE academy_missions m
      SET concept_id = peers.concept_id
      FROM (
        SELECT subject_id, MIN(concept_id) AS concept_id
        FROM   academy_missions
        WHERE  concept_id IS NOT NULL
        GROUP  BY subject_id
      ) peers
      WHERE m.subject_id = peers.subject_id
        AND m.concept_id IS NULL
    SQL

    fallback_updated = ActiveRecord::Base.connection.execute(fallback_sql).cmd_tuples
    say "Backfilled concept_id via subject fallback for #{fallback_updated} mission(s).", true if fallback_updated.positive?

    missing_count = ActiveRecord::Base.connection.select_value(
      "SELECT COUNT(*) FROM academy_missions WHERE concept_id IS NULL"
    ).to_i

    if missing_count.positive?
      missing_ids = ActiveRecord::Base.connection.select_values(
        "SELECT id FROM academy_missions WHERE concept_id IS NULL ORDER BY id"
      )
      say "WARN: #{missing_count} missions still without concept_id (ids: #{missing_ids.inspect})", true
      raise StandardError,
            "#{missing_count} missions cannot be backfilled — seed concepts for their subjects, then retry."
    end
  end

  def down
    ActiveRecord::Base.connection.execute(
      "UPDATE academy_missions SET concept_id = NULL"
    )
  end
end

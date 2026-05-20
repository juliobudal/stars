# frozen_string_literal: true

# Removes the cross-area transfer detector (LLM judge) — pipeline retired.
# Drops `academy_transfer_detections` and the `transfer_count` counter on
# `academy_learner_concepts`. Pokédex L3 is now reachable only through
# completed missions across multiple subjects.
class DropAcademyTransferDetection < ActiveRecord::Migration[8.1]
  def up
    drop_table :academy_transfer_detections if table_exists?(:academy_transfer_detections)

    if column_exists?(:academy_learner_concepts, :transfer_count)
      remove_column :academy_learner_concepts, :transfer_count
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

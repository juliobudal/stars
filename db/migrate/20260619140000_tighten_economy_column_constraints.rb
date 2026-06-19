# frozen_string_literal: true

# Closes integrity gaps on the star-economy tables: the ledger
# (activity_logs) and the redeem record (redemptions) are the system of
# record, yet their enum/value columns were nullable with no DB default — a
# bug or raw SQL could persist an untyped/valueless ledger row or a
# status-less redemption that escapes the enum scopes.
#
# The 4th `change_column_null` argument backfills any pre-existing NULLs so
# the migration is safe on populated production data (dev has none). The
# backfill values only touch already-corrupt rows.
class TightenEconomyColumnConstraints < ActiveRecord::Migration[8.1]
  def up
    # redemptions.status — the model already defaults to :pending; mirror it at
    # the DB level so the column can never be NULL (outside pending/approved/rejected).
    change_column_default :redemptions, :status, from: nil, to: 0
    change_column_null :redemptions, :status, false, 0

    # activity_logs — append-only points ledger. Both the type and the value
    # must always be present for balance reconstruction / reconciliation.
    change_column_null :activity_logs, :log_type, false, 2 # 2 = :adjust (neutral)
    change_column_null :activity_logs, :points, false, 0
  end

  def down
    change_column_null :activity_logs, :points, true
    change_column_null :activity_logs, :log_type, true
    change_column_null :redemptions, :status, true
    change_column_default :redemptions, :status, from: 0, to: nil
  end
end

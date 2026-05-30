# frozen_string_literal: true

# Thin scheduler around Ledger::ReconcileService (mirrors how DailyResetJob
# wraps Tasks::DailyResetService). Runs the star-economy integrity check and,
# if any profile's cached points diverge from its signed ActivityLog ledger,
# reports through the Rails.error API (→ Observability::ErrorSubscriber, plus
# any external tracker wired in config/initializers/error_reporting.rb).
class LedgerReconciliationJob < ApplicationJob
  queue_as :default

  class LedgerDiscrepancy < StandardError; end

  def perform
    discrepancies = Ledger::ReconcileService.call.data
    return if discrepancies.empty?

    Rails.error.report(
      LedgerDiscrepancy.new("#{discrepancies.size} profile(s) com saldo divergente do ledger"),
      handled: true,
      source: "ledger_reconciliation",
      context: { discrepancies: discrepancies }
    )
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe LedgerReconciliationJob, type: :job do
  it "does not report when the ledger is consistent" do
    profile = create(:profile, points: 30)
    create(:activity_log, profile: profile, log_type: :earn, points: 50)
    create(:activity_log, profile: profile, log_type: :redeem, points: -20)

    expect(Rails.error).not_to receive(:report)

    described_class.perform_now
  end

  it "reports a discrepancy through Rails.error when points drift from the ledger" do
    profile = create(:profile, points: 999)
    create(:activity_log, profile: profile, log_type: :earn, points: 10)

    reported = nil
    allow(Rails.error).to receive(:report) { |error, **kwargs| reported = { error: error, kwargs: kwargs } }

    described_class.perform_now

    expect(reported[:error]).to be_a(LedgerReconciliationJob::LedgerDiscrepancy)
    expect(reported[:kwargs][:source]).to eq("ledger_reconciliation")
    expect(reported[:kwargs][:context][:discrepancies].first).to include(profile_id: profile.id, diff: 989)
  end
end

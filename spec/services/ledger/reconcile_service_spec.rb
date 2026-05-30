# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ledger::ReconcileService do
  it "returns no discrepancies when points match the signed ledger" do
    profile = create(:profile, points: 30)
    create(:activity_log, profile: profile, log_type: :earn, points: 50)
    create(:activity_log, profile: profile, log_type: :redeem, points: -20)

    result = described_class.call

    expect(result).to be_success
    expect(result.data).to eq([])
  end

  it "lists each profile whose points drift from the ledger" do
    profile = create(:profile, points: 999)
    create(:activity_log, profile: profile, log_type: :earn, points: 10)

    result = described_class.call

    expect(result.data).to contain_exactly(
      hash_including(profile_id: profile.id, points: 999, ledger: 10, diff: 989)
    )
  end

  it "treats an empty ledger as zero and flags a non-zero balance" do
    profile = create(:profile, points: 5) # no activity logs → ledger sum is 0

    result = described_class.call

    expect(result.data).to contain_exactly(
      hash_including(profile_id: profile.id, points: 5, ledger: 0, diff: 5)
    )
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ledger::DecayService do
  let(:family) { create(:family, decay_enabled: true) }
  let(:child)  { create(:profile, family: family, points: 0) }

  def earn(points, created_at)
    create(:activity_log, profile: child, log_type: :earn, points: points, created_at: created_at)
  end

  it "is a no-op when the family has decay disabled" do
    family.update!(decay_enabled: false)
    earn(50, 40.days.ago)
    child.update!(points: 50)

    expect { described_class.call(family: family) }.not_to(change { child.reload.points })
  end

  it "expires unused stars earned more than 30 days ago" do
    earn(50, 40.days.ago)
    child.update!(points: 50)

    result = described_class.call(family: family)

    expect(result).to be_success
    expect(result.data[:decayed]).to eq(50)
    expect(child.reload.points).to eq(0)
    expect(child.activity_logs.where(log_type: :decay).sum(:points)).to eq(-50)
  end

  it "leaves recent earns untouched" do
    earn(50, 5.days.ago)
    child.update!(points: 50)

    expect { described_class.call(family: family) }.not_to(change { child.reload.points })
  end

  it "caps the deduction at the current balance (never goes negative)" do
    earn(100, 40.days.ago)
    child.update!(points: 20) # 80 already spent

    described_class.call(family: family)

    expect(child.reload.points).to eq(0)
  end

  it "is idempotent — a second run does not decay the same earns again" do
    earn(50, 40.days.ago)
    child.update!(points: 50)

    described_class.call(family: family)

    expect { described_class.call(family: family) }.not_to(change { child.reload.points })
  end

  it "preserves the ledger invariant (points == sum of logs)" do
    earn(80, 40.days.ago)
    earn(20, 5.days.ago)
    child.update!(points: 100)

    described_class.call(family: family)

    expect(child.reload.points).to eq(child.activity_logs.sum(:points))
  end
end

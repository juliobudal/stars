require "rails_helper"

RSpec.describe Rewards::RejectRedemptionService do
  let(:family) { create(:family) }
  let(:child)  { create(:profile, :child, family: family, points: 70) }
  let(:reward) { create(:reward, family: family, cost: 30, title: "Sorvete") }
  let(:redemption) { Redemption.create!(profile: child, reward: reward, points: 30, status: :pending) }

  describe "#call" do
    context "when redemption is pending" do
      it "marks the redemption as rejected" do
        described_class.call(redemption)
        expect(redemption.reload).to be_rejected
      end

      it "refunds the points to the child" do
        expect {
          described_class.call(redemption)
        }.to change { child.reload.points }.by(30)
      end

      it "creates a refund activity_log" do
        expect {
          described_class.call(redemption)
        }.to change { ActivityLog.count }.by(1)

        log = ActivityLog.last
        expect(log.profile).to eq(child)
        expect(log.log_type).to eq("adjust")
        expect(log.points).to eq(30)
        expect(log.title).to include("Sorvete")
      end

      it "returns success" do
        result = described_class.call(redemption)
        expect(result.success?).to be true
      end
    end

    context "when redemption is already rejected" do
      before { redemption.update!(status: :rejected) }

      it "fails fast and does not double-refund" do
        expect {
          described_class.call(redemption)
        }.not_to change { child.reload.points }
      end
    end

    context "when redemption is approved" do
      before { redemption.update!(status: :approved) }

      it "refuses to reject" do
        result = described_class.call(redemption)
        expect(result.success?).to be false
      end
    end

    context "transaction rollback" do
      it "does not refund points if ActivityLog creation fails" do
        allow(ActivityLog).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(ActivityLog.new))

        expect {
          described_class.call(redemption)
        }.not_to change { child.reload.points }

        expect(redemption.reload).to be_pending
      end
    end
  end
end

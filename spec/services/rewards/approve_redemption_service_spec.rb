require "rails_helper"

RSpec.describe Rewards::ApproveRedemptionService do
  let(:family) { create(:family) }
  let(:child)  { create(:profile, :child, family: family, points: 100) }
  let(:reward) { create(:reward, family: family, cost: 30) }
  let(:redemption) { Redemption.create!(profile: child, reward: reward, points: 30, status: :pending) }

  describe "#call" do
    context "when redemption is pending" do
      it "marks the redemption as approved" do
        result = described_class.call(redemption)
        expect(result.success?).to be true
        expect(redemption.reload).to be_approved
      end

      it "does not refund the child" do
        expect {
          described_class.call(redemption)
        }.not_to change { child.reload.points }
      end
    end

    context "when redemption is already approved" do
      before { redemption.update!(status: :approved) }

      it "returns failure without changing status" do
        result = described_class.call(redemption)
        expect(result.success?).to be false
        expect(result.error).to match(/não está pendente/i)
      end
    end

    context "when redemption is rejected" do
      before { redemption.update!(status: :rejected) }

      it "refuses to approve" do
        result = described_class.call(redemption)
        expect(result.success?).to be false
      end
    end
  end
end

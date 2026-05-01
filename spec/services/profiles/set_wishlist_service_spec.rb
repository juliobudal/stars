require "rails_helper"

RSpec.describe Profiles::SetWishlistService do
  let(:family) { create(:family) }
  let(:other_family) { create(:family) }
  let(:child) { create(:profile, :child, family: family, points: 30) }
  let(:reward) { create(:reward, family: family, cost: 100) }
  let(:foreign_reward) { create(:reward, family: other_family, cost: 100) }

  describe "#call" do
    context "pinning a same-family reward" do
      it "returns a successful Result" do
        result = described_class.call(profile: child, reward: reward)
        expect(result.success?).to be true
        expect(result.data).to eq({ profile: child, reward: reward })
        expect(result.error).to be_nil
      end

      it "persists the association" do
        described_class.call(profile: child, reward: reward)
        expect(child.reload.wishlist_reward).to eq(reward)
      end

      it "broadcasts a Turbo Stream replace via the Profile model callback" do
        expect {
          described_class.call(profile: child, reward: reward)
        }.to have_broadcasted_to("kid_#{child.id}")
      end
    end

    context "pinning a cross-family reward" do
      it "returns a failed Result with pt-BR error" do
        result = described_class.call(profile: child, reward: foreign_reward)
        expect(result.success?).to be false
        expect(result.error).to match(/família/i)
      end

      it "does not persist the wishlist" do
        described_class.call(profile: child, reward: foreign_reward)
        expect(child.reload.wishlist_reward).to be_nil
      end

      it "does not broadcast" do
        expect {
          described_class.call(profile: child, reward: foreign_reward)
        }.not_to have_broadcasted_to("kid_#{child.id}")
      end
    end

    context "clearing (reward: nil)" do
      before { child.update!(wishlist_reward: reward) }

      it "returns a successful Result and clears the association" do
        result = described_class.call(profile: child, reward: nil)
        expect(result.success?).to be true
        expect(child.reload.wishlist_reward).to be_nil
      end

      it "broadcasts the change via the model callback" do
        expect {
          described_class.call(profile: child, reward: nil)
        }.to have_broadcasted_to("kid_#{child.id}")
      end
    end

    context "replacing the existing pin (single-goal-per-kid invariant)" do
      let(:other_reward) { create(:reward, family: family) }
      before { child.update!(wishlist_reward: reward) }

      it "replaces the previous wishlist when called with a different reward" do
        described_class.call(profile: child, reward: other_reward)
        expect(child.reload.wishlist_reward).to eq(other_reward)
      end
    end
  end
end

# == Schema Information
#
# Table name: redemptions
#
#  id         :bigint           not null, primary key
#  points     :integer
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  profile_id :bigint           not null
#  reward_id  :bigint           not null
#
# Indexes
#
#  index_redemptions_on_profile_id  (profile_id)
#  index_redemptions_on_reward_id   (reward_id)
#
# Foreign Keys
#
#  fk_rails_...  (profile_id => profiles.id)
#  fk_rails_...  (reward_id => rewards.id)
#
require "rails_helper"

RSpec.describe Redemption, type: :model do
  let(:family) { create(:family) }
  let(:parent) { create(:profile, :parent, family: family) }
  let(:child) { create(:profile, :child, family: family) }
  let(:reward) { create(:reward, family: family, cost: 50) }

  describe "associations" do
    it { is_expected.to belong_to(:profile) }
    it { is_expected.to belong_to(:reward) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:points) }
  end

  describe "enums" do
    it "defines pending, approved, rejected statuses" do
      expect(described_class.statuses).to eq("pending" => 0, "approved" => 1, "rejected" => 2)
    end

    it "defaults to pending on a new instance" do
      redemption = Redemption.new(profile: child, reward: reward, points: 50)
      expect(redemption.status).to eq("pending")
    end
  end

  describe ".awaiting_approval scope" do
    let!(:pending_redemption)  { create(:redemption, profile: child, reward: reward, points: 50, status: :pending) }
    let!(:approved_redemption) { create(:redemption, profile: child, reward: reward, points: 50, status: :approved) }
    let!(:rejected_redemption) { create(:redemption, profile: child, reward: reward, points: 50, status: :rejected) }

    it "returns only pending redemptions" do
      expect(Redemption.awaiting_approval).to contain_exactly(pending_redemption)
    end
  end

  describe "factory" do
    it "creates a valid redemption" do
      redemption = build(:redemption, profile: child, reward: reward, points: 50)
      expect(redemption).to be_valid
    end
  end
end

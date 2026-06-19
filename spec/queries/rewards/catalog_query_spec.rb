# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rewards::CatalogQuery do
  let(:family)  { create(:family) }
  let(:profile) { create(:profile, family: family, points: 50) }

  it "splits the family's rewards into affordable vs locked by balance" do
    cheap  = create(:reward, family: family, cost: 30)
    exact  = create(:reward, family: family, cost: 50)
    pricey = create(:reward, family: family, cost: 80)

    result = described_class.new(profile).call

    expect(result.affordable).to contain_exactly(cheap, exact)
    expect(result.locked).to contain_exactly(pricey)
    expect(result.balance).to eq(50)
  end

  it "scopes rewards to the profile's family" do
    mine  = create(:reward, family: family, cost: 10)
    other = create(:reward, family: create(:family), cost: 10)

    result = described_class.new(profile).call

    expect(result.rewards).to include(mine)
    expect(result.rewards).not_to include(other)
  end

  it "returns the profile's redemptions newest-first" do
    reward = create(:reward, family: family, cost: 10)
    older  = create(:redemption, profile: profile, reward: reward, created_at: 2.days.ago)
    newer  = create(:redemption, profile: profile, reward: reward, created_at: 1.hour.ago)

    result = described_class.new(profile).call

    expect(result.redeemed.to_a).to eq([ newer, older ])
  end
end

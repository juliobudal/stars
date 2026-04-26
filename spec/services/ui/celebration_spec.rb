require 'rails_helper'

RSpec.describe Ui::Celebration do
  describe '.tier_for' do
    it 'returns :big for :approved' do
      expect(described_class.tier_for(:approved)).to eq(:big)
    end

    it 'returns :big for :redeemed' do
      expect(described_class.tier_for(:redeemed)).to eq(:big)
    end

    it 'returns :big for :streak' do
      expect(described_class.tier_for(:streak)).to eq(:big)
    end

    it 'returns :big for :threshold' do
      expect(described_class.tier_for(:threshold)).to eq(:big)
    end

    it 'returns :big for :all_cleared' do
      expect(described_class.tier_for(:all_cleared)).to eq(:big)
    end

    it 'returns :small for :done_tapped' do
      expect(described_class.tier_for(:done_tapped)).to eq(:small)
    end

    it 'returns :small for :reset' do
      expect(described_class.tier_for(:reset)).to eq(:small)
    end

    it 'returns :small for :reward_unlocked' do
      expect(described_class.tier_for(:reward_unlocked)).to eq(:small)
    end

    it 'returns :none for an unknown event' do
      expect(described_class.tier_for(:something_else)).to eq(:none)
    end

    it 'accepts an arbitrary context hash without raising' do
      expect { described_class.tier_for(:approved, profile: nil, points: 5) }.not_to raise_error
    end
  end
end

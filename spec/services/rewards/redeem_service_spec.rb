require 'rails_helper'

RSpec.describe Rewards::RedeemService do
  let(:family) { create(:family) }
  let(:child) { create(:profile, :child, family: family, points: 100) }
  let(:reward) { create(:reward, family: family, cost: 70) }

  describe '#call' do
    context 'when child has enough points' do
      it 'deducts points from the child' do
        expect {
          described_class.new(profile: child, reward: reward).call
        }.to change { child.reload.points }.by(-70)
      end

      it 'creates an activity log' do
        expect {
          described_class.new(profile: child, reward: reward).call
        }.to change(child.activity_logs, :count).by(1)
        
        log = child.activity_logs.last
        expect(log.log_type).to eq('reward_redeemed')
        expect(log.points).to eq(-70)
      end

      it 'returns true' do
        expect(described_class.new(profile: child, reward: reward).call).to be true
      end
    end

    context 'when child has insufficient points' do
      let(:child) { create(:profile, :child, family: family, points: 50) }

      it 'does not deduct points' do
        expect {
          described_class.new(profile: child, reward: reward).call
        }.not_to change { child.reload.points }
      end

      it 'returns false' do
        expect(described_class.new(profile: child, reward: reward).call).to be false
      end
      
      it 'does not create an activity log' do
        expect {
          described_class.new(profile: child, reward: reward).call
        }.not_to change(ActivityLog, :count)
      end
    end
  end
end

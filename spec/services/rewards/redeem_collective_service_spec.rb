require 'rails_helper'

RSpec.describe Rewards::RedeemCollectiveService do
  let(:family) { create(:family) }
  let(:parent_profile) { create(:profile, :parent, family: family) }
  let(:kid) { create(:profile, :child, family: family) }
  let(:reward) { create(:reward, family: family, cost: 100, collective: true) }

  describe '#call' do
    context 'when goal reached' do
      before { create(:activity_log, profile: kid, log_type: :earn, points: 150) }

      it 'creates a collective redemption without debiting kid points' do
        kid_points_before = kid.points

        expect {
          described_class.call(family: family, reward: reward, requested_by: parent_profile)
        }.to change(Redemption, :count).by(1)

        expect(kid.reload.points).to eq(kid_points_before)
        red = Redemption.last
        expect(red.collective).to be true
        expect(red.profile).to eq(parent_profile)
      end

      it 'logs audit on parent activity' do
        expect {
          described_class.call(family: family, reward: reward, requested_by: parent_profile)
        }.to change(parent_profile.activity_logs, :count).by(1)
      end
    end

    context 'when goal not reached' do
      it 'fails' do
        result = described_class.call(family: family, reward: reward, requested_by: parent_profile)
        expect(result.success?).to be false
        expect(result.error).to match(/não atingida/)
      end
    end

    context 'when reward is not collective' do
      let(:reward) { create(:reward, family: family, cost: 100, collective: false) }

      it 'fails' do
        result = described_class.call(family: family, reward: reward, requested_by: parent_profile)
        expect(result.success?).to be false
      end
    end

    context 'when requested by kid' do
      before { create(:activity_log, profile: kid, log_type: :earn, points: 150) }

      it 'fails' do
        result = described_class.call(family: family, reward: reward, requested_by: kid)
        expect(result.success?).to be false
        expect(result.error).to match(/pais/)
      end
    end
  end
end

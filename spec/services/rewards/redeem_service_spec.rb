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
        expect(log.log_type).to eq('redeem')
        expect(log.points).to eq(-70)
      end

      it 'returns success' do
        result = described_class.new(profile: child, reward: reward).call
        expect(result.success?).to be true
      end
    end

    context 'when child has insufficient points' do
      let(:child) { create(:profile, :child, family: family, points: 50) }

      it 'does not deduct points' do
        expect {
          described_class.new(profile: child, reward: reward).call
        }.not_to change { child.reload.points }
      end

      it 'returns failure with error' do
        result = described_class.new(profile: child, reward: reward).call
        expect(result.success?).to be false
        expect(result.error).to match(/saldo insuficiente/i)
      end

      it 'does not create an activity log' do
        expect {
          described_class.new(profile: child, reward: reward).call
        }.not_to change(ActivityLog, :count)
      end
    end

    context 'when allow_negative is true and balance stays within max_debt' do
      let(:family) { create(:family, allow_negative: true, max_debt: 100) }
      let(:child)  { create(:profile, :child, family: family, points: 10) }
      let(:reward) { create(:reward, family: family, cost: 50) }

      it 'allows the redeem and results in a negative balance' do
        result = described_class.new(profile: child, reward: reward).call
        expect(result.success?).to be true
        expect(child.reload.points).to eq(-40)
      end
    end

    context 'when allow_negative is true and redeem lands exactly at -max_debt' do
      let(:family) { create(:family, allow_negative: true, max_debt: 100) }
      let(:child)  { create(:profile, :child, family: family, points: 0) }
      let(:reward) { create(:reward, family: family, cost: 100) }

      it 'allows the redeem at the exact boundary' do
        result = described_class.new(profile: child, reward: reward).call
        expect(result.success?).to be true
        expect(child.reload.points).to eq(-100)
      end
    end

    context 'when allow_negative is true but redeem would exceed max_debt' do
      let(:family) { create(:family, allow_negative: true, max_debt: 100) }
      let(:child)  { create(:profile, :child, family: family, points: 10) }
      let(:reward) { create(:reward, family: family, cost: 500) }

      it 'blocks the redeem and leaves the balance unchanged' do
        result = described_class.new(profile: child, reward: reward).call
        expect(result.success?).to be false
        expect(result.error).to match(/saldo insuficiente/i)
        expect(child.reload.points).to eq(10)
      end
    end

    context 'when allow_negative is false (default)' do
      let(:family) { create(:family, allow_negative: false) }
      let(:child)  { create(:profile, :child, family: family, points: 10) }
      let(:reward) { create(:reward, family: family, cost: 50) }

      it 'blocks the redeem even if max_debt would cover it' do
        result = described_class.new(profile: child, reward: reward).call
        expect(result.success?).to be false
        expect(result.error).to match(/saldo insuficiente/i)
        expect(child.reload.points).to eq(10)
      end
    end

    context 'race condition: two concurrent redeems for same profile' do
      let(:child) { create(:profile, :child, family: family, points: 70) }
      let!(:reward) { create(:reward, family: family, cost: 70) }

      it 'allows exactly one to succeed and the other to fail with balance error' do
        results = []
        mutex = Mutex.new

        threads = 2.times.map do
          Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              result = described_class.new(
                profile: Profile.find(child.id),
                reward: Reward.find(reward.id)
              ).call
              mutex.synchronize { results << result }
            end
          end
        end

        threads.each(&:join)

        successes = results.count { |r| r.success? }
        failures = results.count { |r| !r.success? }

        expect(successes).to eq(1)
        expect(failures).to eq(1)
        expect(results.find { |r| !r.success? }.error).to match(/saldo insuficiente/i)
        expect(child.reload.points).to eq(0)
      end
    end
  end
end

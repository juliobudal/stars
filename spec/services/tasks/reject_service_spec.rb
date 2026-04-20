require 'rails_helper'

RSpec.describe Tasks::RejectService do
  let(:family) { create(:family) }
  let(:child) { create(:profile, :child, family: family, points: 100) }
  let(:global_task) { create(:global_task, family: family, points: 50) }
  let(:profile_task) { create(:profile_task, :awaiting_approval, profile: child, global_task: global_task) }

  describe '#call' do
    context 'when task is awaiting approval' do
      it 'updates status back to pending' do
        described_class.new(profile_task).call
        expect(profile_task.reload.status).to eq('pending')
      end

      it 'does NOT change points' do
        expect {
          described_class.new(profile_task).call
        }.not_to change { child.reload.points }
      end
      
      it 'returns true/truthy' do
        expect(described_class.new(profile_task).call).to be_truthy
      end
    end

    context 'when task is not awaiting approval' do
      let(:profile_task) { create(:profile_task, :pending, profile: child, global_task: global_task) }

      it 'returns false' do
        expect(described_class.new(profile_task).call).to be false
      end
    end
  end
end

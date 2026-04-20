require 'rails_helper'

RSpec.describe Tasks::ApproveService do
  let(:family) { create(:family) }
  let(:child) { create(:profile, :child, family: family, points: 0) }
  let(:global_task) { create(:global_task, family: family, points: 50) }
  let(:profile_task) { create(:profile_task, :awaiting_approval, profile: child, global_task: global_task) }

  describe '#call' do
    context 'when task is awaiting approval' do
      it 'updates status to approved' do
        described_class.new(profile_task).call
        expect(profile_task.reload.status).to eq('approved')
      end

      it 'credits points to the child' do
        expect {
          described_class.new(profile_task).call
        }.to change { child.reload.points }.by(50)
      end

      it 'creates an activity log' do
        expect {
          described_class.new(profile_task).call
        }.to change(ActivityLog, :count).by(1)
        
        log = ActivityLog.last
        expect(log.log_type).to eq('task_completed')
        expect(log.points).to eq(50)
        expect(log.profile).to eq(child)
      end
      
      it 'sets completed_at' do
        described_class.new(profile_task).call
        expect(profile_task.reload.completed_at).to be_present
      end
      
      it 'returns true' do
        expect(described_class.new(profile_task).call).to be true
      end
    end

    context 'when task is already pending' do
      let(:profile_task) { create(:profile_task, :pending, profile: child, global_task: global_task) }

      it 'returns false and does not change points' do
        expect(described_class.new(profile_task).call).to be false
        expect(child.reload.points).to eq(0)
      end
    end
    
    context 'when task is already approved' do
      let(:profile_task) { create(:profile_task, :approved, profile: child, global_task: global_task) }

      it 'returns false' do
        expect(described_class.new(profile_task).call).to be false
      end
    end
  end
end

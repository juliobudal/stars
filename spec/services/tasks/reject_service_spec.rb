require 'rails_helper'

RSpec.describe Tasks::RejectService do
  let(:family) { create(:family) }
  let(:child) { create(:profile, :child, family: family, points: 100) }
  let(:global_task) { create(:global_task, family: family, points: 50) }
  let(:profile_task) { create(:profile_task, :awaiting_approval, profile: child, global_task: global_task) }

  describe '#call' do
    context 'when task is awaiting approval' do
      it 'updates status to rejected' do
        described_class.new(profile_task).call
        expect(profile_task.reload.status).to eq('rejected')
      end

      it 'does NOT change points' do
        expect {
          described_class.new(profile_task).call
        }.not_to change { child.reload.points }
      end

      it 'returns success' do
        result = described_class.new(profile_task).call
        expect(result.success?).to be true
      end
    end

    context 'when task is not awaiting approval' do
      let(:profile_task) { create(:profile_task, :pending, profile: child, global_task: global_task) }

      it 'returns failure' do
        result = described_class.new(profile_task).call
        expect(result.success?).to be false
        expect(result.error).to be_present
      end
    end
  end

  describe "post-reject slot refresh on a repeatable mission" do
    let(:family) { create(:family) }
    let(:profile) { create(:profile, :child, family: family) }
    let(:gt) { create(:global_task, :daily, family: family, max_completions_per_period: 3) }
    let(:awaiting) { create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :awaiting_approval) }

    it "spawns a fresh pending row after a rejection so the kid can retry" do
      expect {
        described_class.new(awaiting).call
      }.to change {
        ProfileTask.where(profile: profile, global_task: gt, status: :pending).count
      }.from(0).to(1)
    end

    it "does not double-spawn if a pending row already exists" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :pending)
      expect {
        described_class.new(awaiting).call
      }.not_to change {
        ProfileTask.where(profile: profile, global_task: gt, status: :pending).count
      }
    end

    context "with cap reached by a prior approval" do
      let(:gt) { create(:global_task, :daily, family: family, max_completions_per_period: 1) }
      let!(:approved) { create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :approved, completed_at: Time.current) }
      let(:awaiting) { create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :awaiting_approval) }

      it "rejects without spawning a new pending while cap remains met by the approval" do
        expect {
          described_class.new(awaiting).call
        }.not_to change { ProfileTask.where(profile: profile, global_task: gt, status: :pending).count }
        expect(awaiting.reload.status).to eq("rejected")
      end
    end
  end
end

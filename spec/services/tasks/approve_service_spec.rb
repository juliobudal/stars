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
        expect(log.log_type).to eq('earn')
        expect(log.points).to eq(50)
        expect(log.profile).to eq(child)
      end

      it 'sets completed_at' do
        described_class.new(profile_task).call
        expect(profile_task.reload.completed_at).to be_present
      end

      it 'returns success' do
        result = described_class.new(profile_task).call
        expect(result.success?).to be true
        expect(result.error).to be_nil
      end
    end

    context 'when task is already pending' do
      let(:profile_task) { create(:profile_task, :pending, profile: child, global_task: global_task) }

      it 'returns failure and does not change points' do
        result = described_class.new(profile_task).call
        expect(result.success?).to be false
        expect(result.error).to be_present
        expect(child.reload.points).to eq(0)
      end
    end

    context 'when task is already approved' do
      let(:profile_task) { create(:profile_task, :approved, profile: child, global_task: global_task) }

      it 'returns failure' do
        result = described_class.new(profile_task).call
        expect(result.success?).to be false
      end
    end

    context 'celebration broadcast' do
      # Stub Streaks::CheckService to nil so the default :big tier (from Ui::Celebration.tier_for(:approved))
      # is not overridden by a real streak/threshold detection (50pt task crosses the 50 threshold).
      before { allow(Streaks::CheckService).to receive(:call).and_return(nil) }

      it 'broadcasts a celebration partial with data-fx-event and tier=big' do
        expect {
          described_class.new(profile_task).call
        }.to have_broadcasted_to("kid_#{child.id}")
          .from_channel(Turbo::StreamsChannel)
          .with { |stream| expect(stream).to include('data-fx-event="celebrate"', 'data-fx-tier="big"') }
      end

      it 'upgrades tier to :streak when Streaks::CheckService returns one' do
        allow(Streaks::CheckService).to receive(:call).and_return({ tier: :streak, payload: { days: 3 } })
        expect {
          described_class.new(profile_task).call
        }.to have_broadcasted_to("kid_#{child.id}")
          # Payload is rendered into an HTML attribute (data-fx-payload) so the JSON's
          # double-quotes are HTML-escaped to &quot;. Assert against the escaped form.
          .with { |stream| expect(stream).to include('&quot;days&quot;:3', 'data-fx-tier="streak"') }
      end
    end
  end
end

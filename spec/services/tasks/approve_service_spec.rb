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

  describe "post-approval slot refresh on a repeatable mission" do
    let(:family) { create(:family) }
    let(:profile) { create(:profile, :child, family: family) }
    let(:gt) { create(:global_task, :daily, family: family, max_completions_per_period: 3) }
    let(:awaiting) { create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :awaiting_approval) }

    it "leaves a pending row available when there is still slot capacity" do
      described_class.new(awaiting).call
      expect(ProfileTask.where(profile: profile, global_task: gt, status: :pending).count).to eq(1)
    end

    it "does not create a pending row when the cap has been reached" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :approved)
      create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :approved)
      described_class.new(awaiting).call
      expect(ProfileTask.where(profile: profile, global_task: gt, status: :pending)).to be_empty
    end
  end

  describe "race condition: two concurrent approvals on the same profile_task" do
    let!(:family) { create(:family) }
    let!(:child) { create(:profile, :child, family: family, points: 0) }
    let!(:global_task) { create(:global_task, family: family, points: 50) }
    let!(:profile_task) { create(:profile_task, :awaiting_approval, profile: child, global_task: global_task) }

    it "credits points exactly once and reports the loser as already processed" do
      results = []
      mutex = Mutex.new

      threads = 2.times.map do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            result = described_class.new(ProfileTask.find(profile_task.id)).call
            mutex.synchronize { results << result }
          end
        end
      end

      threads.each(&:join)

      successes = results.count(&:success?)
      failures = results.reject(&:success?)

      expect(successes).to eq(1)
      expect(failures.size).to eq(1)
      expect(failures.first.error).to match(/já foi processada|aguardando aprovação/i)
      expect(child.reload.points).to eq(50)
    end
  end

  describe "custom missions" do
    let(:family) { create(:family) }
    let(:profile) { create(:profile, family: family, role: :child) }
    let(:category) { create(:category, family: family) }
    let(:profile_task) do
      create(:profile_task, :custom,
             profile: profile,
             custom_category: category,
             custom_points: 50,
             submission_comment: "Foi mole")
    end

    it "applies points_override before crediting" do
      result = described_class.call(profile_task, points_override: 30)

      expect(result).to be_success
      expect(profile_task.reload.custom_points).to eq(30)
      expect(profile.reload.points).to eq(30)
    end

    it "uses original points when no override" do
      result = described_class.call(profile_task)

      expect(result).to be_success
      expect(profile.reload.points).to eq(50)
    end

    it "rejects override outside 1..1000" do
      result = described_class.call(profile_task, points_override: 0)
      expect(result).not_to be_success
      expect(profile.reload.points).to eq(0)
    end

    it "writes submission_comment into ActivityLog title" do
      described_class.call(profile_task)
      log = ActivityLog.last
      expect(log.title).to include("Foi mole").or include("[Sugerida")
    end
  end
end

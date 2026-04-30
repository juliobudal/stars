require 'rails_helper'

RSpec.describe Tasks::DailyResetService do
  include ActiveSupport::Testing::TimeHelpers
  let(:family) { create(:family) }
  let!(:child1) { create(:profile, :child, family: family) }
  let!(:child2) { create(:profile, :child, family: family) }

  # Daily task
  let!(:daily_task) { create(:global_task, :daily, family: family) }

  # Weekly task for Wednesday (wday 3)
  let!(:weekly_task) { create(:global_task, :weekly, family: family, days_of_week: [ 3 ]) }

  describe '#call' do
    context 'when it is Wednesday (wday 3)' do
      let(:wednesday) { Date.new(2024, 1, 3) } # 2024-01-03 was a Wednesday

      it 'instantiates both daily and weekly tasks for all children' do
        expect {
          described_class.new(date: wednesday, family: family).call
        }.to change(ProfileTask, :count).by(4) # 2 children * 2 tasks
      end

      it 'does not duplicate tasks if run twice' do
        service = described_class.new(date: wednesday, family: family)
        service.call
        expect { service.call }.not_to change(ProfileTask, :count)
      end

      it 'assigns the correct date' do
        described_class.new(date: wednesday, family: family).call
        expect(child1.profile_tasks.pluck(:assigned_date).uniq).to eq([ wednesday ])
      end
    end

    context 'when it is Monday (wday 1)' do
      let(:monday) { Date.new(2024, 1, 1) } # 2024-01-01 was a Monday

      it 'instantiates only daily tasks' do
        expect {
          described_class.new(date: monday, family: family).call
        }.to change(ProfileTask, :count).by(2) # 2 children * 1 task (daily_task)

        # Verify weekly task was NOT created
        expect(ProfileTask.where(profile: child1, global_task: weekly_task, assigned_date: monday)).to be_empty
      end
    end

    context 'when family timezone differs from UTC' do
      let(:ny_family) { create(:family, timezone: 'America/New_York') }
      let!(:ny_child) { create(:profile, :child, family: ny_family) }
      let!(:ny_daily_task) { create(:global_task, :daily, family: ny_family) }

      it 'creates tasks for the family-local date, not UTC date' do
        # 2024-01-02 04:00 UTC = 2024-01-01 23:00 in America/New_York
        travel_to Time.utc(2024, 1, 2, 4, 0, 0) do
          described_class.new(family: ny_family).call
          expect(ProfileTask.where(profile: ny_child, global_task: ny_daily_task, assigned_date: Date.new(2024, 1, 1))).to exist
          expect(ProfileTask.where(profile: ny_child, global_task: ny_daily_task, assigned_date: Date.new(2024, 1, 2))).to be_empty
        end
      end
    end

    context 'with inactive missions' do
      let(:monday) { Date.new(2024, 1, 1) }

      it 'skips inactive missions entirely' do
        daily_task.update!(active: false)
        expect {
          described_class.new(date: monday, family: family).call
        }.not_to change(ProfileTask, :count)
      end
    end

    context 'monthly missions' do
      let!(:monthly_task) { create(:global_task, family: family, frequency: :monthly, day_of_month: 15) }

      it 'creates ProfileTask when date matches day_of_month' do
        target_date = Date.new(2026, 5, 15)
        expect {
          described_class.new(date: target_date, family: family).call
        }.to change(ProfileTask, :count).by(4) # daily_task + monthly_task × 2 children
        expect(ProfileTask.where(global_task: monthly_task, assigned_date: target_date)).to exist
      end

      it 'does NOT create ProfileTask when date does not match day_of_month' do
        target_date = Date.new(2026, 5, 14)
        described_class.new(date: target_date, family: family).call
        expect(ProfileTask.where(global_task: monthly_task, assigned_date: target_date)).to be_empty
      end
    end

    context 'once missions' do
      let!(:once_task) { create(:global_task, family: family, frequency: :once) }
      let(:any_date) { Date.new(2026, 5, 1) }

      it 'creates ProfileTask on the first call' do
        expect {
          described_class.new(date: any_date, family: family).call
        }.to change { ProfileTask.where(global_task: once_task).count }.by(2)
      end

      it 'does NOT create ProfileTask on the second call (already exists)' do
        described_class.new(date: any_date, family: family).call
        expect {
          described_class.new(date: any_date + 1, family: family).call
        }.not_to change { ProfileTask.where(global_task: once_task).count }
      end
    end

    context 'with explicit assignments' do
      let(:monday) { Date.new(2024, 1, 1) }

      it 'targets only assigned children' do
        GlobalTaskAssignment.create!(global_task: daily_task, profile: child1)

        expect {
          described_class.new(date: monday, family: family).call
        }.to change(ProfileTask, :count).by(1)

        expect(ProfileTask.where(profile: child1, global_task: daily_task)).to exist
        expect(ProfileTask.where(profile: child2, global_task: daily_task)).to be_empty
      end

      it 'falls back to all children when no assignment is set' do
        expect {
          described_class.new(date: monday, family: family).call
        }.to change(ProfileTask, :count).by(2)
      end
    end

    context 'with repeatable daily missions (max=3)' do
      let(:monday) { Date.new(2024, 1, 1) }
      let!(:repeatable_task) { create(:global_task, :daily, family: family, max_completions_per_period: 3) }

      it 'creates exactly one pending row per child (not three)' do
        described_class.new(date: monday, family: family).call
        expect(ProfileTask.where(global_task: repeatable_task, assigned_date: monday, status: :pending).count).to eq(2) # one per child
      end

      it 'does not respawn pending rows already consumed by prior runs' do
        described_class.new(date: monday, family: family).call
        ProfileTask.where(global_task: repeatable_task).each do |pt|
          pt.update!(status: :awaiting_approval)
        end

        expect {
          described_class.new(date: monday, family: family).call
        }.to change { ProfileTask.where(global_task: repeatable_task, status: :pending).count }.from(0).to(2)
      end
    end
  end

  describe "timezone-aware @date" do
    around do |example|
      Time.use_zone("America/Sao_Paulo") { example.run }
    end

    it "uses today's BR date when called at 23:30 BRT" do
      travel_to Time.zone.local(2026, 4, 30, 23, 30, 0) do
        service = described_class.new(family: family)
        expect(service.instance_variable_get(:@date)).to eq(Date.new(2026, 4, 30))
      end
    end

    it "rolls over to next BR date past midnight" do
      travel_to Time.zone.local(2026, 5, 1, 0, 30, 0) do
        service = described_class.new(family: family)
        expect(service.instance_variable_get(:@date)).to eq(Date.new(2026, 5, 1))
      end
    end
  end
end

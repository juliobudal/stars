require "rails_helper"

RSpec.describe Tasks::SlotRefresher do
  let(:family)  { create(:family, week_start: 1) }
  let(:profile) { create(:profile, :child, family: family) }
  let(:date)    { Date.new(2026, 4, 29) }

  subject(:call) { described_class.new(profile: profile, global_task: gt, date: date).call }

  describe "with a non-repeatable daily task (max=1)" do
    let(:gt) { create(:global_task, :daily, family: family, max_completions_per_period: 1) }

    it "creates one pending profile_task when none exists" do
      expect { call }.to change { ProfileTask.count }.by(1)
      expect(ProfileTask.last).to have_attributes(
        profile_id: profile.id,
        global_task_id: gt.id,
        assigned_date: date,
        status: "pending"
      )
    end

    it "does not duplicate the pending row on repeated calls" do
      call
      expect { call }.not_to change { ProfileTask.count }
    end

    it "destroys the pending row once a slot is consumed (awaiting_approval)" do
      pending_pt = create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :awaiting_approval)
      orphan = create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :pending)

      expect { call }.to change { ProfileTask.where(id: orphan.id).count }.from(1).to(0)
      expect(ProfileTask.where(id: pending_pt.id)).to exist
    end

    it "does not respawn after approval (cap reached)" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :approved)
      expect { call }.not_to change { ProfileTask.where(status: :pending).count }
      expect(ProfileTask.where(profile: profile, global_task: gt, status: :pending)).to be_empty
    end
  end

  describe "with a repeatable daily task (max=3)" do
    let(:gt) { create(:global_task, :daily, family: family, max_completions_per_period: 3) }

    it "creates a fresh pending row after a completion goes awaiting_approval" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :awaiting_approval)
      expect { call }.to change { ProfileTask.where(profile: profile, global_task: gt, status: :pending).count }.from(0).to(1)
    end

    it "creates a fresh pending row after one approval and one awaiting_approval (1 + 1 = 2 < 3)" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :approved)
      create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :awaiting_approval)
      expect { call }.to change { ProfileTask.where(status: :pending).count }.by(1)
    end

    it "stops creating pending rows once the cap of 3 is reached" do
      3.times { create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :approved) }
      expect { call }.not_to change { ProfileTask.where(status: :pending).count }
    end

    it "treats rejected rows as not consuming a slot" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: date, status: :rejected)
      expect { call }.to change { ProfileTask.where(status: :pending).count }.by(1)
    end

    it "respects the assigned_date when computing the period" do
      yesterday = date - 1
      create(:profile_task, profile: profile, global_task: gt, assigned_date: yesterday, status: :approved)
      expect { call }.to change { ProfileTask.where(assigned_date: date, status: :pending).count }.by(1)
    end
  end

  describe "with a repeatable weekly task (max=2)" do
    let(:gt) { create(:global_task, :weekly, family: family, days_of_week: ["3"], max_completions_per_period: 2) }

    it "treats approvals across the same calendar week as part of the same cap" do
      monday    = date - 2 # 2026-04-27
      wednesday = date     # 2026-04-29
      create(:profile_task, profile: profile, global_task: gt, assigned_date: monday, status: :approved)
      create(:profile_task, profile: profile, global_task: gt, assigned_date: wednesday, status: :approved)

      expect { call }.not_to change { ProfileTask.where(status: :pending).count }
    end
  end
end

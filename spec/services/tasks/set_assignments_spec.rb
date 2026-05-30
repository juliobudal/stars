require "rails_helper"

RSpec.describe Tasks::SetAssignments do
  let(:family) { create(:family, week_start: 1) }
  let!(:k1) { create(:profile, :child, family: family, name: "Ana") }
  let!(:k2) { create(:profile, :child, family: family, name: "Beto") }
  let!(:k3) { create(:profile, :child, family: family, name: "Caio") }
  let(:date) { Date.new(2026, 4, 29) }

  def all_ids = family.profiles.child.pluck(:id).sort

  describe "reconciling explicit assignments" do
    let(:gt) { create(:global_task, :daily, family: family) }

    it "stores an explicit subset" do
      result = described_class.call(global_task: gt, profile_ids: [ k1.id ], date: date)
      expect(result).to be_success
      expect(gt.assigned_profiles.pluck(:id)).to contain_exactly(k1.id)
    end

    it "collapses a full set to implicit-all (zero rows)" do
      gt.global_task_assignments.create!(profile_id: k1.id)
      result = described_class.call(global_task: gt, profile_ids: all_ids, date: date)
      expect(result).to be_success
      expect(gt.reload.global_task_assignments).to be_empty
      expect(gt.assigned_to_all?).to be(true)
    end

    it "refuses an empty set when children exist" do
      result = described_class.call(global_task: gt, profile_ids: [], date: date)
      expect(result).not_to be_success
      expect(result.error).to eq(:needs_at_least_one)
    end

    it "ignores profile ids from outside the family" do
      stranger = create(:profile, :child)
      result = described_class.call(global_task: gt, profile_ids: [ k1.id, stranger.id ], date: date)
      expect(result).to be_success
      expect(gt.assigned_profiles.pluck(:id)).to contain_exactly(k1.id)
    end
  end

  describe "slot side effects" do
    let(:gt) { create(:global_task, :daily, family: family) }

    it "creates today's slot for a newly-assigned child" do
      gt.global_task_assignments.create!(profile_id: k1.id)
      expect {
        described_class.call(global_task: gt, profile_ids: [ k1.id, k2.id ], date: date)
      }.to change { ProfileTask.where(global_task: gt, profile_id: k2.id, status: :pending).count }.by(1)
    end

    it "expires a pending slot for an un-assigned child" do
      gt.global_task_assignments.create!(profile_id: k1.id)
      gt.global_task_assignments.create!(profile_id: k2.id)
      pt = ProfileTask.create!(global_task: gt, profile: k2, assigned_date: date, status: :pending)

      described_class.call(global_task: gt, profile_ids: [ k1.id ], date: date)
      expect(pt.reload.status).to eq("expired")
    end

    it "does not create a slot when the task does not fire on the date" do
      weekly = create(:global_task, :weekly, family: family, days_of_week: [ "1" ]) # Monday
      weekly.global_task_assignments.create!(profile_id: k1.id)
      # date is a Wednesday → not applicable
      expect {
        described_class.call(global_task: weekly, profile_ids: [ k1.id, k2.id ], date: date)
      }.not_to change { ProfileTask.where(global_task: weekly, profile_id: k2.id).count }
    end
  end
end

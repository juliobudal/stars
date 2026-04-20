require "rails_helper"

RSpec.describe ProfileTask, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:profile) }
    it { is_expected.to belong_to(:global_task) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, awaiting_approval: 1, approved: 2, rejected: 3) }
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:title).to(:global_task) }
    it { is_expected.to delegate_method(:points).to(:global_task) }
    it { is_expected.to delegate_method(:category).to(:global_task) }
  end

  describe "scopes" do
    describe ".for_today" do
      it "returns tasks assigned for today" do
        task_today = create(:profile_task, assigned_date: Date.current)
        task_yesterday = create(:profile_task, assigned_date: Date.yesterday)
        expect(ProfileTask.for_today).to include(task_today)
        expect(ProfileTask.for_today).not_to include(task_yesterday)
      end
    end

    describe ".actionable" do
      it "returns pending and awaiting_approval tasks" do
        pending_task = create(:profile_task, status: :pending)
        awaiting_task = create(:profile_task, status: :awaiting_approval)
        approved_task = create(:profile_task, status: :approved)

        expect(ProfileTask.actionable).to include(pending_task, awaiting_task)
        expect(ProfileTask.actionable).not_to include(approved_task)
      end
    end
  end
end

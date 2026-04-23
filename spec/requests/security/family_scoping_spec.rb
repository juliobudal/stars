require 'rails_helper'

# Verifies cross-family isolation: a parent signed into family A must not be
# able to read or mutate records belonging to family B. Forged/guessed IDs
# must resolve to 404 (RecordNotFound), never leak data or mutate state.
RSpec.describe "Security::FamilyScoping", type: :request do
  let(:family_a) { create(:family, name: "A") }
  let(:family_b) { create(:family, name: "B") }

  let(:parent_a)  { create(:profile, :parent, family: family_a) }
  let(:child_a)   { create(:profile, :child,  family: family_a, points: 100) }

  let(:parent_b)  { create(:profile, :parent, family: family_b) }
  let(:child_b)   { create(:profile, :child,  family: family_b, points: 100) }

  # Family B records — the parent in family A must not be able to touch these.
  let(:global_task_b)  { create(:global_task, family: family_b) }
  let(:reward_b)       { create(:reward, family: family_b, cost: 50) }
  let(:profile_task_b) { create(:profile_task, :awaiting_approval, profile: child_b, global_task: global_task_b) }
  let(:redemption_b)   { Redemption.create!(profile: child_b, reward: reward_b, points: reward_b.cost, status: :pending) }

  before do
    host! "localhost"
    sign_in_as(parent_a)
  end

  # In request specs Rails rescues RecordNotFound. Depending on request format
  # it renders 404 (GET) or 422 (non-GET). Either way: NOT a 2xx/3xx — the
  # request was rejected and no state was mutated. We assert both.
  def expect_rejected
    expect(response.status).to be_in([404, 422])
  end

  describe "Parent::GlobalTasksController" do
    it "returns 404 on edit for a task in another family" do
      get edit_parent_global_task_path(global_task_b)
      expect_rejected
    end

    it "returns 404 on update for a task in another family" do
      patch parent_global_task_path(global_task_b), params: { global_task: { title: "hacked" } }
      expect_rejected
      expect(global_task_b.reload.title).not_to eq("hacked")
    end

    it "returns 404 on destroy for a task in another family" do
      task = global_task_b
      delete parent_global_task_path(task)
      expect_rejected
      expect(GlobalTask.exists?(task.id)).to be true
    end
  end

  describe "Parent::RewardsController" do
    it "returns 404 on destroy for a reward in another family" do
      reward = reward_b
      delete parent_reward_path(reward)
      expect_rejected
      expect(Reward.exists?(reward.id)).to be true
    end
  end

  describe "Parent::ProfilesController" do
    it "returns 404 on edit for a profile in another family" do
      get edit_parent_profile_path(child_b)
      expect_rejected
    end

    it "returns 404 on update for a profile in another family" do
      patch parent_profile_path(child_b), params: { profile: { name: "hacked" } }
      expect_rejected
      expect(child_b.reload.name).not_to eq("hacked")
    end

    it "returns 404 on destroy for a profile in another family" do
      target = child_b
      delete parent_profile_path(target)
      expect_rejected
      expect(Profile.exists?(target.id)).to be true
    end
  end

  describe "Parent::ApprovalsController — ProfileTask" do
    it "returns 404 on approve for a profile_task in another family" do
      pt = profile_task_b
      patch approve_parent_approval_path(pt)
      expect_rejected
      expect(pt.reload.status).to eq("awaiting_approval")
      expect(child_b.reload.points).to eq(100)
    end

    it "returns 404 on reject for a profile_task in another family" do
      pt = profile_task_b
      patch reject_parent_approval_path(pt)
      expect_rejected
      expect(pt.reload.status).to eq("awaiting_approval")
    end
  end

  describe "Parent::ApprovalsController — Redemption" do
    it "returns 404 on approve_redemption for a redemption in another family" do
      r = redemption_b
      patch approve_redemption_parent_approval_path(r)
      expect_rejected
      expect(r.reload.status).to eq("pending")
    end

    it "returns 404 on reject_redemption for a redemption in another family" do
      r = redemption_b
      patch reject_redemption_parent_approval_path(r)
      expect_rejected
      expect(r.reload.status).to eq("pending")
      expect(child_b.reload.points).to eq(100) # no refund issued
    end
  end
end

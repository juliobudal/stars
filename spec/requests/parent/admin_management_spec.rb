require "rails_helper"

# Covers the admin-area productivity features: the assignment matrix, mission &
# reward libraries / duplication, per-child management, and bulk redemption
# approval.
RSpec.describe "Parent admin management", type: :request do
  before { host! "localhost" }

  let(:family) { create(:family) }
  let(:parent_profile) { create(:profile, :parent, family: family) }
  let!(:k1) { create(:profile, :child, family: family, name: "Ana") }
  let!(:k2) { create(:profile, :child, family: family, name: "Beto") }
  let!(:category) { create(:category, family: family) }

  before { sign_in_as(parent_profile) }

  describe "assignment matrix" do
    let!(:mission) { create(:global_task, :daily, family: family, title: "Arrumar a cama") }

    it "renders the matrix with kids and missions" do
      get assignments_parent_global_tasks_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Arrumar a cama", "Ana", "Beto")
    end

    it "persists a row toggle to a subset" do
      patch assignment_parent_global_task_path(mission), params: { profile_ids: [ k1.id ] }
      expect(response).to have_http_status(:success)
      expect(mission.assigned_profiles.pluck(:id)).to contain_exactly(k1.id)
    end

    it "returns 422 and keeps state when no child is selected" do
      patch assignment_parent_global_task_path(mission), params: { profile_ids: [] }
      expect(response).to have_http_status(:unprocessable_content)
      expect(mission.assigned_to_all?).to be(true)
    end
  end

  describe "mission duplication" do
    let!(:mission) { create(:global_task, :daily, family: family, title: "Ler") }

    it "clones the mission and redirects to edit" do
      mission.global_task_assignments.create!(profile_id: k1.id)
      expect {
        post duplicate_parent_global_task_path(mission)
      }.to change(GlobalTask, :count).by(1)
      copy = GlobalTask.order(:id).last
      expect(copy.title).to eq("Ler (cópia)")
      expect(copy.assigned_profiles.pluck(:id)).to contain_exactly(k1.id)
      expect(response).to redirect_to(edit_parent_global_task_path(copy))
    end
  end

  describe "mission library" do
    it "renders curated templates" do
      get library_parent_global_tasks_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Arrumar a cama")
    end

    it "adds selected templates to the catalog" do
      expect {
        post add_from_template_parent_global_tasks_path, params: { keys: %w[arrumar_cama escovar_dentes] }
      }.to change { GlobalTask.where(family_id: family.id).count }.by(2)
      expect(response).to redirect_to(parent_global_tasks_path)
    end
  end

  describe "reward duplication & library" do
    let!(:reward) { create(:reward, family: family, title: "Sorvete", category: category) }

    it "duplicates a reward" do
      expect {
        post duplicate_parent_reward_path(reward)
      }.to change(Reward, :count).by(1)
      expect(Reward.order(:id).last.title).to eq("Sorvete (cópia)")
    end

    it "adds reward templates under the first category" do
      expect {
        post add_from_template_parent_rewards_path, params: { keys: %w[sorvete cinema] }
      }.to change { Reward.where(family_id: family.id).count }.by(2)
      expect(response).to redirect_to(parent_rewards_path)
    end
  end

  describe "per-child management" do
    let!(:mission) { create(:global_task, :daily, family: family, title: "Lição") }

    it "renders the management panel" do
      get manage_parent_profile_path(k1)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Lição")
    end

    it "removes a child from an implicit-all mission, keeping the sibling" do
      patch toggle_mission_parent_profile_path(k1), params: { mission_id: mission.id, assigned: false }
      expect(response).to have_http_status(:success)
      expect(mission.assigned_profiles.pluck(:id)).to contain_exactly(k2.id)
    end

    it "re-adds a child to a mission" do
      k3 = create(:profile, :child, family: family, name: "Caio")
      mission.global_task_assignments.create!(profile_id: k2.id)
      patch toggle_mission_parent_profile_path(k1), params: { mission_id: mission.id, assigned: true }
      expect(mission.assigned_profiles.pluck(:id)).to contain_exactly(k1.id, k2.id)
      expect(mission.assigned_profiles.pluck(:id)).not_to include(k3.id)
    end
  end

  describe "bulk redemption approval" do
    let!(:reward) { create(:reward, family: family, cost: 10, category: category) }
    let!(:r1) { create(:redemption, profile: k1, reward: reward, status: :pending, points: 10) }
    let!(:r2) { create(:redemption, profile: k2, reward: reward, status: :pending, points: 10) }

    it "approves several redemptions at once" do
      post bulk_approve_redemptions_parent_approvals_path, params: { approval_ids: [ r1.id, r2.id ] }
      expect(r1.reload.status).to eq("approved")
      expect(r2.reload.status).to eq("approved")
    end

    it "rejects several redemptions and refunds points" do
      k1.update!(points: 0)
      post bulk_reject_redemptions_parent_approvals_path, params: { approval_ids: [ r1.id ] }
      expect(r1.reload.status).to eq("rejected")
      expect(k1.reload.points).to eq(10)
    end
  end
end

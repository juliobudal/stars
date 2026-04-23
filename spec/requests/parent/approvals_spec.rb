require 'rails_helper'

RSpec.describe "Parent::Approvals", type: :request do
  let(:family) { create(:family) }
  let(:parent) { create(:profile, :parent, family: family) }
  let(:child) { create(:profile, :child, family: family, points: 0) }
  let(:global_task) { create(:global_task, family: family, points: 50) }
  let(:profile_task) { create(:profile_task, :awaiting_approval, profile: child, global_task: global_task) }

  before do
    host! "localhost"
    post "/sessions", params: { email: parent.email, password: "supersecret1234" }
  end

  describe "GET /parent/approvals" do
    it "returns http success" do
      get parent_approvals_path
      expect(response).to have_http_status(:success)
    end

    it "lists tasks awaiting approval" do
      task = profile_task
      get parent_approvals_path
      expect(response.body).to include(task.title)
    end
  end

  describe "PATCH /parent/approvals/:id/approve" do
    it "approves the task and credits points" do
      expect {
        patch approve_parent_approval_path(profile_task)
      }.to change { child.reload.points }.by(50)
      
      expect(profile_task.reload.status).to eq('approved')
      expect(response).to redirect_to(parent_approvals_path)
    end
  end

  describe "PATCH /parent/approvals/:id/reject" do
    it "rejects the task" do
      patch reject_parent_approval_path(profile_task)

      expect(profile_task.reload.status).to eq('rejected')
      expect(response).to redirect_to(parent_approvals_path)
    end
  end

  describe "POST /parent/approvals/bulk_approve" do
    let(:global_task2) { create(:global_task, family: family, points: 30) }
    let(:global_task3) { create(:global_task, family: family, points: 20) }
    let(:task1) { create(:profile_task, :awaiting_approval, profile: child, global_task: global_task) }
    let(:task2) { create(:profile_task, :awaiting_approval, profile: child, global_task: global_task2) }
    let(:task3) { create(:profile_task, :awaiting_approval, profile: child, global_task: global_task3) }

    it "approves all selected tasks and credits points" do
      ids = [task1.id, task2.id, task3.id]
      expect {
        post bulk_approve_parent_approvals_path, params: { approval_ids: ids }
      }.to change { child.reload.points }.by(100)

      expect(task1.reload.status).to eq("approved")
      expect(task2.reload.status).to eq("approved")
      expect(task3.reload.status).to eq("approved")
      expect(response).to redirect_to(parent_approvals_path)
    end

    it "redirects with alert when approval_ids is empty" do
      post bulk_approve_parent_approvals_path, params: { approval_ids: [] }
      expect(response).to redirect_to(parent_approvals_path)
      expect(flash[:alert]).to be_present
    end

    it "does not approve tasks belonging to another family" do
      other_family  = create(:family)
      other_child   = create(:profile, :child, family: other_family, points: 0)
      other_gt      = create(:global_task, family: other_family, points: 50)
      other_task    = create(:profile_task, :awaiting_approval, profile: other_child, global_task: other_gt)

      post bulk_approve_parent_approvals_path, params: { approval_ids: [other_task.id] }

      expect(other_task.reload.status).to eq("awaiting_approval")
      expect(other_child.reload.points).to eq(0)
    end
  end

  context "security" do
    it "prevents child from accessing" do
      post "/sessions", params: { profile_id: child.id }
      get parent_approvals_path
      expect(response).to redirect_to(root_path)
    end
  end
end

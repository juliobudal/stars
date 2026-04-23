require 'rails_helper'

RSpec.describe "Parent::Approvals", type: :request do
  let(:family) { create(:family) }
  let(:parent) { create(:profile, :parent, family: family) }
  let(:child) { create(:profile, :child, family: family, points: 0) }
  let(:global_task) { create(:global_task, family: family, points: 50) }
  let(:profile_task) { create(:profile_task, :awaiting_approval, profile: child, global_task: global_task) }

  before do
    host! "localhost"
    post "/sessions", params: { profile_id: parent.id }
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

  context "security" do
    it "prevents child from accessing" do
      post "/sessions", params: { profile_id: child.id }
      get parent_approvals_path
      expect(response).to redirect_to(root_path)
    end
  end
end

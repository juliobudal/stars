require 'rails_helper'

RSpec.describe "Kid::Dashboard", type: :request do
  let(:family) { create(:family) }
  let(:parent) { create(:profile, :parent, family: family) }
  let(:child) { create(:profile, :child, family: family, points: 100) }
  let(:global_task) { create(:global_task, family: family, points: 50) }
  let(:profile_task) { create(:profile_task, :pending, profile: child, global_task: global_task) }

  before do
    host! "localhost"
    post "/sessions", params: { profile_id: child.id }
  end

  describe "GET /kid" do
    it "returns http success and shows missions" do
      task = profile_task
      get kid_root_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(task.title)
      expect(response.body).to include("100") # Points
    end
  end

  describe "PATCH /kid/missions/:id/complete" do
    it "marks mission as awaiting_approval" do
      task = profile_task
      patch complete_kid_mission_path(task)
      expect(task.reload.status).to eq('awaiting_approval')
      expect(response).to redirect_to(kid_root_path)
    end
  end

  describe "Security" do
    it "prevents parent from accessing kid dashboard" do
      post "/sessions", params: { profile_id: parent.id }
      get kid_root_path
      expect(response).to redirect_to(root_path)
    end

    it "returns 404 when child tries to complete someone else's task" do
      other_child = create(:profile, :child, family: family)
      other_task = create(:profile_task, :pending, profile: other_child, global_task: global_task)
      
      patch complete_kid_mission_path(other_task)
      expect(response).to have_http_status(:not_found)
    end
  end
end

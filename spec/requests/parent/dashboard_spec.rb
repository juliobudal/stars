require "rails_helper"

RSpec.describe "Parent::Dashboard", type: :request do
  let(:family) { create(:family) }
  let(:parent) { create(:profile, :parent, family: family) }
  let(:child) { create(:profile, :child, family: family, points: 10) }

  before { host! "localhost" }

  describe "Access control" do
    it "redirects unauthenticated requests" do
      get parent_root_path
      expect(response).to redirect_to(root_path)
    end

    it "denies child profiles" do
      post "/sessions", params: { email: child.email, password: "supersecret1234" }
      get parent_root_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /parent" do
    before { post "/sessions", params: { email: parent.email, password: "supersecret1234" } }

    it "returns http success" do
      get parent_root_path
      expect(response).to have_http_status(:success)
    end

    it "lists children" do
      child
      get parent_root_path
      expect(response.body).to include(child.name)
    end

    it "shows pending approvals count in stats" do
      global_task = create(:global_task, family: family, points: 5)
      create(:profile_task, :awaiting_approval, profile: child, global_task: global_task)
      get parent_root_path
      expect(response).to have_http_status(:success)
    end
  end
end

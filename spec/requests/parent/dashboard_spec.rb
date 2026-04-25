require "rails_helper"

RSpec.describe "Parent::Dashboard", type: :request do
  let(:family) { create(:family) }
  let(:parent) { create(:profile, :parent, family: family) }
  let(:child) { create(:profile, :child, family: family, points: 10) }

  before { host! "localhost" }

  describe "Access control" do
    it "redirects unauthenticated requests" do
      get parent_root_path
      expect(response).to redirect_to(new_family_session_path)
    end

    it "denies child profiles" do
      sign_in_as(child)
      get parent_root_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /parent" do
    before { sign_in_as(parent) }

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

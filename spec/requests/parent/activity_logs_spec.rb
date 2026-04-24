require "rails_helper"

RSpec.describe "Parent::ActivityLogs", type: :request do
  let(:family) { create(:family) }
  let(:parent) { create(:profile, :parent, family: family) }
  let(:child) { create(:profile, :child, family: family) }
  let(:other_family) { create(:family) }
  let(:other_child) { create(:profile, :child, family: other_family) }

  before { host! "localhost" }

  describe "Access control" do
    it "redirects unauthenticated requests" do
      get parent_activity_logs_path
      expect(response).to redirect_to(root_path)
    end

    it "denies child profiles" do
      post "/sessions", params: { email: child.email, password: "supersecret1234" }
      get parent_activity_logs_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /parent/activity_logs" do
    before { post "/sessions", params: { email: parent.email, password: "supersecret1234" } }

    it "returns http success" do
      get parent_activity_logs_path
      expect(response).to have_http_status(:success)
    end

    it "shows activity logs for family children" do
      log = create(:activity_log, profile: child, log_type: :earn, title: "Missão Concluída: Arrumar o quarto", points: 10)
      get parent_activity_logs_path
      expect(response.body).to include(log.title)
    end

    it "does not show logs from other families" do
      other_log = create(:activity_log, profile: other_child, log_type: :earn, title: "Tarefa de outra família", points: 5)
      get parent_activity_logs_path
      expect(response.body).not_to include(other_log.title)
    end
  end
end

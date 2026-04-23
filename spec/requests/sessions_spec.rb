require "rails_helper"

RSpec.describe "Sessions", type: :request do
  before { host! "localhost" }

  let(:family) { create(:family) }
  let(:parent_profile) { create(:profile, :parent, family: family) }
  let(:child_profile) { create(:profile, :child, family: family) }

  describe "POST /sessions — email+password (parent)" do
    it "logs in with correct credentials and redirects to parent dashboard" do
      post sessions_path, params: { email: parent_profile.email, password: "supersecret1234" }
      expect(response).to redirect_to(parent_root_path)
    end

    it "rotates session id on successful login (reset_session called)" do
      # Establish a session cookie, then verify it changes after login
      get root_path
      old_cookie = cookies["_app_session"]
      post sessions_path, params: { email: parent_profile.email, password: "supersecret1234" }
      # reset_session issues a new session — cookie value must differ or be absent then re-set
      expect(cookies["_app_session"]).not_to eq(old_cookie)
    end

    it "returns 302 with flash on wrong password" do
      post sessions_path, params: { email: parent_profile.email, password: "wrongpassword999" }
      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq("Email ou senha incorretos.")
    end

    it "returns 302 with flash on unknown email" do
      post sessions_path, params: { email: "nobody@example.com", password: "supersecret1234" }
      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to eq("Email ou senha incorretos.")
    end
  end

  describe "POST /sessions — profile_id picker (kid)" do
    it "redirects child to /kid dashboard" do
      post sessions_path, params: { profile_id: child_profile.id }
      expect(response).to redirect_to(kid_root_path)
    end

    it "prevents parent from using the picker path" do
      post sessions_path, params: { profile_id: parent_profile.id }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "DELETE /sessions" do
    it "clears the session and redirects to root" do
      post sessions_path, params: { email: parent_profile.email, password: "supersecret1234" }
      delete sessions_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "Protected Routes" do
    it "redirects unauthenticated users to root" do
      get parent_root_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Por favor, selecione um perfil primeiro.")
    end

    it "prevents children from accessing parent dashboard" do
      post sessions_path, params: { profile_id: child_profile.id }
      get parent_root_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Acesso restrito para pais.")
    end

    it "prevents parents from accessing child dashboard" do
      post sessions_path, params: { email: parent_profile.email, password: "supersecret1234" }
      get kid_root_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Acesso restrito para filhos.")
    end
  end

  describe "rate limiting" do
    it "returns 429 after 10 login attempts within 3 minutes" do
      10.times do
        post sessions_path, params: { email: "x@x.com", password: "wrongpassword999" }
      end
      post sessions_path, params: { email: "x@x.com", password: "wrongpassword999" }
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end

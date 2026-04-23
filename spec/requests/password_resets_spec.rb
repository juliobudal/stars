require "rails_helper"

RSpec.describe "PasswordResets", type: :request do
  before { host! "localhost" }

  let(:family) { create(:family) }
  let(:parent_profile) { create(:profile, :parent, family: family) }

  describe "POST /password_reset" do
    it "enqueues mail for known email and redirects with neutral flash" do
      parent_profile # ensure created
      expect {
        post password_reset_path, params: { email: parent_profile.email }
      }.to have_enqueued_mail(PasswordMailer, :reset)
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to be_present
    end

    it "redirects with neutral flash even for unknown email (no leak)" do
      expect {
        post password_reset_path, params: { email: "nobody@example.com" }
      }.not_to have_enqueued_mail(PasswordMailer, :reset)
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to be_present
    end
  end

  describe "GET /password_reset/edit" do
    it "renders edit form for valid token" do
      token = parent_profile.signed_id(purpose: :password_reset, expires_in: 2.hours)
      get edit_password_reset_path(token: token)
      expect(response).to have_http_status(:ok)
    end

    it "redirects for expired/invalid token" do
      get edit_password_reset_path(token: "invalid-token")
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /password_reset" do
    it "updates password, logs in, and redirects to parent dashboard" do
      token = parent_profile.signed_id(purpose: :password_reset, expires_in: 2.hours)
      patch password_reset_path(token: token), params: {
        token: token,
        password: "newpassword5678",
        password_confirmation: "newpassword5678"
      }
      expect(response).to redirect_to(parent_root_path)
      parent_profile.reload
      expect(parent_profile.authenticate("newpassword5678")).to be_truthy
    end

    it "redirects for invalid token" do
      patch password_reset_path(token: "bad-token"), params: {
        token: "bad-token",
        password: "newpassword5678",
        password_confirmation: "newpassword5678"
      }
      expect(response).to redirect_to(root_path)
    end
  end
end

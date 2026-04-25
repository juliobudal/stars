require "rails_helper"

RSpec.describe "FamilySessions", type: :request do
  let!(:family) { Family.create!(name: "Fam", email: "f@x.co", password: "supersecret1234") }

  describe "POST /family_session" do
    it "sets a signed cookie and redirects to picker on valid creds" do
      post family_session_path, params: { email: "f@x.co", password: "supersecret1234" }
      expect(response).to redirect_to(new_profile_session_path)
      expect(cookies.signed[:family_id]).to eq(family.id)
    end

    it "re-renders new on invalid creds" do
      post family_session_path, params: { email: "f@x.co", password: "wrong" }
      expect(response).to have_http_status(:unprocessable_content).or have_http_status(:ok)
      expect(cookies.signed[:family_id]).to be_blank
    end
  end

  describe "DELETE /family_session" do
    it "clears the family cookie" do
      post family_session_path, params: { email: "f@x.co", password: "supersecret1234" }
      delete family_session_path
      expect(cookies.signed[:family_id]).to be_blank
    end
  end

  describe "GET /family_session/new" do
    it "redirects to profile picker when cookie maps to an existing family" do
      post family_session_path, params: { email: "f@x.co", password: "supersecret1234" }
      get new_family_session_path
      expect(response).to redirect_to(new_profile_session_path)
    end

    it "renders the form and clears the cookie when family record is gone (stale cookie)" do
      post family_session_path, params: { email: "f@x.co", password: "supersecret1234" }
      family.destroy
      get new_family_session_path
      expect(response).to have_http_status(:ok)
      expect(cookies.signed[:family_id]).to be_blank
    end
  end
end

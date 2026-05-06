require "rails_helper"

RSpec.describe "ProfileSessions", type: :request do
  let!(:family) { Family.create!(name: "Fam", email: "f@x.co", password: "supersecret1234") }
  let!(:kid)    { family.profiles.create!(name: "Kid", role: :child, pin: "1234") }
  let!(:other)  { Family.create!(name: "Other", email: "o@x.co", password: "supersecret1234").profiles.create!(name: "Stranger", role: :child, pin: "9999") }

  before do
    post family_session_path, params: { email: "f@x.co", password: "supersecret1234" }
  end

  it "redirects to family login if no family cookie" do
    cookies.delete(:family_id)
    get new_profile_session_path
    expect(response).to redirect_to(new_family_session_path)
  end

  it "renders picker with family profiles" do
    get new_profile_session_path
    expect(response).to be_successful
    expect(response.body).to include("Kid")
  end

  it "logs in profile with correct PIN" do
    post profile_session_path, params: { profile_id: kid.id, pin: "1234" }
    expect(response).to redirect_to(kid_root_path)
    expect(session[:profile_id]).to eq(kid.id)
  end

  it "rejects wrong PIN" do
    post profile_session_path, params: { profile_id: kid.id, pin: "0000" }
    expect(session[:profile_id]).to be_blank
  end

  it "404s on cross-family profile_id" do
    post profile_session_path, params: { profile_id: other.id, pin: "9999" }
    expect(response).to have_http_status(:not_found)
  end

  describe "PIN lockout" do
    before { Rails.cache.clear }

    it "locks the profile after 5 wrong PIN attempts" do
      5.times do
        post profile_session_path, params: { profile_id: kid.id, pin: "0000" }
      end
      post profile_session_path, params: { profile_id: kid.id, pin: "1234" }
      expect(response).to have_http_status(:too_many_requests)
      expect(session[:profile_id]).to be_blank
    end

    it "resets attempt counter on successful login" do
      4.times do
        post profile_session_path, params: { profile_id: kid.id, pin: "0000" }
      end
      post profile_session_path, params: { profile_id: kid.id, pin: "1234" }
      expect(response).to redirect_to(kid_root_path)
    end
  end
end

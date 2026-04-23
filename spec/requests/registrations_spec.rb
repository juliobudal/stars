require "rails_helper"

RSpec.describe "Registrations", type: :request do
  before { host! "localhost" }

  describe "POST /registration" do
    let(:valid_params) do
      {
        family_name: "Família Silva",
        name: "João Silva",
        email: "joao@example.com",
        password: "supersecret1234",
        password_confirmation: "supersecret1234"
      }
    end

    it "creates a family, parent profile, and sets session" do
      expect {
        post registration_path, params: valid_params
      }.to change(Family, :count).by(1)
        .and change(Profile, :count).by(1)

      expect(response).to redirect_to(parent_root_path)

      profile = Profile.last
      expect(profile.parent?).to be true
      expect(profile.email).to eq("joao@example.com")
      expect(profile.confirmed_at).to be_present
    end

    it "renders new on invalid params" do
      post registration_path, params: valid_params.merge(password: "short")
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /registration/new" do
    it "renders the registration form" do
      get new_registration_path
      expect(response).to have_http_status(:ok)
    end
  end
end

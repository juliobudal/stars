require "rails_helper"

RSpec.describe "Registrations", type: :request do
  before { host! "localhost" }

  describe "POST /registration" do
    let(:valid_params) do
      {
        family: {
          name: "Família Silva",
          email: "joao@example.com",
          password: "supersecret1234"
        }
      }
    end

    it "creates a family and redirects to onboarding profile form" do
      expect {
        post registration_path, params: valid_params
      }.to change(Family, :count).by(1)

      expect(response).to redirect_to(new_parent_profile_path(onboarding: true))

      family = Family.last
      expect(family.email).to eq("joao@example.com")
      expect(family.name).to eq("Família Silva")
    end

    it "renders new on invalid params" do
      post registration_path, params: { family: { name: "x", email: "joao@example.com", password: "short" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /registration/new" do
    it "renders the registration form" do
      get new_registration_path
      expect(response).to have_http_status(:ok)
    end
  end
end

require 'rails_helper'

RSpec.describe "Kid::Onboarding", type: :request do
  let(:family) { create(:family) }
  let(:fresh_child) { create(:profile, :child, :fresh, family: family, name: "Lila") }
  let(:onboarded_child) { create(:profile, :child, family: family) }
  let(:parent) { create(:profile, :parent, family: family) }

  before { host! "localhost" }

  describe "gate" do
    it "redirects an un-onboarded child from the kid root to the welcome flow" do
      sign_in_as(fresh_child)
      get kid_root_path
      expect(response).to redirect_to(kid_welcome_path)
    end

    it "does not redirect an already-onboarded child" do
      sign_in_as(onboarded_child)
      get kid_root_path
      expect(response).to have_http_status(:success)
    end

    it "redirects un-onboarded kids from other kid surfaces too" do
      sign_in_as(fresh_child)
      get kid_rewards_path
      expect(response).to redirect_to(kid_welcome_path)
    end

    it "redirects un-onboarded kids from Academy surfaces" do
      sign_in_as(fresh_child)
      get kid_academy_root_path
      expect(response).to redirect_to(kid_welcome_path)
    end

    it "lets parents through to / when they try /kid" do
      sign_in_as(parent)
      get kid_root_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /kid/welcome" do
    before { sign_in_as(fresh_child) }

    it "renders the welcome screen with the kid's name" do
      get kid_welcome_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Lila")
      expect(response.body).to include("Bora")
    end

    it "does not bounce already-onboarded kids away" do
      sign_in_as(onboarded_child)
      get kid_welcome_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /kid/welcome/interests" do
    before { sign_in_as(fresh_child) }

    it "renders the interest picker with the canonical catalog" do
      get kid_welcome_interests_path
      expect(response).to have_http_status(:success)
      ProfileInterest::Catalog.all.first(3).each do |entry|
        expect(response.body).to include(entry.label)
      end
    end
  end

  describe "PATCH /kid/welcome/interests" do
    before { sign_in_as(fresh_child) }

    it "persists 3+ valid keys and advances to the how-it-works screen" do
      patch kid_welcome_interests_path, params: { interest_keys: %w[dinossauros espaco futebol] }
      expect(response).to redirect_to(kid_welcome_how_path)
      expect(fresh_child.profile_interests.order(:rank).pluck(:interest_key))
        .to eq(%w[dinossauros espaco futebol])
    end

    it "rejects fewer than 3 selections" do
      patch kid_welcome_interests_path, params: { interest_keys: %w[dinossauros espaco] }
      expect(response).to have_http_status(:unprocessable_content)
      expect(fresh_child.profile_interests).to be_empty
    end

    it "ignores unknown keys but accepts the valid remainder" do
      patch kid_welcome_interests_path,
            params: { interest_keys: %w[dinossauros not_a_real_key espaco futebol] }
      expect(response).to redirect_to(kid_welcome_how_path)
      expect(fresh_child.profile_interests.pluck(:interest_key))
        .to match_array(%w[dinossauros espaco futebol])
    end

    it "replaces previous selections idempotently" do
      fresh_child.profile_interests.create!(interest_key: "gatos", rank: 1)
      patch kid_welcome_interests_path, params: { interest_keys: %w[dinossauros espaco futebol] }
      expect(fresh_child.profile_interests.pluck(:interest_key))
        .to match_array(%w[dinossauros espaco futebol])
    end
  end

  describe "GET /kid/welcome/how" do
    it "renders the three explanation cards" do
      sign_in_as(fresh_child)
      get kid_welcome_how_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Missões")
      expect(response.body).to include("Estrelinhas")
      expect(response.body).to include("Recompensas")
    end
  end

  describe "GET /kid/welcome/ready" do
    it "renders the ready screen with the finish form" do
      sign_in_as(fresh_child)
      get kid_welcome_ready_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Tudo pronto")
      expect(response.body).to include("Lila")
    end
  end

  describe "POST /kid/welcome/finish" do
    before { sign_in_as(fresh_child) }

    it "stamps onboarded_at and redirects to /kid" do
      expect {
        post kid_welcome_finish_path
        fresh_child.reload
      }.to change(fresh_child, :onboarded_at).from(nil)

      expect(response).to redirect_to(kid_root_path)
      follow_redirect!
      expect(response.body).to include("Lila")
    end

    it "is idempotent on replay" do
      post kid_welcome_finish_path
      expect(response).to redirect_to(kid_root_path)

      first_stamp = fresh_child.reload.onboarded_at
      travel_to(1.second.from_now) do
        post kid_welcome_finish_path
        expect(response).to redirect_to(kid_root_path)
      end

      expect(fresh_child.reload.onboarded_at).to be > first_stamp
    end
  end
end

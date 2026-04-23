require 'rails_helper'

RSpec.describe "Parent::Settings", type: :request do
  before { host! "localhost" }

  let(:family) { create(:family) }
  let(:parent_profile) { create(:profile, :parent, family: family) }

  def login_as(profile)
    sign_in_as(profile)
  end

  describe "Access Control" do
    it "redirects unauthenticated" do
      get parent_settings_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /parent/settings" do
    before { login_as(parent_profile) }

    it "renders" do
      get parent_settings_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /parent/settings" do
    before { login_as(parent_profile) }

    it "persists settings" do
      patch parent_settings_path, params: {
        family: {
          locale: "en",
          timezone: "Europe/Lisbon",
          week_start: "0",
          require_photo: "1",
          decay_enabled: "0",
          allow_negative: "1",
          auto_approve_threshold: "15"
        }
      }

      expect(response).to redirect_to(parent_settings_path)
      family.reload
      expect(family.locale).to eq("en")
      expect(family.timezone).to eq("Europe/Lisbon")
      expect(family.week_start).to eq(0)
      expect(family.require_photo).to eq(true)
      expect(family.decay_enabled).to eq(false)
      expect(family.allow_negative).to eq(true)
      expect(family.auto_approve_threshold).to eq(15)
    end

    it "blanks threshold when empty" do
      family.update!(auto_approve_threshold: 25)
      patch parent_settings_path, params: { family: { auto_approve_threshold: "" } }
      expect(family.reload.auto_approve_threshold).to be_nil
    end
  end
end

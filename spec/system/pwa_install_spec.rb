require "rails_helper"

# NOTE: Despite the file path being spec/system/, this is a `type: :request` spec.
# Why: the SW registration / install prompt UI flow involves browser-only events
# (`beforeinstallprompt`, `navigator.standalone`) that headless Chrome does not
# fire reliably. The request spec proves the SERVER-SIDE wiring (routes resolve,
# layouts render the install components hidden, manifest + SW endpoints serve
# valid bodies). Browser-side behavior is verified manually + via Lighthouse.
#
# Also note: Stimulus identifiers are FLAT in this codebase
# (`data-controller="install-prompt"`, NOT path-based "ui--install-prompt--install-prompt").
# See plans 07-05 / 07-06 carry-over notes.
RSpec.describe "PWA install integration", type: :request do
  describe "GET /manifest" do
    it "serves a valid expanded manifest" do
      # Match the Accept header browsers send for the <link rel="manifest"> request
      # so the Rails PWA controller picks the .json.erb template.
      get "/manifest", headers: { "Accept" => "application/manifest+json,application/json" }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["name"]).to eq("LittleStars")
      expect(json["lang"]).to eq("pt-BR")
      expect(json["start_url"]).to include("source=pwa")
      expect(json["icons"]).to be_an(Array)
      expect(json["icons"].map { |i| i["sizes"] }).to include("192x192", "512x512")
      expect(json["icons"].any? { |i| i["purpose"]&.include?("maskable") }).to be(true)
    end
  end

  describe "GET /service-worker" do
    it "serves the SW JS with the expected cache version" do
      # Browsers fetch /service-worker with text/javascript Accept; mirror that so
      # Rails picks the service-worker.js template.
      get "/service-worker", headers: { "Accept" => "text/javascript,application/javascript" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("littlestars-v1")
      expect(response.body).to include("addEventListener")
      expect(response.body).to include("offline.html")
    end
  end

  describe "kid layout" do
    let(:family) { create(:family) }
    let(:child)  { create(:profile, :child, family: family) }

    before do
      host! "localhost"
      sign_in_as(child)
    end

    it "renders both install components hidden" do
      get "/kid"
      expect(response).to have_http_status(:ok)
      # Flat Stimulus identifier (not path-based) — see header note.
      expect(response.body).to include('data-controller="install-prompt"')
      expect(response.body).to include('data-controller="ios-install-hint"')
      # Both components render with the HTML5 boolean `hidden` attribute.
      expect(response.body).to match(/<div hidden[^>]*data-controller="install-prompt"/m)
      expect(response.body).to match(/<div hidden[^>]*data-controller="ios-install-hint"/m)
    end

    it "renders the manifest link tag and theme-color meta in head" do
      get "/kid"
      expect(response.body).to include('rel="manifest"')
      expect(response.body).to include('name="theme-color"')
    end
  end

  describe "parent layout" do
    let(:family) { create(:family) }
    let(:parent_profile) { create(:profile, :parent, family: family) }

    before do
      host! "localhost"
      sign_in_as(parent_profile)
    end

    it "renders both install components hidden" do
      get "/parent"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="install-prompt"')
      expect(response.body).to include('data-controller="ios-install-hint"')
      expect(response.body).to match(/<div hidden[^>]*data-controller="install-prompt"/m)
    end

    it "renders the manifest link tag and theme-color meta in head" do
      get "/parent"
      expect(response.body).to include('rel="manifest"')
      expect(response.body).to include('name="theme-color"')
    end
  end
end

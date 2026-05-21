# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Illustrations::Generate do
  # 1×1 transparent PNG bytes.
  let(:tiny_png_bytes) do
    Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
    )
  end

  let(:concept) { create(:academy_concept, slug: "test-rspec-pill", name: "Test rspec pill") }
  let(:hint)    { "Ilustração de pedra com fresta e gotas d'água." }
  let(:lens_cache) do
    Academy::LensCache.create!(
      concept: concept, lens_type: "scientific", age_band: "kid", locale: "pt-BR",
      source: "curated", generated_at: Time.current,
      payload: { "headline" => "Água que rachou montanha", "illustration_hint" => hint }
    )
  end

  let(:client) { instance_double(Academy::Illustrations::Client) }
  let(:client_response) do
    { mime: "image/png", bytes: tiny_png_bytes, model: "google/gemini-2.5-flash-image", raw: {} }
  end

  let(:output_path) { described_class::OUTPUT_DIR.join("test-rspec-pill.webp") }

  before do
    Academy.config.openrouter_api_key = "x" * 20
    FileUtils.rm_f(output_path)
  end

  after do
    Academy.config.openrouter_api_key = ""
    FileUtils.rm_f(output_path)
  end

  describe "success path" do
    before { allow(client).to receive(:generate).and_return(client_response) }

    it "writes a webp file and updates the payload" do
      result = described_class.call(lens_cache: lens_cache, client: client)

      expect(result.success?).to be true
      expect(result.data[:skipped]).to be false
      expect(result.data[:slug]).to eq("test-rspec-pill")
      expect(result.data[:url]).to eq("/academy/illustrations/test-rspec-pill.webp")
      expect(File.exist?(output_path)).to be true
      expect(File.size(output_path)).to be > 0

      lens_cache.reload
      expect(lens_cache.payload["illustration_url"]).to eq("/academy/illustrations/test-rspec-pill.webp")
      expect(lens_cache.payload["illustration_meta"]).to include(
        "style" => Academy::Illustrations::PromptComposer::STYLE_VERSION,
        "model" => "google/gemini-2.5-flash-image"
      )
      expect(lens_cache.payload["illustration_meta"]["generated_at"]).to be_present
    end

    it "preserves the original hint and headline" do
      described_class.call(lens_cache: lens_cache, client: client)
      lens_cache.reload
      expect(lens_cache.payload["illustration_hint"]).to eq(hint)
      expect(lens_cache.payload["headline"]).to eq("Água que rachou montanha")
    end
  end

  describe "idempotence" do
    it "skips when URL+file+style already match" do
      allow(client).to receive(:generate).and_return(client_response)
      described_class.call(lens_cache: lens_cache, client: client)

      allow(client).to receive(:generate).and_raise("should not be called")
      result = described_class.call(lens_cache: lens_cache, client: client)

      expect(result.success?).to be true
      expect(result.data[:skipped]).to be true
    end

    it "regenerates when force: true even if up to date" do
      allow(client).to receive(:generate).and_return(client_response)
      described_class.call(lens_cache: lens_cache, client: client)

      result = described_class.call(lens_cache: lens_cache, client: client, force: true)
      expect(result.success?).to be true
      expect(result.data[:skipped]).to be false
      expect(client).to have_received(:generate).twice
    end

    it "regenerates when stored style version differs from current" do
      allow(client).to receive(:generate).and_return(client_response)
      lens_cache.payload = lens_cache.payload.merge(
        "illustration_url" => "/academy/illustrations/test-rspec-pill.webp",
        "illustration_meta" => { "style" => "duolingo@v0-stale", "model" => "x", "generated_at" => "now" }
      )
      lens_cache.save!
      FileUtils.mkdir_p(described_class::OUTPUT_DIR)
      File.binwrite(output_path, "stale")

      result = described_class.call(lens_cache: lens_cache, client: client)
      expect(result.data[:skipped]).to be false
    end
  end

  describe "preconditions" do
    it "fails when API key is blank" do
      Academy.config.openrouter_api_key = ""
      result = described_class.call(lens_cache: lens_cache, client: client)
      expect(result.success?).to be false
      expect(result.error).to eq(:no_api_key)
      expect(File.exist?(output_path)).to be false
    end

    it "fails when illustration_hint is missing" do
      lens_cache.update!(payload: { "headline" => "no hint here" })
      result = described_class.call(lens_cache: lens_cache, client: client)
      expect(result.success?).to be false
      expect(result.error).to eq(:missing_hint)
      expect(File.exist?(output_path)).to be false
    end
  end

  describe "client error handling" do
    it "returns fail_with(:client_error) without leaving a partial file" do
      allow(client).to receive(:generate).and_raise(Academy::Illustrations::Client::Error, "boom")

      result = described_class.call(lens_cache: lens_cache, client: client)

      expect(result.success?).to be false
      expect(result.error).to eq(:client_error)
      expect(result.data[:message]).to eq("boom")
      expect(File.exist?(output_path)).to be false

      lens_cache.reload
      expect(lens_cache.payload["illustration_url"]).to be_nil
    end
  end
end

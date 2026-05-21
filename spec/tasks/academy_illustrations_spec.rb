# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "academy:illustrations:generate", type: :task do
  before(:all) do
    Rake.application.rake_require("tasks/academy_illustrations", [ Rails.root.join("lib").to_s ])
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task["academy:illustrations:generate"] }

  let(:tiny_png_bytes) do
    Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
    )
  end

  let!(:concept_a) { create(:academy_concept, slug: "test-pill-a", name: "Test Pill A") }
  let!(:concept_b) { create(:academy_concept, slug: "test-pill-b", name: "Test Pill B") }
  let!(:row_a) do
    Academy::LensCache.create!(
      concept: concept_a, lens_type: "scientific", age_band: "kid", locale: "pt-BR",
      source: "curated", generated_at: Time.current,
      payload: { "headline" => "A", "illustration_hint" => "scene A" }
    )
  end
  let!(:row_b) do
    Academy::LensCache.create!(
      concept: concept_b, lens_type: "scientific", age_band: "kid", locale: "pt-BR",
      source: "curated", generated_at: Time.current,
      payload: { "headline" => "B", "illustration_hint" => "scene B" }
    )
  end
  let!(:row_no_hint) do
    extra = create(:academy_concept, slug: "no-hint-concept", name: "No hint")
    Academy::LensCache.create!(
      concept: extra, lens_type: "scientific", age_band: "kid", locale: "pt-BR",
      source: "curated", generated_at: Time.current,
      payload: { "headline" => "no hint" }
    )
  end

  def output_path(slug) = Academy::Illustrations::Generate::OUTPUT_DIR.join("#{slug}.webp")

  before do
    task.reenable
    %w[test-pill-a test-pill-b].each { |s| FileUtils.rm_f(output_path(s)) }
    Academy.config.openrouter_api_key = "x" * 20
    ENV["FORCE"] = ENV["ONLY"] = ENV["DRY_RUN"] = ENV["MODEL"] = nil
  end

  after do
    %w[test-pill-a test-pill-b].each { |s| FileUtils.rm_f(output_path(s)) }
    Academy.config.openrouter_api_key = ""
    ENV["FORCE"] = ENV["ONLY"] = ENV["DRY_RUN"] = ENV["MODEL"] = nil
  end

  describe "DRY_RUN" do
    it "prints summary without writing files or calling client" do
      ENV["DRY_RUN"] = "1"
      ENV["ONLY"] = "test-pill-a,test-pill-b"

      expect(Academy::Illustrations::Generate).not_to receive(:call)
      expect { task.invoke }.to output(/DRY_RUN.*2 rows/m).to_stdout

      expect(File.exist?(output_path("test-pill-a"))).to be false
      expect(File.exist?(output_path("test-pill-b"))).to be false
    end

    it "is allowed even without API key" do
      Academy.config.openrouter_api_key = ""
      ENV["DRY_RUN"] = "1"
      ENV["ONLY"] = "test-pill-a"
      expect { task.invoke }.not_to raise_error
    end
  end

  describe "missing API key" do
    it "aborts when key is blank and not dry-run" do
      Academy.config.openrouter_api_key = ""
      ENV["ONLY"] = "test-pill-a"
      expect { task.invoke }.to raise_error(SystemExit).and output(/OPENROUTER_API_KEY ausente/).to_stderr
    end
  end

  describe "happy path" do
    it "invokes Generate for each matched row" do
      ENV["ONLY"] = "test-pill-a,test-pill-b"

      ok = ApplicationService::Result.new(
        success: true, error: nil,
        data: { skipped: false, slug: "x", url: "/academy/illustrations/x.webp", bytes_written: 100, model: "m" }
      )
      expect(Academy::Illustrations::Generate).to receive(:call).twice.and_return(ok)

      expect { task.invoke }.to output(/generated=2 skipped=0 failed=0/).to_stdout
    end

    it "continues past failures and tallies them" do
      ENV["ONLY"] = "test-pill-a,test-pill-b"

      ok = ApplicationService::Result.new(success: true, error: nil,
                                          data: { skipped: false, slug: "x", url: "/x", bytes_written: 1, model: "m" })
      bad = ApplicationService::Result.new(success: false, error: :client_error, data: { message: "boom" })
      allow(Academy::Illustrations::Generate).to receive(:call).and_return(ok, bad)

      expect { task.invoke }.to output(/generated=1 skipped=0 failed=1/).to_stdout
    end
  end

  describe "MODEL override" do
    it "sets Academy.config.image_model for the run" do
      ENV["DRY_RUN"] = "1"
      ENV["MODEL"] = "recraft/recraft-v4"
      ENV["ONLY"] = "test-pill-a"
      expect { task.invoke }.to change { Academy.config.image_model }.to("recraft/recraft-v4")
    end
  end
end

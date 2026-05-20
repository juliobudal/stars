# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Pills::PickDailyForLearner do
  let(:learner) do
    Academy::Learner.new(
      id: 42, display_name: "Theo", age_band: "kid", timezone: "UTC", interests: []
    )
  end

  let!(:curiosity_concept) do
    Academy::Concept.find_or_create_by!(slug: "pill-curiosity") do |c|
      c.name = "Curiosidade"
      c.category = "mundo_natural"
    end
  end

  let!(:meta_concept) do
    Academy::Concept.find_or_create_by!(slug: "pill-meta") do |c|
      c.name = "Meta"
      c.category = "cognitivo"
    end
  end

  let!(:curiosity_lens) do
    Academy::LensCache.create!(
      concept: curiosity_concept, lens_type: "scientific",
      age_band: "kid", locale: "pt-BR", source: "curated",
      payload: { headline: "Por que o céu é azul" }, generated_at: Time.current
    )
  end

  let!(:meta_lens) do
    Academy::LensCache.create!(
      concept: meta_concept, lens_type: "narrative",
      age_band: "kid", locale: "pt-BR", source: "curated",
      payload: { headline: "Foco" }, generated_at: Time.current
    )
  end

  it "returns a curated lens for the learner" do
    result = described_class.call(learner: learner)
    expect(result).to be_success
    expect(result.data[:lens_cache]).to be_present
    expect(result.data[:pill_view]).to be_persisted
  end

  it "prefers curiosity-of-the-world categories" do
    # Run a few times; the curiosity concept should be picked at least once.
    picks = 8.times.map do
      Academy::PillView.delete_all
      described_class.call(learner: learner).data[:lens_cache].concept.slug
    end
    expect(picks).to include("pill-curiosity")
  end

  it "is idempotent intra-day" do
    first  = described_class.call(learner: learner).data[:pill_view]
    second = described_class.call(learner: learner).data[:pill_view]
    expect(second.id).to eq(first.id)
  end

  it "fails with :no_pill_available when nothing curated exists" do
    Academy::LensCache.destroy_all
    result = described_class.call(learner: learner)
    expect(result).not_to be_success
    expect(result.error).to eq(:no_pill_available)
  end

  it "fails with :no_learner when learner is nil" do
    result = described_class.call(learner: nil)
    expect(result).not_to be_success
    expect(result.error).to eq(:no_learner)
  end
end

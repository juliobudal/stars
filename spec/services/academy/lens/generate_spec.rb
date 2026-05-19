# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::Generate do
  let(:concept) do
    create(:academy_concept, slug: "switch-cost-gen-#{SecureRandom.hex(3)}",
           name: "Custo da troca (spec)", definition: "Cada interrupção paga um pedágio.")
  end

  def curated_row(lens_type:, quality_flagged: false)
    Academy::LensCache.create!(
      concept_id: concept.id, lens_type: lens_type, age_band: "kid", locale: "pt-BR",
      source: "curated",
      payload: { "headline" => "x" * 30,
                 "mechanism_steps" => Array.new(3) { "y" * 40 },
                 "illustration_hint" => "z" * 60,
                 "micro_check" => { "question" => "?" * 30, "options" => %w[a b c],
                                    "correct_index" => 0, "rationale" => "r" * 50 } },
      generated_at: Time.current, quality_flagged: quality_flagged
    )
  end

  it "returns the curated row when one exists" do
    row = curated_row(lens_type: "scientific")
    result = described_class.call(concept: concept, lens_type: :scientific)
    expect(result).to be_success
    expect(result.data.id).to eq(row.id)
  end

  it "fails with :no_curated_payload when no curated row exists" do
    result = described_class.call(concept: concept, lens_type: :scientific)
    expect(result).not_to be_success
    expect(result.error).to eq(:no_curated_payload)
  end

  it "ignores quality_flagged curated rows" do
    curated_row(lens_type: "scientific", quality_flagged: true)
    result = described_class.call(concept: concept, lens_type: :scientific)
    expect(result).not_to be_success
    expect(result.error).to eq(:no_curated_payload)
  end

  it "is locale-scoped" do
    curated_row(lens_type: "scientific") # pt-BR
    result = described_class.call(concept: concept, lens_type: :scientific, locale: "en-US")
    expect(result).not_to be_success
  end

  it "accepts the retired generator:/force_refresh:/learner_id: kwargs as no-ops" do
    row = curated_row(lens_type: "scientific")
    result = described_class.call(
      concept: concept, lens_type: :scientific,
      generator: :ignored, force_refresh: true, learner_id: 42
    )
    expect(result).to be_success
    expect(result.data.id).to eq(row.id)
  end
end

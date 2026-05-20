# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::ResolveCuratedPayload do
  let(:concept) do
    Academy::Concept.find_or_create_by!(slug: "rcp-concept") do |c|
      c.name = "RCP"
      c.category = "cognitivo"
    end
  end

  let!(:default_row) do
    Academy::LensCache.create!(
      concept: concept, lens_type: "narrative", age_band: "kid", locale: "pt-BR",
      source: "curated", payload: { default: true }, generated_at: Time.current
    )
  end

  let(:learner_with_minecraft) do
    Academy::Learner.new(
      id: 1, display_name: "K", age_band: "kid", timezone: "UTC",
      interests: [ Academy::Interest.new(key: "minecraft", label: "Minecraft") ]
    )
  end

  context "when no interest variant exists" do
    it "returns the default row" do
      result = described_class.call(
        concept: concept, lens_type: :narrative, learner: learner_with_minecraft
      )
      expect(result).to be_success
      expect(result.data.id).to eq(default_row.id)
    end
  end

  context "when an interest variant matching the top interest exists" do
    let!(:variant_row) do
      Academy::LensCache.create!(
        concept: concept, lens_type: "narrative", age_band: "kid", locale: "pt-BR",
        source: "curated", payload: { variant: "minecraft" }, generated_at: Time.current,
        interest_key: "minecraft"
      )
    end

    it "prefers the interest variant over the default" do
      result = described_class.call(
        concept: concept, lens_type: :narrative, learner: learner_with_minecraft
      )
      expect(result).to be_success
      expect(result.data.id).to eq(variant_row.id)
      expect(result.data.payload).to eq("variant" => "minecraft")
    end

    it "falls back to default when the learner's top interest differs" do
      other_learner = Academy::Learner.new(
        id: 2, display_name: "K2", age_band: "kid", timezone: "UTC",
        interests: [ Academy::Interest.new(key: "futebol", label: "Futebol") ]
      )
      result = described_class.call(
        concept: concept, lens_type: :narrative, learner: other_learner
      )
      expect(result.data.id).to eq(default_row.id)
    end
  end

  context "when no curated row exists at all" do
    it "fails with :no_curated_payload" do
      Academy::LensCache.where(concept: concept).delete_all
      result = described_class.call(concept: concept, lens_type: :narrative, learner: nil)
      expect(result).not_to be_success
      expect(result.error).to eq(:no_curated_payload)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Mission do
  describe "validations" do
    describe "concept_must_have_curated_kid_payload" do
      let(:concept) { create(:academy_concept, slug: "no-content") }

      it "blocks publishing when the concept has no curated kid payload" do
        mission = build(:academy_mission, concept: concept,
                        with_curated_kid_payload: false, active: true)
        expect(mission).not_to be_valid
        expect(mission.errors[:concept]).to include(
          a_string_matching(/ainda não tem aula curada/)
        )
      end

      it "allows inactive missions even without curated coverage" do
        mission = build(:academy_mission, concept: concept,
                        with_curated_kid_payload: false, active: false)
        expect(mission).to be_valid
      end

      it "passes once a curated kid payload exists for the concept" do
        Academy::LensCache.create!(
          concept: concept, lens_type: "narrative", age_band: "kid", locale: "pt-BR",
          source: "curated", payload: { stub: true }, quality_flagged: false,
          generated_at: Time.current
        )
        mission = build(:academy_mission, concept: concept,
                        with_curated_kid_payload: false, active: true)
        expect(mission).to be_valid
      end

      it "ignores parent-locale payloads when evaluating kid coverage" do
        Academy::LensCache.create!(
          concept: concept, lens_type: "narrative", age_band: "parent", locale: "pt-BR",
          source: "curated", payload: { stub: true }, quality_flagged: false,
          generated_at: Time.current
        )
        mission = build(:academy_mission, concept: concept,
                        with_curated_kid_payload: false, active: true)
        expect(mission).not_to be_valid
      end

      it "ignores quality_flagged payloads" do
        Academy::LensCache.create!(
          concept: concept, lens_type: "narrative", age_band: "kid", locale: "pt-BR",
          source: "curated", payload: { stub: true }, quality_flagged: true,
          generated_at: Time.current
        )
        mission = build(:academy_mission, concept: concept,
                        with_curated_kid_payload: false, active: true)
        expect(mission).not_to be_valid
      end
    end
  end
end

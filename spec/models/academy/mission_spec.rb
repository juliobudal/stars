# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Mission do
  describe "validations" do
    describe "concept_must_have_curated_kid_payload (on: :publish)" do
      let(:concept) { create(:academy_concept, slug: "no-content") }

      it "blocks the :publish context when the concept has no curated kid payload" do
        mission = build(:academy_mission, concept: concept,
                        with_curated_kid_payload: false, active: true)
        expect(mission.valid?(:publish)).to be(false)
        expect(mission.errors[:concept]).to include(
          a_string_matching(/ainda não tem aula curada/)
        )
      end

      it "passes default save context even without curated coverage (seed-time path)" do
        # The seed loads missions BEFORE payloads; default save can't be
        # the enforcement point. The Academy audit at the end of db/seeds/
        # academy.rb runs :publish for every active mission.
        mission = build(:academy_mission, concept: concept,
                        with_curated_kid_payload: false, active: true)
        expect(mission).to be_valid
      end

      it "skips the check for inactive missions" do
        mission = build(:academy_mission, concept: concept,
                        with_curated_kid_payload: false, active: false)
        expect(mission.valid?(:publish)).to be(true)
      end

      it "passes once a curated kid payload exists for the concept" do
        Academy::LensCache.create!(
          concept: concept, lens_type: "narrative", age_band: "kid", locale: "pt-BR",
          source: "curated", payload: { stub: true }, quality_flagged: false,
          generated_at: Time.current
        )
        mission = build(:academy_mission, concept: concept,
                        with_curated_kid_payload: false, active: true)
        expect(mission.valid?(:publish)).to be(true)
      end

      it "ignores parent-locale payloads when evaluating kid coverage" do
        Academy::LensCache.create!(
          concept: concept, lens_type: "narrative", age_band: "parent", locale: "pt-BR",
          source: "curated", payload: { stub: true }, quality_flagged: false,
          generated_at: Time.current
        )
        mission = build(:academy_mission, concept: concept,
                        with_curated_kid_payload: false, active: true)
        expect(mission.valid?(:publish)).to be(false)
      end

      it "ignores quality_flagged payloads" do
        Academy::LensCache.create!(
          concept: concept, lens_type: "narrative", age_band: "kid", locale: "pt-BR",
          source: "curated", payload: { stub: true }, quality_flagged: true,
          generated_at: Time.current
        )
        mission = build(:academy_mission, concept: concept,
                        with_curated_kid_payload: false, active: true)
        expect(mission.valid?(:publish)).to be(false)
      end
    end
  end
end

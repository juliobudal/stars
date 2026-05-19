# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::WarmCacheJob do
  let(:learner_id) { 555 }
  let(:subject_) { create(:academy_subject) }
  let(:concept) { create(:academy_concept, slug: "warm-concept", category: "cognitivo") }
  let(:mission) { create(:academy_mission, subject: subject_, concept: concept, slug: "warm-mission") }

  before do
    Academy::MissionProgress.create!(
      learner_id: learner_id, mission: mission, status: :in_progress,
      started_at: 1.day.ago, updated_at: 1.day.ago
    )
    allow(Academy).to receive(:configured?).and_return(true)
  end

  context "when no compass plan is available" do
    it "no-ops" do
      allow(Academy::Compass::Propose).to receive(:call).and_return(
        instance_double(Academy::ApplicationService::Result, success?: false)
      )

      report = described_class.new.perform(max_llm_calls: 10)
      expect(report).to eq(lenses_warmed: 0, llm_calls_made: 0)
    end
  end

  context "when cache is already warm" do
    it "performs zero LLM calls (REQ-LGEN-008 cache-warm short-circuit)" do
      Academy::Lens::Catalog.types.each do |lens_type|
        entry = Academy::Lens::Catalog.fetch(lens_type)
        Academy::LensCache.create!(
          concept_id: concept.id, lens_type: lens_type.to_s,
          age_band: "kid", locale: "pt-BR",
          template_version: entry.template_version,
          payload: { "headline" => "cached" },
          generated_at: Time.current
        )
      end

      card = double(mission: mission)
      plan = double(cards: [ card ])
      allow(Academy::Compass::Propose).to receive(:call).and_return(
        double(success?: true, data: plan)
      )
      expect(Academy::Lens::Generate).not_to receive(:call)

      report = described_class.new.perform(max_llm_calls: 50)
      expect(report[:llm_calls_made]).to eq(0)
    end
  end

  context "when budget is zero" do
    it "skips immediately" do
      expect(Academy::Compass::Propose).not_to receive(:call)
      report = described_class.new.perform(max_llm_calls: 0)
      expect(report).to eq(lenses_warmed: 0, llm_calls_made: 0)
    end
  end
end

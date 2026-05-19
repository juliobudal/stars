# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::PrewarmNextJob do
  let(:learner_id) { 777 }
  let(:subject_) { create(:academy_subject) }
  let(:concept) { create(:academy_concept, slug: "prewarm-concept", category: "cognitivo") }
  let(:mission) { create(:academy_mission, subject: subject_, concept: concept, slug: "prewarm-mission") }
  let(:progress) do
    Academy::MissionProgress.create!(
      learner_id: learner_id, mission: mission, status: :in_progress, started_at: Time.current
    )
  end

  before { allow(Academy).to receive(:configured?).and_return(true) }

  context "when module is not configured" do
    it "no-ops without touching Generate" do
      allow(Academy).to receive(:configured?).and_return(false)
      expect(Academy::Lens::Generate).not_to receive(:call)
      described_class.new.perform(mission_progress_id: progress.id)
    end
  end

  context "when progress does not exist" do
    it "no-ops silently" do
      expect(Academy::Lens::Generate).not_to receive(:call)
      described_class.new.perform(mission_progress_id: -1)
    end
  end

  context "with a fresh progress (no visits)" do
    it "pre-generates the first MAX_CANDIDATES from the rotation" do
      received = []
      allow(Academy::Lens::Generate).to receive(:call) do |concept:, lens_type:, learner_id: nil|
        received << lens_type
        instance_double(Academy::ApplicationService::Result, success?: true)
      end

      described_class.new.perform(mission_progress_id: progress.id)

      expect(received.size).to eq(described_class::MAX_CANDIDATES)
      expected_head = (Academy::Lens::ChooseNext::CONCRETE_OPENERS +
                       Academy::Lens::ChooseNext::ABSTRACT_LENSES +
                       Academy::Lens::ChooseNext::CLOSURE_LENSES)
                        .uniq.first(described_class::MAX_CANDIDATES)
      expect(received).to eq(expected_head)
    end
  end

  context "when some types have been visited" do
    it "skips visited types and the current open type" do
      [ :narrative, :first_person ].each_with_index do |lens_type, idx|
        Academy::LearnerLensVisit.create!(
          mission_progress: progress, learner_id: learner_id, concept_id: concept.id,
          lens_type: lens_type.to_s, ordering_position: idx + 1,
          opened_at: Time.current, closed_at: Time.current
        )
      end
      # Current open visit (last in ordering) should also be excluded.
      Academy::LearnerLensVisit.create!(
        mission_progress: progress, learner_id: learner_id, concept_id: concept.id,
        lens_type: "scientific", ordering_position: 3, opened_at: Time.current
      )

      received = []
      allow(Academy::Lens::Generate).to receive(:call) do |concept:, lens_type:, learner_id: nil|
        received << lens_type
        instance_double(Academy::ApplicationService::Result, success?: true)
      end

      described_class.new.perform(mission_progress_id: progress.id)

      expect(received).not_to include(:narrative, :first_person, :scientific)
      expect(received.size).to be <= described_class::MAX_CANDIDATES
    end
  end

  context "when Generate fails" do
    it "logs and continues without raising" do
      allow(Academy::Lens::Generate).to receive(:call).and_return(
        instance_double(Academy::ApplicationService::Result, success?: false, error: :llm_transport_error)
      )
      expect(Rails.logger).to receive(:warn).at_least(:once)
      expect { described_class.new.perform(mission_progress_id: progress.id) }.not_to raise_error
    end
  end
end

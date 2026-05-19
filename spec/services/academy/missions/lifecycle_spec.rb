# frozen_string_literal: true

require "rails_helper"

# Integration spec for Mission::{Begin, AdvanceLens, Finalize}. Drives a
# synthetic learner through a complete journey with stubbed Lens::Generate
# so the test doesn't depend on actual curated seed data.
RSpec.describe "Mission lifecycle (v5)" do
  let(:concept) { create(:academy_concept, slug: "mlc-c", name: "MLCC") }
  let(:subject_) { create(:academy_subject) }
  let(:mission)  { create(:academy_mission, subject: subject_, concept: concept) }
  let(:learner)  { Academy::Learner.new(id: 7, display_name: "Lia", age_band: "kid") }

  # Pre-seed all 8 lens types as curated rows so ChooseNext sees full
  # coverage from the start. Without this, the curated_types_for set
  # would grow mid-loop and bias rotation in unrealistic ways.
  before do
    Academy::Lens::Catalog.types.each do |lens_type|
      Academy::LensCache.find_or_create_by!(
        concept_id: concept.id, lens_type: lens_type.to_s,
        age_band: "kid", locale: "pt-BR"
      ) do |r|
        r.source = "curated"
        r.payload = { "stub" => true, "lens" => lens_type.to_s }
        r.generated_at = Time.current
      end
    end

    # Lens::Generate now resolves to the pre-seeded curated row.
    allow(Academy::Lens::Generate).to receive(:call) do |kwargs|
      lens_type = kwargs[:lens_type].to_s
      row = Academy::LensCache.curated.find_by!(
        concept_id: concept.id, lens_type: lens_type, age_band: "kid", locale: "pt-BR"
      )
      Academy::ApplicationService::Result.new(success: true, error: nil, data: row)
    end
  end

  describe Academy::Missions::Begin do
    it "creates a progress + first open visit + cache" do
      result = described_class.call(learner: learner, mission: mission)
      expect(result.success?).to be true
      stage = result.data
      expect(stage.progress).to be_in_progress
      expect(stage.visit.closed_at).to be_nil
      expect(stage.lens_cache).to be_present
      expect(Academy::Lens::ChooseNext::CONCRETE_OPENERS).to include(stage.visit.lens_type.to_sym)
    end

    it "is idempotent — second call returns the same open visit" do
      first = described_class.call(learner: learner, mission: mission)
      second = described_class.call(learner: learner, mission: mission)
      expect(second.data.visit.id).to eq(first.data.visit.id)
    end
  end

  describe Academy::Missions::AdvanceLens do
    it "closes the open visit, opens the next, and never repeats the lens type" do
      stage = Academy::Missions::Begin.call(learner: learner, mission: mission).data
      first_type = stage.visit.lens_type

      result = described_class.call(progress: stage.progress, signal_payload: { "micro_check_correct" => true })
      expect(result.success?).to be true
      next_stage = result.data
      expect(next_stage.mission_complete?).to be false
      expect(next_stage.visit.lens_type).not_to eq(first_type)
    end

    it "drives the mission to completion within HARD_CAP visits" do
      stage = Academy::Missions::Begin.call(learner: learner, mission: mission).data

      visited_types = [ stage.visit.lens_type.to_sym ]
      attempts = 0
      loop do
        result = described_class.call(progress: stage.progress, signal_payload: { "micro_check_correct" => true })
        attempts += 1
        break if result.data.mission_complete? || attempts > 8
        visited_types << result.data.visit.lens_type.to_sym
      end

      expect(attempts).to be <= Academy::Lens::ChooseNext::HARD_CAP
      expect(stage.progress.reload).to be_completed
      expect(visited_types.uniq.size).to be >= Academy::Lens::ChooseNext::COVERAGE_FLOOR
      expect(visited_types.last).to satisfy { |t|
        Academy::Lens::ChooseNext::CLOSURE_LENSES.include?(t)
      }
    end
  end

  describe Academy::Missions::Finalize do
    it "marks the progress completed and chains the post-mission services" do
      progress = Academy::MissionProgress.create!(
        learner_id: learner.id, mission: mission, status: :in_progress,
        started_at: Time.current
      )

      expect(Academy::Cards::MintAfterMission).to receive(:call).with(progress: progress).and_call_original
      expect(Academy::Pokedex::Advance).to receive(:call).with(hash_including(concept: concept, trigger: :mission_completed)).and_call_original
      # Signals::Record fires :mission_completed from Finalize AND may fire
      # :concept_evolved from Pokedex::Advance. Use a flexible expectation.
      mission_completed_seen = false
      allow(Academy::Signals::Record).to receive(:call) do |args|
        mission_completed_seen = true if args[:event] == :mission_completed
        Academy::ApplicationService::Result.new(success: true, error: nil, data: nil)
      end

      result = described_class.call(progress: progress)
      expect(result.success?).to be true
      expect(progress.reload).to be_completed
      expect(mission_completed_seen).to be(true), "expected Signals::Record to receive :mission_completed"
    end

    it "refuses to finalize an already-completed progress" do
      progress = Academy::MissionProgress.create!(
        learner_id: learner.id, mission: mission, status: :completed,
        started_at: 1.hour.ago, completed_at: Time.current
      )
      result = described_class.call(progress: progress)
      expect(result.success?).to be false
    end
  end
end

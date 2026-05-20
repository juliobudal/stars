# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::ChooseNext do
  let(:concept) { create(:academy_concept, slug: "dop-cn") }
  let(:mission) { create(:academy_mission, concept: concept) }
  let(:progress) do
    Academy::MissionProgress.create!(
      learner_id: 33, mission: mission, status: :in_progress, started_at: Time.current
    )
  end

  def add_visit(lens_type, position, signals: {})
    Academy::LearnerLensVisit.create!(
      mission_progress: progress,
      learner_id: 33,
      concept_id: concept.id,
      lens_type: lens_type.to_s,
      ordering_position: position,
      opened_at: position.minutes.ago,
      closed_at: (position - 1).minutes.ago,
      outcome: "completed",
      signal_payload: signals
    )
  end

  describe "opener" do
    it "picks a concrete opener when no visits exist" do
      result = described_class.call(mission_progress: progress)
      decision = result.data
      expect(decision.done).to be false
      expect(described_class::CONCRETE_OPENERS).to include(decision.next_lens)
    end
  end

  describe "variety rule" do
    it "never picks the same type as the last visit" do
      add_visit(:narrative, 1)
      result = described_class.call(mission_progress: progress)
      expect(result.data.next_lens).not_to eq(:narrative)
    end
  end

  describe "closure conditions" do
    it "does not close before COVERAGE_FLOOR distinct types" do
      add_visit(:narrative, 1)
      add_visit(:first_person, 2)
      add_visit(:analogy_bridge, 3) # closure type, but only 3 distinct
      result = described_class.call(mission_progress: progress)
      expect(result.data.done).to be false
    end

    it "closes when ≥4 distinct types AND last visit is closure-type" do
      add_visit(:narrative, 1)
      add_visit(:first_person, 2)
      add_visit(:scientific, 3)
      add_visit(:analogy_bridge, 4)
      result = described_class.call(mission_progress: progress)
      expect(result.data.done).to be true
      expect(result.data.reason).to eq(:closed_with_transfer)
    end

    it "biases to a closure lens once coverage floor is hit without one yet" do
      add_visit(:narrative, 1)
      add_visit(:first_person, 2)
      add_visit(:scientific, 3)
      add_visit(:historical, 4) # 4 distinct, none closure
      result = described_class.call(mission_progress: progress)
      expect(described_class::CLOSURE_LENSES).to include(result.data.next_lens)
    end
  end

  describe "hard cap" do
    it "force-closes with a closure lens when cap reached without transfer" do
      %i[narrative first_person scientific historical engineering statistical scientific].each_with_index do |t, i|
        add_visit(t, i + 1)
      end
      result = described_class.call(mission_progress: progress)
      expect(result.data.forced_close).to be true
      expect(described_class::CLOSURE_LENSES).to include(result.data.next_lens)
    end

    it "closes cleanly when cap reached and closure lens already visited" do
      %i[narrative first_person scientific historical analogy_bridge engineering statistical].each_with_index do |t, i|
        add_visit(t, i + 1)
      end
      result = described_class.call(mission_progress: progress)
      expect(result.data.done).to be true
      expect(result.data.reason).to eq(:cap_reached_with_transfer)
    end
  end

  describe "curated set without closure lens" do
    # Concept ships only narrative/scientific/statistical curated payloads
    # (no analogy_bridge/ethical). The chooser must close cleanly once all
    # three are visited instead of looping to HARD_CAP and 503ing.
    let(:curated_types) { %i[narrative scientific statistical] }

    before do
      curated_types.each do |t|
        Academy::LensCache.create!(
          concept: concept, lens_type: t, age_band: "kid", locale: "pt-BR",
          source: "curated", payload: { stub: true }, quality_flagged: false,
          generated_at: Time.current
        )
      end
    end

    it "closes with curated_coverage_complete after every curated type is visited" do
      curated_types.each_with_index { |t, i| add_visit(t, i + 1) }
      result = described_class.call(mission_progress: progress)
      expect(result.data.done).to be true
      expect(result.data.reason).to eq(:curated_coverage_complete)
    end

    it "keeps cycling within the curated set until coverage is complete" do
      add_visit(:narrative, 1)
      result = described_class.call(mission_progress: progress)
      expect(curated_types).to include(result.data.next_lens)
      expect(result.data.next_lens).not_to eq(:narrative)
      expect(result.data.done).to be false
    end
  end

  describe "adaptive: wrong-streak biases towards re-anchor" do
    it "prefers a concrete lens after 2 wrong micro_checks" do
      add_visit(:scientific, 1)
      add_visit(:statistical, 2)

      [ 1, 2 ].each do |position|
        Academy::LensSignal.create!(
          mission_progress_id: progress.id,
          learner_id: 33, concept_id: concept.id,
          lens_type: "statistical", signal_type: "micro_check_wrong",
          numeric_value: 1, recorded_at: position.minutes.ago
        )
      end

      result = described_class.call(mission_progress: progress)
      expect(described_class::CONCRETE_OPENERS).to include(result.data.next_lens)
    end
  end
end

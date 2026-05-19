# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::ScoreVisit do
  let(:concept) { create(:academy_concept, slug: "score-c") }
  let(:mission) { create(:academy_mission, concept: concept) }
  let(:progress) do
    Academy::MissionProgress.create!(
      learner_id: 9, mission: mission, status: :in_progress, started_at: Time.current
    )
  end

  def closed_visit(payload:, opened_ago: 90, closed_ago: 30, outcome: "completed")
    Academy::LearnerLensVisit.create!(
      mission_progress: progress, learner_id: 9, concept_id: concept.id,
      lens_type: "scientific", ordering_position: 1,
      opened_at: opened_ago.seconds.ago, closed_at: closed_ago.seconds.ago,
      outcome: outcome, signal_payload: payload
    )
  end

  it "fails on still-open visits" do
    open = Academy::LearnerLensVisit.create!(
      mission_progress: progress, learner_id: 9, concept_id: concept.id,
      lens_type: "scientific", ordering_position: 1, opened_at: 10.seconds.ago
    )
    result = described_class.call(visit: open)
    expect(result.success?).to be false
    expect(result.error).to eq(:visit_still_open)
  end

  it "emits time_on_lens always" do
    visit = closed_visit(payload: {})
    described_class.call(visit: visit)
    signals = Academy::LensSignal.where(lens_visit_id: visit.id)
    expect(signals.map(&:signal_type)).to include("time_on_lens")
    time_sig = signals.find_by(signal_type: "time_on_lens")
    expect(time_sig.numeric_value).to be_within(5).of(60)
  end

  it "emits micro_check_correct when payload signals correctness" do
    visit = closed_visit(payload: { "micro_check_correct" => true })
    described_class.call(visit: visit)
    types = Academy::LensSignal.where(lens_visit_id: visit.id).pluck(:signal_type)
    expect(types).to include("micro_check_correct")
    expect(types).not_to include("micro_check_wrong")
  end

  it "emits micro_check_wrong when payload signals incorrectness" do
    visit = closed_visit(payload: { "micro_check_correct" => false })
    described_class.call(visit: visit)
    types = Academy::LensSignal.where(lens_visit_id: visit.id).pluck(:signal_type)
    expect(types).to include("micro_check_wrong")
  end

  it "emits abandoned when outcome is abandoned" do
    visit = closed_visit(payload: {}, outcome: "abandoned")
    described_class.call(visit: visit)
    types = Academy::LensSignal.where(lens_visit_id: visit.id).pluck(:signal_type)
    expect(types).to include("abandoned")
  end

  it "emits self_report_hard when affective_tap is hard" do
    visit = closed_visit(payload: { "affective_tap" => "hard" })
    described_class.call(visit: visit)
    types = Academy::LensSignal.where(lens_visit_id: visit.id).pluck(:signal_type)
    expect(types).to include("self_report_hard")
  end
end

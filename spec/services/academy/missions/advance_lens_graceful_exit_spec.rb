# frozen_string_literal: true

require "rails_helper"

# AdvanceLens used to fail with :lens_generation_failed when every
# candidate lens type came back empty (concept's curated rows all
# quality_flagged, LLM transport down, etc), which the controller then
# rendered as a 503. The kid hit the "VOLTA EM INSTANTES" placeholder
# without any indication the mission was actually unservable.
#
# Current behavior: record a `curated_gap_hit` LensSignal for ops/parent
# visibility, finalize the mission, and return mission_complete=true so
# the controller routes to the regular completion screen.
RSpec.describe Academy::Missions::AdvanceLens, "graceful exit when generation fails" do
  let(:learner_id) { 7777 }
  let(:concept) { create(:academy_concept, slug: "ge-concept") }
  let(:mission) { create(:academy_mission, concept: concept, slug: "ge-mission") }
  let(:progress) do
    Academy::MissionProgress.create!(
      learner_id: learner_id, mission: mission, status: :in_progress, started_at: Time.current
    )
  end

  let!(:open_visit) do
    cache = Academy::LensCache.find_or_create_by!(
      concept: concept, lens_type: "narrative", age_band: "kid", locale: "pt-BR"
    ) do |r|
      r.source = "curated"
      r.payload = { stub: true }
      r.generated_at = Time.current
    end
    Academy::LearnerLensVisit.create!(
      mission_progress: progress, learner_id: learner_id, concept_id: concept.id,
      lens_type: "narrative", lens_cache: cache, ordering_position: 1,
      opened_at: 1.minute.ago
    )
  end

  before do
    decision = Academy::Lens::ChooseNext::Decision.new(
      done: false, next_lens: :scientific, forced_close: false,
      reason: :adaptive, version: "stub"
    )
    allow(Academy::Lens::ChooseNext).to receive(:call).and_return(
      Academy::ApplicationService::Result.new(success: true, error: nil, data: decision)
    )
    allow(Academy::Lens::Generate).to receive(:call).and_return(
      Academy::ApplicationService::Result.new(success: false, error: :no_curated_payload, data: nil)
    )
  end

  it "finalizes the mission instead of failing when no candidate generates" do
    result = described_class.call(progress: progress)

    expect(result.success?).to be true
    expect(result.data.mission_complete?).to be true
    expect(progress.reload).to be_completed
  end

  it "records a curated_gap_hit LensSignal for the preferred lens" do
    expect {
      described_class.call(progress: progress)
    }.to change { Academy::LensSignal.where(signal_type: "curated_gap_hit", mission_progress_id: progress.id).count }.by(1)

    signal = Academy::LensSignal.find_by!(signal_type: "curated_gap_hit", mission_progress_id: progress.id)
    expect(signal.lens_type).to eq("scientific")
    expect(signal.concept_id).to eq(concept.id)
  end

  it "still closes the open visit so the ledger stays consistent" do
    described_class.call(progress: progress)
    expect(open_visit.reload.closed_at).to be_present
  end
end

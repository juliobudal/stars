# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Digests::Compose do
  let(:learner_id) { 101 }
  let(:parent_id)  { 999 }

  let(:concept) { create(:academy_concept) }

  # Anchor "now" mid-week so relative times (2.days.ago, 1.day.ago) consistently
  # fall inside Date.current.beginning_of_week(:monday)..next_week regardless
  # of the actual weekday the suite runs.
  around do |ex|
    travel_to(Time.zone.local(2026, 5, 20, 12, 0, 0)) { ex.run } # Wednesday
  end

  before do
    # 2 transfers + 1 mission completion in the past 7 days
    other_concept = create(:academy_concept)
    # v5: 1:1 mission↔concept. The digest spec only needs activity to exist;
    # cross-concept linkage now lives on TransferDetection rows.
    other_mission = create(:academy_mission, concept: other_concept)

    Academy::MissionProgress.create!(
      learner_id: learner_id, mission: other_mission, status: :completed,
      started_at: 3.days.ago, completed_at: 2.days.ago
    )

    msg = create(:academy_message,
                 session: create(:academy_session,
                                 mission_progress: Academy::MissionProgress.last))
    create(:academy_transfer_detection,
           learner_id: learner_id, from_concept: concept, to_concept: other_concept,
           message: msg, confidence: 0.85, detected_at: 1.day.ago)
  end

  it "composes a digest with all 4 blocks (fallback when LLM not configured)" do
    # Stub Academy.configured? to false to exercise fallback path
    allow(::Academy).to receive(:configured?).and_return(false)

    result = described_class.call(learner_id: learner_id, parent_id: parent_id)
    expect(result.success?).to be true
    digest = result.data
    expect(digest).to be_a(Academy::ParentDigest)
    expect(digest.payload.keys).to match_array(Academy::ParentDigest::PAYLOAD_BLOCKS)
  end

  it "is idempotent per (learner, week_starting)" do
    allow(::Academy).to receive(:configured?).and_return(false)
    described_class.call(learner_id: learner_id, parent_id: parent_id)
    described_class.call(learner_id: learner_id, parent_id: parent_id)

    expect(Academy::ParentDigest.where(learner_id: learner_id).count).to eq(1)
  end

  it "returns ok(nil) when there is no activity" do
    # Probe a fresh learner_id with no activity at all.
    result = described_class.call(learner_id: 999_999, parent_id: parent_id)
    expect(result.data).to be_nil
  end
end

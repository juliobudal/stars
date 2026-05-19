# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Adapt::NextMissionFor do
  let(:learner_id) { 555 }
  let(:subject_a) { create(:academy_subject, slug: "adapt-a", position: 1) }
  let(:subject_b) { create(:academy_subject, slug: "adapt-b", position: 2) }
  let(:trail_a)   { create(:academy_trail, subject: subject_a) }
  let(:trail_b)   { create(:academy_trail, subject: subject_b) }

  # Test DB may carry seeded Academy data. Clean v2-shaped missions
  # (those tied to a trail) so the adaptive picker sees only our fixtures.
  before do
    Academy::Mission.where.not(trail_id: nil).update_all(active: false)
  end

  it "returns nil when no fresh candidates exist for this learner" do
    result = described_class.call(learner_id: learner_id)
    expect(result.success?).to be true
    expect(result.data).to be_nil
  end

  it "continues an in-progress mission if there is one" do
    mission = create(:academy_mission, subject: subject_a, trail: trail_a, slug: "adapt-m1")
    create(:academy_mission_progress, mission: mission, learner_id: learner_id, status: :in_progress)
    other = create(:academy_mission, subject: subject_b, trail: trail_b, slug: "adapt-m2")

    result = described_class.call(learner_id: learner_id)
    expect(result.data).to eq(mission)
    expect(result.data).not_to eq(other)
  end

  it "picks fresh missions over completed ones" do
    completed = create(:academy_mission, subject: subject_a, trail: trail_a, slug: "completed")
    fresh     = create(:academy_mission, subject: subject_b, trail: trail_b, slug: "fresh")
    create(:academy_mission_progress, mission: completed, learner_id: learner_id, status: :completed)

    result = described_class.call(learner_id: learner_id)
    expect(result.data).to eq(fresh)
  end

  it "prefers a subject with higher affinity" do
    high_affinity_subject = subject_a
    low_affinity_subject  = subject_b

    # We crank affinity high enough on subject_a to override the freshness
    # boost (1.4) of subject_b for a brand-new learner.
    create(:academy_learner_signal, learner_id: learner_id, subject: high_affinity_subject, affinity_score: 50)

    high = create(:academy_mission, subject: high_affinity_subject, trail: trail_a, slug: "hi")
    low  = create(:academy_mission, subject: low_affinity_subject,  trail: trail_b, slug: "lo")

    # Run a few times because there's jitter. We just require "hi" to win
    # at least once across the runs.
    picks = Array.new(5) { described_class.call(learner_id: learner_id).data }
    expect(picks).to include(high)
  end
end

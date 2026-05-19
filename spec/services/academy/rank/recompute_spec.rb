# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Rank::Recompute do
  let(:learner_id) { 999 }
  let(:subject_a) { create(:academy_subject, slug: "area-a", position: 1) }
  let(:subject_b) { create(:academy_subject, slug: "area-b", position: 2) }

  it "stays aprendiz when no cards" do
    record = described_class.call(learner_id: learner_id).data
    expect(record.rank).to eq("aprendiz")
  end

  it "becomes explorador with 5 cards spread across 2 subjects" do
    3.times do |i|
      mission = create(:academy_mission, subject: subject_a, slug: "m-a-#{i}")
      create(:academy_discovery_card, mission: mission, learner_id: learner_id)
    end
    2.times do |i|
      mission = create(:academy_mission, subject: subject_b, slug: "m-b-#{i}")
      create(:academy_discovery_card, mission: mission, learner_id: learner_id)
    end

    record = described_class.call(learner_id: learner_id).data
    expect(record.rank).to eq("explorador")
  end

  it "is idempotent — re-running keeps a single row" do
    described_class.call(learner_id: learner_id)
    described_class.call(learner_id: learner_id)
    expect(Academy::LearnerRank.where(learner_id: learner_id).count).to eq(1)
  end
end

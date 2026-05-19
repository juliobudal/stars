# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Signals::Record do
  let(:subject_a) { create(:academy_subject, slug: "sig-a") }
  let(:mission)   { create(:academy_mission, subject: subject_a, slug: "sig-m") }
  let(:learner_id) { 777 }

  it "creates a new row on first signal" do
    described_class.call(learner_id: learner_id, mission: mission, event: :mission_completed)
    row = Academy::LearnerSignal.find_by(learner_id: learner_id, subject_id: subject_a.id)
    expect(row.affinity_score).to eq(5)
    expect(row.completion_count).to eq(1)
    expect(row.last_session_at).to be_present
  end

  it "increments existing row on subsequent signals" do
    described_class.call(learner_id: learner_id, mission: mission, event: :checkpoint_correct)
    described_class.call(learner_id: learner_id, mission: mission, event: :checkpoint_correct)
    described_class.call(learner_id: learner_id, mission: mission, event: :checkpoint_wrong)
    row = Academy::LearnerSignal.find_by(learner_id: learner_id, subject_id: subject_a.id)
    expect(row.affinity_score).to eq(2)
    expect(row.correct_checkpoints).to eq(2)
    expect(row.wrong_checkpoints).to eq(1)
  end

  it "rejects unknown events" do
    result = described_class.call(learner_id: learner_id, mission: mission, event: :nope)
    expect(result.success?).to be false
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Secrets::EvaluateForLearner do
  let(:learner_id) { 808 }
  let(:subject) { create(:academy_subject, slug: "mente-area") }

  let!(:secret) do
    create(:academy_secret,
           slug: "test-secret",
           kind: :cards_in_subject,
           rule: { "subject_slug" => "mente-area", "threshold" => 2 })
  end

  it "unlocks a secret when the rule is satisfied" do
    2.times do |i|
      mission = create(:academy_mission, subject: subject, slug: "m-#{i}")
      create(:academy_discovery_card, mission: mission, learner_id: learner_id)
    end

    result = described_class.call(learner_id: learner_id)
    expect(result.success?).to be true
    expect(result.data.size).to eq(1)
    expect(Academy::SecretUnlock.where(learner_id: learner_id, secret_id: secret.id)).to exist
  end

  it "is idempotent — re-running doesn't create duplicates" do
    2.times do |i|
      mission = create(:academy_mission, subject: subject, slug: "m-#{i}")
      create(:academy_discovery_card, mission: mission, learner_id: learner_id)
    end
    described_class.call(learner_id: learner_id)
    described_class.call(learner_id: learner_id)
    expect(Academy::SecretUnlock.where(learner_id: learner_id).count).to eq(1)
  end

  it "does not unlock when below threshold" do
    mission = create(:academy_mission, subject: subject, slug: "only-one")
    create(:academy_discovery_card, mission: mission, learner_id: learner_id)
    described_class.call(learner_id: learner_id)
    expect(Academy::SecretUnlock.where(learner_id: learner_id)).to be_empty
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Cards::MintAfterMission do
  let(:subject_) { create(:academy_subject, icon: "sparkle") }
  let(:concept)  { create(:academy_concept, slug: "card-mint-c") }
  let(:mission) do
    create(:academy_mission, subject: subject_, concept: concept,
           central_insight: "se X, então Y", learning_objective: "objetivo",
           illustration_key: "lamp")
  end

  def make_progress(status)
    Academy::MissionProgress.create!(
      learner_id: 99, mission: mission, status: status,
      started_at: 1.hour.ago, completed_at: (status == :completed ? Time.current : nil)
    )
  end

  it "creates a DiscoveryCard from mission.central_insight when no session summary exists" do
    progress = make_progress(:completed)

    expect {
      described_class.call(progress: progress)
    }.to change { Academy::DiscoveryCard.where(learner_id: 99, mission_id: mission.id).count }.from(0).to(1)

    card = Academy::DiscoveryCard.find_by!(learner_id: 99, mission_id: mission.id)
    expect(card.headline).to eq("se X, então Y")
    expect(card.illustration_key).to eq("lamp")
    expect(card.application).to eq("objetivo")
    expect(card.minted_at).to be_present
  end

  it "is idempotent — second call returns the existing card without duplication" do
    progress = make_progress(:completed)
    first = described_class.call(progress: progress)
    expect {
      described_class.call(progress: progress)
    }.not_to change { Academy::DiscoveryCard.where(learner_id: 99, mission_id: mission.id).count }
    expect(described_class.call(progress: progress).data.id).to eq(first.data.id)
  end

  it "refuses to mint when the mission is not finalized" do
    progress = make_progress(:in_progress)
    result = described_class.call(progress: progress)
    expect(result.success?).to be false
    expect(Academy::DiscoveryCard.where(learner_id: 99, mission_id: mission.id)).to be_empty
  end

  it "is invoked by Missions::Finalize and produces a real card row" do
    progress = Academy::MissionProgress.create!(
      learner_id: 99, mission: mission, status: :in_progress, started_at: 1.hour.ago
    )
    expect {
      Academy::Missions::Finalize.call(progress: progress)
    }.to change { Academy::DiscoveryCard.where(learner_id: 99, mission_id: mission.id).count }.from(0).to(1)
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Connections::ForMission do
  let(:subject_a) { create(:academy_subject, slug: "area-a", position: 1) }
  let(:subject_b) { create(:academy_subject, slug: "area-b", position: 2) }

  let(:dopamine)  { create(:academy_concept, slug: "test-dop-#{SecureRandom.hex(3)}", name: "Dopamina") }
  let(:focus)     { create(:academy_concept, slug: "test-foc-#{SecureRandom.hex(3)}", name: "Foco") }

  # v5: 1:1 mission↔concept — "related" = other missions tagged with same concept.
  let(:source) { create(:academy_mission, subject: subject_a, slug: "source-mission", concept: dopamine) }
  let(:same_area)  { create(:academy_mission, subject: subject_a, slug: "same-area",  concept: dopamine) }
  let(:cross_area) { create(:academy_mission, subject: subject_b, slug: "cross-area", concept: dopamine) }
  let(:no_shared)  { create(:academy_mission, subject: subject_a, slug: "no-shared",  concept: focus) }

  before do
    same_area
    cross_area
    no_shared
  end

  it "returns related missions ranked by score" do
    result = described_class.call(mission: source)
    expect(result.success?).to be true

    connections = result.data
    expect(connections.size).to eq(2)
    expect(connections.map(&:mission)).to contain_exactly(same_area, cross_area)

    # Cross-area gets cross-subject bonus → should rank first.
    expect(connections.first.mission).to eq(cross_area)
    expect(connections.first.same_subject).to be false
  end

  it "ignores the source mission itself" do
    result = described_class.call(mission: source)
    expect(result.data.map(&:mission)).not_to include(source)
  end

  it "returns empty when no other mission shares the concept" do
    lonely_concept = create(:academy_concept, slug: "lonely-concept")
    bare = create(:academy_mission, subject: subject_a, slug: "bare", concept: lonely_concept)
    result = described_class.call(mission: bare)
    expect(result.success?).to be true
    expect(result.data).to eq([])
  end

  it "marks has_card when learner has a DiscoveryCard for the related mission" do
    learner_id = 42
    Academy::DiscoveryCard.create!(
      learner_id: learner_id,
      mission_id: cross_area.id,
      headline: "x",
      minted_at: Time.current
    )

    result = described_class.call(mission: source, learner_id: learner_id)
    cross = result.data.find { |c| c.mission == cross_area }
    same  = result.data.find { |c| c.mission == same_area }
    expect(cross.has_card).to be true
    expect(same.has_card).to be false
  end

  it "respects the limit parameter" do
    create(:academy_mission, subject: subject_b, slug: "extra", concept: dopamine)

    result = described_class.call(mission: source, limit: 1)
    expect(result.data.size).to eq(1)
  end
end

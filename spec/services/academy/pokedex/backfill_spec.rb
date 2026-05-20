# frozen_string_literal: true

require "rails_helper"

# End-to-end Pokédex evolution coverage (PR4 from .planning/designs/academy-v4-tasks.md
# audit follow-ups). Asserts that a learner with cross-subject encounters of the
# same concept reaches L3 (mastered) through Backfill alone — the same path that
# would run in production for an account that completed missions pre-v4.
RSpec.describe Academy::Pokedex::Backfill do
  let(:learner_id) { 42 }
  let(:concept) do
    Academy::Concept.find_or_create_by!(slug: "dopamina") do |c|
      c.name = "Dopamina"
      c.definition = "neurotransmissor da expectativa"
      c.category = "cognitivo"
      c.active = true
    end.tap do |c|
      c.update!(pokedex_color_key: "cognitivo", pokedex_silhouette_key: "dopamina")
    end
  end

  def complete_mission!(subject:)
    mission = create(:academy_mission, subject: subject, concept: concept)
    Academy::MissionProgress.create!(
      learner_id: learner_id,
      mission: mission,
      status: :completed,
      started_at: 2.hours.ago,
      completed_at: 1.hour.ago
    )
    mission
  end

  it "promotes the concept to L3 (mastered) after ≥3 cross-subject encounters" do
    3.times { complete_mission!(subject: create(:academy_subject)) }

    result = described_class.call(learner_ids: [ learner_id ])

    expect(result.success?).to be true
    expect(result.data[:failed]).to eq(0)

    learner_concept = Academy::LearnerConcept.find_by(learner_id: learner_id, concept_id: concept.id)
    expect(learner_concept).to be_present
    expect(learner_concept.level).to eq(3)
    expect(learner_concept).to be_mastered
    expect(learner_concept.seen_in_subjects_count).to eq(3)
  end

  it "is idempotent — re-running the backfill does not over-level the concept" do
    3.times { complete_mission!(subject: create(:academy_subject)) }

    described_class.call(learner_ids: [ learner_id ])
    described_class.call(learner_ids: [ learner_id ])

    lc = Academy::LearnerConcept.find_by(learner_id: learner_id, concept_id: concept.id)
    expect(lc.level).to eq(3)
  end

  it "renders the mastered orb state for a backfilled learner on the Atlas chip" do
    3.times { complete_mission!(subject: create(:academy_subject)) }
    described_class.call(learner_ids: [ learner_id ])

    learner_concept = Academy::LearnerConcept.find_by(learner_id: learner_id, concept_id: concept.id)
    html = ApplicationController.render(
      Kid::Academy::Atlas::ConceptOrbComponent.new(concept: concept, level: learner_concept.level)
    )

    expect(html).to include("pokedex-orb--mastered")
    expect(html).to include("data-concept-slug=\"dopamina\"")
    expect(html).to include("--academy-pokedex-cognitivo")
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Pills::BuildLightningRound do
  let(:learner) do
    Academy::Learner.new(
      id: 777, display_name: "Lia", age_band: "kid", timezone: "UTC", interests: []
    )
  end

  def setup_concept(slug, name = nil)
    concept = Academy::Concept.find_or_create_by!(slug: slug) do |c|
      c.name = name || slug.titleize
      c.category = "cognitivo"
    end

    Academy::LensCache.create!(
      concept: concept, lens_type: "narrative", age_band: "kid", locale: "pt-BR",
      source: "curated",
      payload: {
        "headline" => "h",
        "micro_check" => {
          "question" => "Q sobre #{slug}",
          "options" => ["a", "b", "c", "d"],
          "correct_index" => 1,
          "rationale" => "Porque..."
        }
      },
      generated_at: Time.current
    )

    Academy::LearnerConcept.create!(
      learner_id: learner.id, concept_id: concept.id,
      level: 1, last_seen_at: 10.days.ago, first_seen_at: 20.days.ago
    )
    concept
  end

  it "builds 5 rounds when ≥5 fading concepts exist" do
    6.times { |i| setup_concept("lr-c-#{i}") }

    result = described_class.call(learner: learner)
    expect(result).to be_success
    expect(result.data[:rounds].size).to eq(5)
    expect(result.data[:rounds].first[:question]).to start_with("Q sobre ")
  end

  it "fails with :not_enough_concepts when pool is too small" do
    2.times { |i| setup_concept("lr-small-#{i}") }
    expect(described_class.call(learner: learner).error).to eq(:not_enough_concepts)
  end

  it "ignores recently-seen concepts (last_seen_at < 7d)" do
    5.times { |i| setup_concept("lr-recent-#{i}") }
    Academy::LearnerConcept.update_all(last_seen_at: 1.day.ago)
    expect(described_class.call(learner: learner).error).to eq(:not_enough_concepts)
  end

  it "ignores mastered concepts (level 3) — not in the forgetting zone" do
    5.times { |i| setup_concept("lr-master-#{i}") }
    Academy::LearnerConcept.update_all(level: 3)
    expect(described_class.call(learner: learner).error).to eq(:not_enough_concepts)
  end

  it "fails with :no_learner when learner is nil" do
    result = described_class.call(learner: nil)
    expect(result.error).to eq(:no_learner)
  end
end

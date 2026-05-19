# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Transfer::Detect do
  let(:learner_id) { 55 }

  let(:from_concept) { create(:academy_concept, name: "Dopamina") }
  let(:to_concept)   { create(:academy_concept, name: "Pico de glicose") }
  let(:mission)      { create(:academy_mission, concept: to_concept) }
  let(:progress) do
    Academy::MissionProgress.create!(
      learner_id: learner_id, mission: mission, status: :in_progress, started_at: Time.current
    )
  end
  let(:session) { create(:academy_session, mission_progress: progress) }

  before do
    create(:academy_learner_concept, learner_id: learner_id, concept: from_concept, level: 1, last_seen_at: 2.days.ago)
  end

  def learner_message(content)
    session.messages.create!(role: :learner, content: content, metadata: { "kind" => "text" })
  end

  context "with a high-confidence judge result" do
    let(:fake_judge) do
      slug = from_concept.slug
      instance_double(Academy::Llm::Client).tap do |c|
        allow(c).to receive(:chat).and_return(
          content: %({"applied":[{"slug":"#{slug}","confidence":0.85,"snippet":"açúcar e tiktok"}]})
        )
      end
    end

    it "creates a TransferDetection and promotes the from_concept to mastered" do
      msg = learner_message("açúcar funciona igual ao TikTok — solta dopamina e te puxa de novo, sério")

      result = described_class.call(message: msg, judge: fake_judge)

      expect(result.success?).to be true
      detections = result.data
      expect(detections.size).to eq(1)
      detection = detections.first
      expect(detection.from_concept).to eq(from_concept)
      expect(detection.to_concept).to eq(to_concept)
      expect(detection.confidence).to be_within(0.001).of(0.85)

      record = Academy::LearnerConcept.find_by(learner_id: learner_id, concept_id: from_concept.id)
      expect(record).to be_mastered
    end
  end

  context "with low confidence (below 0.75)" do
    let(:fake_judge) do
      slug = from_concept.slug
      instance_double(Academy::Llm::Client).tap do |c|
        allow(c).to receive(:chat).and_return(
          content: %({"applied":[{"slug":"#{slug}","confidence":0.5,"snippet":"talvez"}]})
        )
      end
    end

    it "does not persist anything" do
      msg = learner_message("acho que tem alguma coisa parecida com aquilo de antes")
      result = described_class.call(message: msg, judge: fake_judge)
      expect(result.data).to be_a(Hash) # skipped
      expect(Academy::TransferDetection.count).to eq(0)
    end
  end

  context "below MIN_CONTENT_LENGTH" do
    it "skips fast" do
      msg = learner_message("legal")
      result = described_class.call(message: msg, judge: nil)
      expect(result.data).to eq(skipped: :short)
    end
  end

  context "with no candidate concepts" do
    it "skips" do
      Academy::LearnerConcept.where(learner_id: learner_id).delete_all
      msg = learner_message("texto longo o suficiente pra atingir o threshold de 40 chars facilmente")
      result = described_class.call(message: msg, judge: nil)
      expect(result.data).to eq(skipped: :no_candidates)
    end
  end
end

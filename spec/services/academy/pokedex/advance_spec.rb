# frozen_string_literal: true

require "rails_helper"

# v5 Pokédex ladder (academy-v5-lens-missions spec `pokedex-depth`):
#   L0 unseen
#   L1 ≥1 LearnerLensVisit (any lens type, open or closed)
#   L2 ≥1 completed MissionProgress on this concept
#   L3 ≥2 completed MissionProgress on this concept across ≥2 distinct subjects
RSpec.describe Academy::Pokedex::Advance do
  let(:learner_id) { 99 }
  let(:concept)    { create(:academy_concept) }

  def mission_with_concept(subject: nil)
    subject ||= create(:academy_subject)
    create(:academy_mission, subject: subject, concept: concept)
  end

  def complete_mission!(mission)
    Academy::MissionProgress.create!(
      learner_id: learner_id, mission: mission, status: :completed,
      completed_at: Time.current, started_at: 1.hour.ago
    )
  end

  def open_lens_visit!(mission)
    progress = Academy::MissionProgress.find_or_create_by!(
      learner_id: learner_id, mission: mission
    ) do |p|
      p.status = :in_progress
      p.started_at = 1.hour.ago
    end
    Academy::LearnerLensVisit.create!(
      mission_progress: progress, learner_id: learner_id, concept_id: concept.id,
      lens_type: "scientific", ordering_position: 1, opened_at: Time.current
    )
  end

  describe "L0 → L1 (lens visit only, no mission complete)" do
    it "promotes to L1 when a LearnerLensVisit exists" do
      mission = mission_with_concept
      open_lens_visit!(mission)

      result = described_class.call(
        learner_id: learner_id, concept: concept, mission: mission, trigger: :lens_opened
      )

      expect(result.success?).to be true
      expect(result.data).to be_spotted
    end
  end

  describe "L1/L2 → L2 (mission complete)" do
    it "promotes to L2 on first completed mission" do
      mission = mission_with_concept
      complete_mission!(mission)

      result = described_class.call(
        learner_id: learner_id, concept: concept, mission: mission, trigger: :mission_completed
      )
      expect(result.data).to be_recognized
      expect(result.data.evolved_to_2_at).to be_present
    end
  end

  describe "L2 → L3 (cross-subject completion)" do
    it "promotes to L3 on the second completion in a different subject" do
      subj_a = create(:academy_subject)
      subj_b = create(:academy_subject)
      [ subj_a, subj_b ].each do |s|
        m = mission_with_concept(subject: s)
        complete_mission!(m)
        described_class.call(learner_id: learner_id, concept: concept, mission: m, trigger: :mission_completed)
      end

      record = Academy::LearnerConcept.find_by(learner_id: learner_id, concept_id: concept.id)
      expect(record).to be_mastered
    end

    it "does NOT promote to L3 when both completions are in the same subject" do
      subject_ = create(:academy_subject)
      2.times do |i|
        m = create(:academy_mission, subject: subject_, concept: concept, slug: "m-#{i}")
        complete_mission!(m)
        described_class.call(learner_id: learner_id, concept: concept, mission: m, trigger: :mission_completed)
      end

      record = Academy::LearnerConcept.find_by(learner_id: learner_id, concept_id: concept.id)
      expect(record).to be_recognized
    end
  end

  describe "idempotency + monotonicity" do
    it "does not over-level on repeated mission_completed calls for one completion" do
      mission = mission_with_concept
      complete_mission!(mission)

      3.times do
        described_class.call(learner_id: learner_id, concept: concept, mission: mission, trigger: :mission_completed)
      end

      record = Academy::LearnerConcept.find_by(learner_id: learner_id, concept_id: concept.id)
      expect(record.level).to eq(2)
    end

    it "does not regress level when calling with weaker evidence" do
      mission = mission_with_concept
      complete_mission!(mission)
      described_class.call(learner_id: learner_id, concept: concept, mission: mission, trigger: :mission_completed)

      open_lens_visit!(mission_with_concept)
      described_class.call(learner_id: learner_id, concept: concept, mission: mission, trigger: :lens_opened)

      record = Academy::LearnerConcept.find_by(learner_id: learner_id, concept_id: concept.id)
      expect(record.level).to eq(2)
    end
  end

  describe "invalid trigger" do
    it "returns a failure" do
      result = described_class.call(learner_id: learner_id, concept: concept, trigger: :foo)
      expect(result.success?).to be false
      expect(result.error).to match(/Trigger inválido/)
    end
  end
end

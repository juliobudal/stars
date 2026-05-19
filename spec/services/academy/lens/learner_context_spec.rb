# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::LearnerContext do
  let(:concept) { create(:academy_concept, slug: "ctx-concept", category: "cognitivo") }
  let(:subject_) { create(:academy_subject) }
  let(:mission)  { create(:academy_mission, subject: subject_, concept: concept, slug: "ctx-mission") }
  let(:progress) do
    Academy::MissionProgress.create!(
      learner_id: 99, mission: mission, status: :in_progress, started_at: 1.hour.ago
    )
  end

  describe ".build" do
    it "returns the level-0 context when learner_id is nil" do
      ctx = described_class.build(learner_id: nil, concept: concept)
      expect(ctx.level).to eq(0)
      expect(ctx.wrong_streak).to eq(0)
      expect(ctx).to be_novice
    end

    it "stays at level 0 when no LearnerConcept row exists" do
      ctx = described_class.build(learner_id: 99, concept: concept)
      expect(ctx.level).to eq(0)
      expect(ctx).to be_novice
    end

    it "reports level 1 for spotted concept" do
      Academy::LearnerConcept.create!(learner_id: 99, concept: concept, level: 1)
      expect(described_class.build(learner_id: 99, concept: concept).level).to eq(1)
    end

    it "flips to advanced from level 2 onwards" do
      Academy::LearnerConcept.create!(learner_id: 99, concept: concept, level: 2)
      ctx = described_class.build(learner_id: 99, concept: concept)
      expect(ctx.level).to eq(2)
      expect(ctx).to be_advanced
    end

    it "counts recent wrong signals into wrong_streak" do
      3.times do
        Academy::LensSignal.create!(
          learner_id: 99, concept_id: concept.id, mission_progress_id: progress.id,
          lens_type: "scientific", signal_type: "micro_check_wrong",
          numeric_value: 1, recorded_at: 1.hour.ago
        )
      end
      ctx = described_class.build(learner_id: 99, concept: concept)
      expect(ctx.wrong_streak).to eq(3)
    end

    it "ignores wrong signals older than 24h" do
      Academy::LensSignal.create!(
        learner_id: 99, concept_id: concept.id, mission_progress_id: progress.id,
        lens_type: "scientific", signal_type: "micro_check_wrong",
        numeric_value: 1, recorded_at: 2.days.ago
      )
      expect(described_class.build(learner_id: 99, concept: concept).wrong_streak).to eq(0)
    end

    it "preloads up to 5 related concept names from edges" do
      other_a = create(:academy_concept, slug: "ctx-related-a", category: "cognitivo")
      other_b = create(:academy_concept, slug: "ctx-related-b", category: "cognitivo")
      Academy::ConceptEdge.create!(from_concept: concept, to_concept: other_a, kind: :leads_to)
      Academy::ConceptEdge.create!(from_concept: other_b, to_concept: concept, kind: :depends_on)

      ctx = described_class.build(learner_id: 99, concept: concept)
      expect(ctx.related_concept_names).to contain_exactly(other_a.name, other_b.name)
    end
  end
end

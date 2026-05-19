# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Missions::ReviewMode do
  let(:learner) { Academy::Learner.new(id: 4242, display_name: "Aluno", age_band: "kid") }
  let(:subject_) { create(:academy_subject) }
  let(:concept) { create(:academy_concept, slug: "review-concept", category: "cognitivo") }
  let(:mission) { create(:academy_mission, subject: subject_, concept: concept, slug: "review-mission") }

  def make_progress(status:)
    Academy::MissionProgress.create!(
      learner_id: learner.id, mission: mission, status: status, started_at: 1.day.ago
    )
  end

  def make_closed_visit(progress, lens_type, position)
    cache = Academy::LensCache.create!(
      concept_id: concept.id, lens_type: lens_type.to_s, age_band: "kid", locale: "pt-BR",
      template_version: "v1", payload: { "h" => "x" }, generated_at: Time.current
    )
    Academy::LearnerLensVisit.create!(
      mission_progress: progress, learner_id: learner.id, concept_id: concept.id,
      lens_type: lens_type.to_s, lens_cache: cache, ordering_position: position,
      opened_at: 1.hour.ago, closed_at: 30.minutes.ago, outcome: "completed"
    )
  end

  context "when there is no progress yet" do
    it "fails with :no_progress" do
      result = described_class.call(learner: learner, mission: mission)
      expect(result).not_to be_success
      expect(result.error).to eq(:no_progress)
    end
  end

  context "when progress is in_progress" do
    it "fails with :not_completed so caller falls through to lens stage" do
      make_progress(status: :in_progress)
      result = described_class.call(learner: learner, mission: mission)
      expect(result).not_to be_success
      expect(result.error).to eq(:not_completed)
    end
  end

  context "when progress is completed" do
    it "returns visits ordered by ordering_position with their lens_caches preloaded" do
      progress = make_progress(status: :completed)
      make_closed_visit(progress, :narrative, 2)
      make_closed_visit(progress, :scientific, 1)
      make_closed_visit(progress, :ethical, 3)

      result = described_class.call(learner: learner, mission: mission)
      expect(result).to be_success

      stage = result.data
      expect(stage.total_visits).to eq(3)
      expect(stage.visits.map(&:lens_type)).to eq(%w[scientific narrative ethical])
      expect(stage.visits.first.lens_cache).to be_present
      expect(stage.lens_types).to contain_exactly("scientific", "narrative", "ethical")
    end

    it "excludes still-open visits from the ledger" do
      progress = make_progress(status: :completed)
      make_closed_visit(progress, :narrative, 1)
      Academy::LearnerLensVisit.create!(
        mission_progress: progress, learner_id: learner.id, concept_id: concept.id,
        lens_type: "scientific", ordering_position: 2, opened_at: Time.current # no closed_at
      )

      stage = described_class.call(learner: learner, mission: mission).data
      expect(stage.visits.map(&:lens_type)).to eq(%w[narrative])
    end
  end

  context "when progress is mastered" do
    it "also returns the review stage" do
      progress = make_progress(status: :mastered)
      make_closed_visit(progress, :first_person, 1)
      expect(described_class.call(learner: learner, mission: mission)).to be_success
    end
  end

  describe ".fetch_visit_entry" do
    it "returns the matching closed visit with its lens_cache" do
      progress = make_progress(status: :completed)
      visit = make_closed_visit(progress, :statistical, 1)

      entry = described_class.fetch_visit_entry(progress: progress, visit_id: visit.id)
      expect(entry.visit.id).to eq(visit.id)
      expect(entry.lens_cache).to be_present
    end

    it "returns nil for an unknown visit id" do
      progress = make_progress(status: :completed)
      expect(described_class.fetch_visit_entry(progress: progress, visit_id: -1)).to be_nil
    end

    it "returns nil for a visit that is still open" do
      progress = make_progress(status: :completed)
      open_visit = Academy::LearnerLensVisit.create!(
        mission_progress: progress, learner_id: learner.id, concept_id: concept.id,
        lens_type: "scientific", ordering_position: 1, opened_at: Time.current
      )
      expect(described_class.fetch_visit_entry(progress: progress, visit_id: open_visit.id)).to be_nil
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::FlagLowQuality do
  let(:concept) { create(:academy_concept, slug: "flq-concept", category: "cognitivo") }
  let(:subject_) { create(:academy_subject) }
  let(:mission)  { create(:academy_mission, subject: subject_, concept: concept, slug: "flq-mission") }
  let(:cache) do
    Academy::LensCache.create!(
      concept_id: concept.id, lens_type: "scientific", age_band: "kid", locale: "pt-BR",
      template_version: "v1", payload: { "h" => "x" }, generated_at: Time.current,
      mastery_tier: "any", prompt_digest: "abc12345"
    )
  end

  def make_progress(learner_id:)
    Academy::MissionProgress.create!(
      learner_id: learner_id, mission: mission, status: :in_progress, started_at: 1.hour.ago
    )
  end

  def make_visit(progress:, position:, payload:, closed:)
    Academy::LearnerLensVisit.create!(
      mission_progress: progress, learner_id: progress.learner_id, concept_id: concept.id,
      lens_type: "scientific", lens_cache: cache, ordering_position: position,
      opened_at: 1.hour.ago, closed_at: closed ? 30.minutes.ago : nil,
      outcome: closed ? "completed" : nil, signal_payload: payload
    )
  end

  def make_wrong_signals(count:)
    last_visit = nil
    count.times do |i|
      progress = make_progress(learner_id: 1_000 + i)
      visit = make_visit(progress: progress, position: 1,
                         payload: { "micro_check_correct" => "false" }, closed: true)
      Academy::LensSignal.create!(
        learner_id: progress.learner_id, concept_id: concept.id,
        mission_progress_id: progress.id, lens_visit_id: visit.id,
        lens_type: "scientific", signal_type: "micro_check_wrong",
        numeric_value: 1, recorded_at: 1.hour.ago
      )
      last_visit = visit
    end
    last_visit
  end

  it "no-ops if the visit has no lens_cache_id" do
    progress = make_progress(learner_id: 42)
    visit = Academy::LearnerLensVisit.create!(
      mission_progress: progress, learner_id: 42, concept_id: concept.id,
      lens_type: "scientific", ordering_position: 1, opened_at: Time.current,
      closed_at: Time.current, signal_payload: { "micro_check_correct" => "false" }
    )
    result = described_class.call(visit: visit)
    expect(result.data).to be(false)
  end

  it "no-ops if the visit's micro_check was correct" do
    progress = make_progress(learner_id: 42)
    visit = make_visit(progress: progress, position: 1,
                       payload: { "micro_check_correct" => "true" }, closed: true)
    expect(described_class.call(visit: visit).data).to be(false)
  end

  it "no-ops below the wrong-count threshold" do
    trigger = make_wrong_signals(count: 2)
    expect(described_class.call(visit: trigger).data).to be(false)
    expect(cache.reload.quality_flagged).to be(false)
  end

  it "flags the cache row when threshold is reached" do
    trigger = make_wrong_signals(count: 3)
    expect(described_class.call(visit: trigger).data).to be(true)
    expect(cache.reload.quality_flagged).to be(true)
  end

  it "ignores wrong signals outside the 7-day window" do
    progress = make_progress(learner_id: 42)
    visit = make_visit(progress: progress, position: 1,
                       payload: { "micro_check_correct" => "false" }, closed: true)
    3.times do
      Academy::LensSignal.create!(
        learner_id: 42, concept_id: concept.id, mission_progress_id: progress.id,
        lens_visit_id: visit.id, lens_type: "scientific",
        signal_type: "micro_check_wrong", numeric_value: 1, recorded_at: 10.days.ago
      )
    end
    expect(described_class.call(visit: visit).data).to be(false)
  end
end

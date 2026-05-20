# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Missions::ReviewMode do
  let(:learner) { Academy::Learner.new(id: 4242, display_name: "Aluno", age_band: "kid") }
  let(:subject_) { create(:academy_subject) }
  let(:concept) { create(:academy_concept, slug: "review-concept", category: "cognitivo") }
  let(:mission) do
    create(:academy_mission, subject: subject_, concept: concept,
           slug: "review-mission", with_curated_kid_payload: false)
  end

  def make_progress(status:)
    Academy::MissionProgress.create!(
      learner_id: learner.id, mission: mission, status: status, started_at: 1.day.ago
    )
  end

  def make_closed_visit(progress, lens_type, position)
    cache = Academy::LensCache.create!(
      concept_id: concept.id, lens_type: lens_type.to_s, age_band: "kid", locale: "pt-BR",
      payload: { "h" => "x" }, generated_at: Time.current
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

    it "exposes the closure-lens headline as `closure_headline` (analogy_bridge counts)" do
      progress = make_progress(status: :completed)
      make_closed_visit(progress, :narrative, 1)
      # The make_closed_visit helper writes payload {h:x}; overwrite the
      # closure cache so it carries a headline the view can render.
      bridge_cache = Academy::LensCache.create!(
        concept_id: concept.id, lens_type: "analogy_bridge", age_band: "kid", locale: "pt-BR",
        payload: { "headline" => "Café da manhã é abastecer um foguete" },
        generated_at: Time.current
      )
      Academy::LearnerLensVisit.create!(
        mission_progress: progress, learner_id: learner.id, concept_id: concept.id,
        lens_type: "analogy_bridge", lens_cache: bridge_cache, ordering_position: 2,
        opened_at: 30.minutes.ago, closed_at: 10.minutes.ago, outcome: "completed"
      )

      stage = described_class.call(learner: learner, mission: mission).data
      expect(stage.closure_headline).to eq("Café da manhã é abastecer um foguete")
    end

    it "returns nil closure_headline when no closure lens was visited" do
      progress = make_progress(status: :completed)
      make_closed_visit(progress, :narrative, 1)
      make_closed_visit(progress, :scientific, 2)

      stage = described_class.call(learner: learner, mission: mission).data
      expect(stage.closure_headline).to be_nil
    end

    it "loads the minted DiscoveryCard and exposes next_mission within the trail" do
      trail = create(:academy_trail, subject: subject_, slug: "rv-trail")
      # The `mission` let opts out of the factory's curated-payload seeding
      # (existing tests below create caches by hand). That flips active=false
      # — which is fine for chooser tests, but here we need the mission to
      # be active so trail.missions.where(active: true) picks it up.
      Academy::LensCache.find_or_create_by!(
        concept: concept, lens_type: "narrative", age_band: "kid", locale: "pt-BR"
      ) do |r|
        r.source = "curated"
        r.payload = { stub: true }
        r.generated_at = Time.current
      end
      mission.update!(trail: trail, position_in_trail: 1, active: true)
      next_concept = create(:academy_concept, slug: "rv-next-concept")
      next_mission = create(:academy_mission, subject: subject_, trail: trail,
                            concept: next_concept, slug: "rv-next", position_in_trail: 2)

      progress = make_progress(status: :completed)
      make_closed_visit(progress, :scientific, 1)
      card = Academy::DiscoveryCard.create!(
        learner_id: learner.id, mission: mission,
        headline: "uma sacada", application: "aplica", central_insight: "se X, então Y",
        minted_at: Time.current
      )

      fresh_mission = Academy::Mission.find(mission.id)
      stage = described_class.call(learner: learner, mission: fresh_mission).data
      expect(fresh_mission.trail).to eq(trail)
      expect(trail.missions.where(active: true).pluck(:id)).to contain_exactly(mission.id, next_mission.id)
      expect(stage.card).to eq(card)
      expect(stage.next_mission).to eq(next_mission)
      expect(stage.trail_total).to eq(2)
      expect(stage.trail_position).to eq(1)
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

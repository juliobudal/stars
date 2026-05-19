# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Compass::Propose do
  let(:learner_id) { 71 }

  let(:subject_hot)  { create(:academy_subject, position: 1) }
  let(:subject_cold) { create(:academy_subject, position: 2) }
  let(:trail_hot)    { create(:academy_trail, subject: subject_hot) }
  let(:trail_cold)   { create(:academy_trail, subject: subject_cold) }

  let!(:hot_mission)  { create(:academy_mission, subject: subject_hot,  trail: trail_hot,  position_in_trail: 0, order_in_subject: 0) }
  let!(:cold_mission) { create(:academy_mission, subject: subject_cold, trail: trail_cold, position_in_trail: 0, order_in_subject: 0) }

  before do
    create(:academy_learner_signal, learner_id: learner_id, subject: subject_hot, affinity_score: 12)
  end

  it "returns a hot_trail card pointing at the most-affined subject" do
    result = described_class.call(learner_id: learner_id)
    plan = result.data
    expect(plan.hot_trail).not_to be_nil
    expect(plan.hot_trail.mission.subject_id).to eq(subject_hot.id)
  end

  it "returns a new_territory card pointing at an untouched subject" do
    result = described_class.call(learner_id: learner_id)
    territory = result.data.new_territory
    expect(territory).not_to be_nil
    expect(territory.mission.subject_id).not_to eq(subject_hot.id)
  end

  it "fills a revisit card when a concept aged out" do
    other_subject = create(:academy_subject, position: 3)
    concept = create(:academy_concept)
    revisit_mission = create(:academy_mission, subject: other_subject,
                                                trail: create(:academy_trail, subject: other_subject),
                                                position_in_trail: 0,
                                                concept: concept)
    create(:academy_learner_concept, learner_id: learner_id, concept: concept, level: 1, last_seen_at: 30.days.ago)

    plan = described_class.call(learner_id: learner_id).data
    expect(plan.revisit).not_to be_nil
    expect(plan.revisit.mission).to eq(revisit_mission)
  end

  it "falls back to a single legacy pick when slots stay empty" do
    Academy::LearnerSignal.where(learner_id: learner_id).delete_all
    Academy::Subject.update_all(active: false)
    subject_hot.update!(active: true)
    # mission_hot stays as the only candidate for the legacy fallback
    Academy::Mission.where.not(subject_id: subject_hot.id).update_all(active: false)

    plan = described_class.call(learner_id: learner_id).data
    expect(plan.cards.size).to be >= 1
  end
end

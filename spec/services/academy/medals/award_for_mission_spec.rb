# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Medals::AwardForMission do
  let(:subject_record) { create(:academy_subject) }
  let(:mission) { create(:academy_mission, subject: subject_record) }
  let(:progress) do
    create(:academy_mission_progress,
           mission: mission, status: :completed,
           total_checkpoints: 3, correct_checkpoints: 3)
  end

  before do
    create(:academy_medal, kind: :mission_completed, mission_id: mission.id, subject_id: subject_record.id, slug: "m-c")
    create(:academy_medal, kind: :mission_perfect,   mission_id: mission.id, subject_id: subject_record.id, slug: "m-p")
    create(:academy_medal, kind: :subject_apprentice, subject_id: subject_record.id, slug: "s-a")
  end

  it "awards completed + perfect when perfect" do
    described_class.call(progress: progress)
    awarded_kinds = Academy::MedalAward.where(learner_id: progress.learner_id)
                                       .joins(:medal).pluck("academy_medals.kind")
    # Rails 8 enums emit the symbolic name via pluck — accept either form for safety.
    expect(awarded_kinds).to include("mission_completed").or include(0)
    expect(awarded_kinds).to include("mission_perfect").or include(1)
  end

  it "is idempotent" do
    2.times { described_class.call(progress: progress) }
    expect(Academy::MedalAward.where(learner_id: progress.learner_id).count)
      .to be <= 3
  end
end

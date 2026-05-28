# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lessons::Available do
  let(:learner) { Academy::Learner.new(id: 42, display_name: "Kid", age_band: "kid") }
  let(:trail) { create(:academy_trail) }
  let!(:l1) { create(:academy_lesson, trail: trail, position: 1) }
  let!(:l2) { create(:academy_lesson, trail: trail, position: 2) }
  let!(:l3) { create(:academy_lesson, trail: trail, position: 3) }

  def statuses
    described_class.call(learner: learner, trail: trail).data.map { |r| r[:status] }
  end

  it "unlocks only the first lesson when nothing is completed" do
    expect(statuses).to eq(%i[available locked locked])
  end

  it "unlocks the next lesson after the previous is completed" do
    create(:academy_lesson_progress, lesson: l1, learner_id: learner.id)
    expect(statuses).to eq(%i[completed available locked])
  end

  it "marks all completed when the trail is done" do
    [ l1, l2, l3 ].each { |l| create(:academy_lesson_progress, lesson: l, learner_id: learner.id) }
    expect(statuses).to eq(%i[completed completed completed])
  end

  it "ignores another learner's progress" do
    create(:academy_lesson_progress, lesson: l1, learner_id: 999)
    expect(statuses).to eq(%i[available locked locked])
  end
end

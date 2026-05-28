# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lessons::Complete do
  let(:learner) { Academy::Learner.new(id: 7, display_name: "Kid", age_band: "kid") }
  let(:trail) { create(:academy_trail) }
  let!(:l1) { create(:academy_lesson, trail: trail, position: 1) }
  let!(:l2) { create(:academy_lesson, trail: trail, position: 2) }

  it "marks the lesson complete and returns the next lesson" do
    result = described_class.call(learner: learner, lesson: l1, check_choice: 1)
    expect(result).to be_success
    expect(result.data[:progress].completed?).to be(true)
    expect(result.data[:next_lesson]).to eq(l2)
  end

  it "records check correctness" do
    correct = described_class.call(learner: learner, lesson: l1, check_choice: 1)
    expect(correct.data[:check_correct]).to be(true)

    wrong = described_class.call(learner: learner, lesson: l2, check_choice: 0)
    expect(wrong.data[:check_correct]).to be(false)
  end

  it "is idempotent — preserves the first completion time" do
    first = described_class.call(learner: learner, lesson: l1, check_choice: 1).data[:progress]
    t = first.completed_at
    again = described_class.call(learner: learner, lesson: l1, check_choice: 0).data[:progress]
    expect(again.id).to eq(first.id)
    expect(again.completed_at).to be_within(1.second).of(t)
    expect(Academy::LessonProgress.where(learner_id: learner.id, lesson_id: l1.id).count).to eq(1)
  end

  it "returns nil next_lesson for the last lesson" do
    result = described_class.call(learner: learner, lesson: l2)
    expect(result.data[:next_lesson]).to be_nil
  end
end

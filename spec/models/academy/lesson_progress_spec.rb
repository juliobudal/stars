# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::LessonProgress, type: :model do
  it "is valid from the factory" do
    expect(build(:academy_lesson_progress)).to be_valid
  end

  it "is unique per (learner, lesson)" do
    lesson = create(:academy_lesson)
    create(:academy_lesson_progress, lesson: lesson, learner_id: 1)
    dup = build(:academy_lesson_progress, lesson: lesson, learner_id: 1)
    expect(dup).to be_invalid
  end

  it "scopes completed rows" do
    completed = create(:academy_lesson_progress, completed_at: Time.current)
    create(:academy_lesson_progress, completed_at: nil)
    expect(described_class.completed).to contain_exactly(completed)
  end
end

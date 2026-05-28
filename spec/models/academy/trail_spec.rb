# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Trail, type: :model do
  it "is valid from the factory" do
    expect(build(:academy_trail)).to be_valid
  end

  it "requires a lowercase-dashed slug" do
    expect(build(:academy_trail, slug: "Bad Slug")).to be_invalid
  end

  it "orders lessons by position" do
    trail = create(:academy_trail)
    b = create(:academy_lesson, trail: trail, position: 2)
    a = create(:academy_lesson, trail: trail, position: 1)
    expect(trail.lessons.to_a).to eq([ a, b ])
  end

  describe ".progress_for" do
    it "counts completed lessons per trail for a learner" do
      trail = create(:academy_trail)
      l1 = create(:academy_lesson, trail: trail, position: 1)
      create(:academy_lesson, trail: trail, position: 2)
      create(:academy_lesson_progress, lesson: l1, learner_id: 99)

      result = described_class.progress_for(99, trails: [ trail ])
      expect(result[trail.id]).to eq({ total: 2, done: 1 })
    end
  end
end

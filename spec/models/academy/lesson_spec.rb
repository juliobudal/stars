# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lesson, type: :model do
  it "is valid with a well-formed payload" do
    expect(build(:academy_lesson)).to be_valid
  end

  it "exposes payload accessors" do
    lesson = build(:academy_lesson)
    expect(lesson.clues).to be_an(Array)
    expect(lesson.revelation).to be_present
    expect(lesson.hook).to be_present
    expect(lesson.check?).to be(true)
  end

  it "treats a nil check as no check" do
    lesson = build(:academy_lesson, :without_check)
    expect(lesson).to be_valid
    expect(lesson.check?).to be(false)
  end

  describe "payload validation" do
    it "rejects fewer than 2 clues" do
      lesson = build(:academy_lesson, payload: { "clues" => [ "só uma" ], "revelation" => "x", "hook" => "y" })
      expect(lesson).to be_invalid
    end

    it "rejects a missing revelation" do
      lesson = build(:academy_lesson, payload: { "clues" => %w[a b], "revelation" => "", "hook" => "y" })
      expect(lesson).to be_invalid
    end

    it "rejects a check whose answer_index is out of range" do
      lesson = build(:academy_lesson, payload: {
        "clues" => %w[a b], "revelation" => "r", "hook" => "h",
        "check" => { "prompt" => "p", "options" => %w[a b], "answer_index" => 5 }
      })
      expect(lesson).to be_invalid
    end
  end

  it "enforces unique slug" do
    create(:academy_lesson, slug: "dup")
    expect { create(:academy_lesson, slug: "dup") }.to raise_error(ActiveRecord::RecordInvalid)
  end
end

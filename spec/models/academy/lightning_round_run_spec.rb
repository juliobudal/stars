# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::LightningRoundRun do
  let(:learner_id) { 42 }

  def add_run(correct:, days_ago: 0, total: 5, tier: "strong")
    described_class.create!(
      learner_id: learner_id, total_questions: total, correct_count: correct,
      tier: tier, created_at: days_ago.days.ago, elapsed_seconds: 60
    )
  end

  describe ".champion?" do
    it "is false with no runs" do
      expect(described_class.champion?(learner_id)).to be false
    end

    it "is false with 3 qualifying runs in the window" do
      3.times { add_run(correct: 5, days_ago: 1) }
      expect(described_class.champion?(learner_id)).to be false
    end

    it "is true with 4 qualifying runs (≥4 hits) in the past 7 days" do
      4.times { |i| add_run(correct: 4, days_ago: i) }
      expect(described_class.champion?(learner_id)).to be true
    end

    it "ignores runs older than the window" do
      4.times { add_run(correct: 5, days_ago: 30) }
      expect(described_class.champion?(learner_id)).to be false
    end

    it "ignores runs with too few correct answers" do
      4.times { add_run(correct: 3, days_ago: 1) }
      expect(described_class.champion?(learner_id)).to be false
    end
  end
end

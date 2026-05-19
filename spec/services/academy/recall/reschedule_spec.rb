# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Recall::Reschedule do
  let(:review) { create(:academy_recall_review, streak: 0, interval_days: 1) }

  it "advances the SM-2 ladder on got_it" do
    described_class.call(review: review, outcome: :got_it)
    review.reload
    expect(review.streak).to eq(1)
    expect(review.interval_days).to eq(3)
    expect(review.due_at).to be > 2.days.from_now
  end

  it "resets on forgot" do
    review.update!(streak: 4, interval_days: 60)
    described_class.call(review: review, outcome: :forgot)
    review.reload
    expect(review.streak).to eq(0)
    expect(review.interval_days).to eq(1)
  end

  it "half-steps backwards on partial" do
    review.update!(streak: 2, interval_days: 7)
    described_class.call(review: review, outcome: :partial)
    review.reload
    expect(review.streak).to eq(2)
    expect(review.interval_days).to eq(3)
  end

  it "rejects unknown outcomes" do
    result = described_class.call(review: review, outcome: :invented)
    expect(result.success?).to be false
  end

  it "caps the interval at the top of the ladder" do
    review.update!(streak: 10, interval_days: 180)
    described_class.call(review: review, outcome: :got_it)
    review.reload
    expect(review.interval_days).to eq(180)
  end
end
